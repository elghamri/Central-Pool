/**
 * Central Pool Step 5: Authoritative Allocation Confirmation Service
 * Orchestrates atomic, transactional confirmation of an Allocation Candidate into an authoritative
 * Allocation Position document, updates unit occupancy, creates the member projection receipt,
 * transitions the Participation Request state, and records idempotency.
 *
 * CRITICAL ARCHITECTURAL BOUNDARY:
 * - Authoritative occupancy source: /allocation_units/{unitId}/positions/{positionNumber}
 * - Derived projection: /users/{userId}/allocations/{allocationId}
 * - Pure transaction boundary: Single atomic write set for position, unit, request, projection, and idempotency.
 */

import { Firestore, FieldValue } from 'firebase-admin/firestore';
import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  ConfirmedAllocation,
  IdempotencyRecord,
  getParticipationRequestPath,
  getAllocationUnitPath,
  getPositionPath,
  getAllocationReceiptPath,
  getIdempotencyRecordPath,
  validateParticipationRequestStateTransition,
  validateAllocationUnitStateTransition,
} from '../domain';
import {
  calculateTotalEntitlement,
  calculateTotalPot,
} from '../math/allocation_math';
import { sha256Hex } from '../matching/compatibility_key';
import {
  docToParticipationRequest,
  docToAllocationCandidate,
  docToAllocationUnit,
  docToAllocationPosition,
  docToIdempotencyRecord,
  participationRequestToDoc,
  allocationPositionToDoc,
  allocationUnitToDoc,
  confirmedAllocationToDoc,
  idempotencyRecordToDoc,
  isoStringToTimestamp,
} from '../persistence/dto/dto_converters';
import {
  EntityNotFoundError,
} from '../persistence/persistence_errors';
import { AllocationConfirmationInput, AllocationConfirmationResult } from './confirmation_types';
import { validateConfirmationInvariants } from './confirmation_validator';
import {
  PositionAlreadyOccupiedError,
} from './confirmation_errors';

export function computeConfirmationIdempotencyId(
  tenantId: string,
  memberUid: string,
  clientKey: string
): string {
  return `idemp_${sha256Hex(`${tenantId}:${memberUid}:${clientKey}`)}`;
}

export function computeAllocationReceiptId(tenantId: string, requestId: string): string {
  return `alloc_${sha256Hex(`${tenantId}:${requestId}`)}`;
}

export class AllocationConfirmationService {
  constructor(private readonly db: Firestore) {}

  /**
   * Executes authoritative allocation confirmation inside an atomic Firestore Transaction.
   */
  async confirmAllocation(
    input: AllocationConfirmationInput
  ): Promise<AllocationConfirmationResult> {
    const { tenantId, memberUid, requestId, candidateId, idempotencyKey } = input;
    const evaluationTime = input.evaluationTimestamp || new Date().toISOString();
    const evaluationTimeMs = new Date(evaluationTime).getTime();

    // 1. Deterministic Idempotency Key & Path
    const idempotencyId = computeConfirmationIdempotencyId(tenantId, memberUid, idempotencyKey);
    const idempotencyRef = this.db.doc(getIdempotencyRecordPath(idempotencyId));

    // 2. Execute Atomic Firestore Transaction
    return await this.db.runTransaction(async (tx) => {
      // a. Read Idempotency Record (Check for completed replay)
      const idempotencySnap = await tx.get(idempotencyRef);
      if (idempotencySnap.exists) {
        const existingRecord = docToIdempotencyRecord(idempotencySnap.data()!);
        if (existingRecord.status === 'COMPLETED' && existingRecord.responsePayload) {
          const cachedResult = existingRecord.responsePayload as unknown as AllocationConfirmationResult;
          return {
            ...cachedResult,
            isIdempotentReplay: true,
          };
        }
      }

      // b. Read Participation Request
      const requestRef = this.db.doc(getParticipationRequestPath(requestId));
      const requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) {
        throw new EntityNotFoundError('ParticipationRequest', requestId);
      }
      const request: ParticipationRequest = docToParticipationRequest(requestSnap.data()!);

      // c. Read Candidate (From candidate storage or candidate subcollection)
      const candidateRef = this.db.doc(`allocation_candidates/${candidateId}`);
      const candidateSnap = await tx.get(candidateRef);
      if (!candidateSnap.exists) {
        throw new EntityNotFoundError('AllocationCandidate', candidateId);
      }
      const candidate: AllocationCandidate = docToAllocationCandidate(candidateSnap.data()!);

      // d. Read Allocation Unit
      const unitRef = this.db.doc(getAllocationUnitPath(candidate.allocationUnitId));
      const unitSnap = await tx.get(unitRef);
      if (!unitSnap.exists) {
        throw new EntityNotFoundError('AllocationUnit', candidate.allocationUnitId);
      }
      const unit: AllocationUnit = docToAllocationUnit(unitSnap.data()!);

      // e. Read Authoritative Position Slot Document
      const positionPath = getPositionPath(unit.unitId, candidate.allocatedPosition);
      const positionRef = this.db.doc(positionPath);
      const positionSnap = await tx.get(positionRef);

      if (positionSnap.exists) {
        throw new PositionAlreadyOccupiedError(unit.unitId, candidate.allocatedPosition);
      }

      // f. Pure Invariant Revalidation (Tenant boundaries, signatures, capacity, rules, math)
      validateConfirmationInvariants(input, request, candidate, unit, evaluationTimeMs);

      // g. Validate Legal State Transitions
      if (request.status === 'AWAITING_SELECTION') {
        validateParticipationRequestStateTransition('AWAITING_SELECTION', 'REVALIDATING');
        validateParticipationRequestStateTransition('REVALIDATING', 'CONFIRMED');
      } else if (request.status === 'REVALIDATING') {
        validateParticipationRequestStateTransition('REVALIDATING', 'CONFIRMED');
      } else {
        validateParticipationRequestStateTransition(request.status, 'CONFIRMED');
      }

      const nextOccupiedCount = unit.occupiedCount + 1;
      const willTransitionToFull = nextOccupiedCount === unit.memberCount;
      const nextUnitStatus = willTransitionToFull ? 'COMMITTED_FULL' : 'FORMING';

      if (willTransitionToFull) {
        validateAllocationUnitStateTransition(unit.status, 'COMMITTED_FULL');
      }

      // h. Prepare Authoritative AllocationPosition Domain Entity
      const positionEntity: AllocationPosition = {
        unitId: unit.unitId,
        positionNumber: candidate.allocatedPosition,
        tenantId,
        memberUid,
        requestId,
        payoutPeriod: candidate.payoutPeriod,
        occupiedAt: evaluationTime,
        version: 1,
      };

      // i. Prepare ConfirmedAllocation Derived Projection Receipt
      const allocationId = computeAllocationReceiptId(tenantId, requestId);
      const totalEntitlementMinor = calculateTotalEntitlement(request.contributionMinor, request.durationPeriods);
      const totalPotMinor = calculateTotalPot(request.contributionMinor, request.durationPeriods);

      const confirmedAllocationEntity: ConfirmedAllocation = {
        allocationId,
        requestId,
        tenantId,
        memberUid,
        allocationUnitId: unit.unitId,
        allocatedPosition: candidate.allocatedPosition,
        payoutPeriod: candidate.payoutPeriod,
        contributionMinor: request.contributionMinor,
        durationPeriods: request.durationPeriods,
        totalEntitlementMinor,
        totalPotMinor,
        currency: request.currency.toUpperCase(),
        allocationRule: 'SYMMETRICAL_V1',
        confirmedAt: evaluationTime,
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        version: 1,
      };

      // j. Prepare Result Payload
      const result: AllocationConfirmationResult = {
        success: true,
        allocationId,
        requestId,
        tenantId,
        memberUid,
        allocationUnitId: unit.unitId,
        allocatedPosition: candidate.allocatedPosition,
        payoutPeriod: candidate.payoutPeriod,
        contributionMinor: request.contributionMinor,
        durationPeriods: request.durationPeriods,
        totalEntitlementMinor,
        totalPotMinor,
        currency: request.currency.toUpperCase(),
        allocationRule: 'SYMMETRICAL_V1',
        confirmedAt: evaluationTime,
        isIdempotentReplay: false,
        unitTransitionedToCommittedFull: willTransitionToFull,
      };

      // k. Prepare Idempotency Record
      const idempotencyRecord: IdempotencyRecord = {
        idempotencyId,
        tenantId,
        memberUid,
        clientKey: idempotencyKey,
        operation: 'CONFIRM_ALLOCATION',
        status: 'COMPLETED',
        responsePayload: result as unknown as Record<string, unknown>,
        createdAt: evaluationTime,
        expiresAt: new Date(evaluationTimeMs + 24 * 60 * 60 * 1000).toISOString(),
        version: 1,
      };

      // --- ATOMIC TRANSACTION MUTATIONS ---

      // 1. Create Authoritative Position Document
      const positionDocData = allocationPositionToDoc(positionEntity, unit.memberCount, true);
      tx.set(positionRef, positionDocData);

      // 2. Update Allocation Unit Occupancy & Formation Status
      const unitUpdates: Record<string, any> = {
        occupiedCount: nextOccupiedCount,
        status: nextUnitStatus,
        version: unit.version + 1,
        updatedAt: FieldValue.serverTimestamp(),
      };
      tx.update(unitRef, unitUpdates);

      // 3. Create Confirmed Allocation Projection Document
      const allocationReceiptRef = this.db.doc(getAllocationReceiptPath(memberUid, allocationId));
      const confirmedAllocationDocData = confirmedAllocationToDoc(confirmedAllocationEntity, true);
      tx.set(allocationReceiptRef, confirmedAllocationDocData);

      // 4. Update Participation Request Status to CONFIRMED
      const requestUpdates: Record<string, any> = {
        status: 'CONFIRMED',
        allocationUnitId: unit.unitId,
        allocatedPosition: candidate.allocatedPosition,
        payoutPeriod: candidate.payoutPeriod,
        confirmedAt: isoStringToTimestamp(evaluationTime, 'confirmedAt'),
        version: request.version + 1,
        updatedAt: FieldValue.serverTimestamp(),
      };
      tx.update(requestRef, requestUpdates);

      // 5. Save Idempotency Record Document
      const idempotencyDocData = idempotencyRecordToDoc(idempotencyRecord, true);
      tx.set(idempotencyRef, idempotencyDocData);

      return result;
    });
  }
}
