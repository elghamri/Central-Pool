/**
 * Central Pool Step 7: Period Projection Service
 * Orchestrates pure period engine projections over authoritative Firestore records with strict tenant and member security.
 */

import { Firestore } from 'firebase-admin/firestore';
import {
  CyclePeriodProjection,
  MemberPeriodProjection,
  MemberPeriodDetail,
  PeriodReadiness,
} from '../domain/period_types';
import {
  deriveCyclePeriodStructure,
  deriveMemberPeriodProjection,
  computePeriodReadiness,
} from '../domain/period_engine';
import {
  PeriodProjectionAccessDeniedError,
  PeriodProjectionMismatchError,
} from '../domain/period_errors';
import {
  getAllocationUnitPath,
  getPositionPath,
  getAllocationReceiptPath,
  getContributionSchedulePath,
} from '../../domain/domain_paths';
import {
  getMemberPeriodProjectionPath,
  getUnitPeriodProjectionPath,
} from '../domain/period_paths';
import {
  cyclePeriodProjectionToDoc,
  memberPeriodProjectionToDoc,
} from '../dto/period_dto';
import { computeObligationId, computeContributionScheduleId } from '../../financial/identities';
import { validatePeriodNumberInRange } from '../domain/period_validation';
import { docToAllocationUnit, docToConfirmedAllocation } from '../../persistence';
import { docToContributionSchedule } from '../../financial/dto';
import { EntityNotFoundError } from '../../persistence/persistence_errors';

export class PeriodProjectionService {
  constructor(private readonly db: Firestore) {}

  /**
   * Generates or retrieves the cycle-level period projection for an Allocation Unit.
   * Strictly enforces tenant boundary isolation.
   */
  async getCyclePeriodProjection(
    callerTenantId: string,
    unitId: string,
    persist = true
  ): Promise<CyclePeriodProjection> {
    if (!callerTenantId || !callerTenantId.trim()) {
      throw new PeriodProjectionAccessDeniedError('callerTenantId is required');
    }
    if (!unitId || !unitId.trim()) {
      throw new PeriodProjectionMismatchError('unitId is required');
    }

    const unitRef = this.db.doc(getAllocationUnitPath(unitId));
    const unitSnap = await unitRef.get();
    if (!unitSnap.exists) {
      throw new EntityNotFoundError('AllocationUnit', unitId);
    }

    const unitData = unitSnap.data();
    if (!unitData) {
      throw new EntityNotFoundError('AllocationUnit', unitId);
    }
    const unit = docToAllocationUnit(unitData);
    if (unit.tenantId !== callerTenantId) {
      throw new PeriodProjectionAccessDeniedError(
        `tenant mismatch: unit belongs to ${unit.tenantId}, caller is ${callerTenantId}`
      );
    }

    // Load authoritative position occupancies
    const positionMembers: Record<number, string> = {};
    for (let pos = 1; pos <= unit.memberCount; pos++) {
      const posRef = this.db.doc(getPositionPath(unitId, pos));
      const posSnap = await posRef.get();
      if (posSnap.exists) {
        const posData = posSnap.data();
        if (posData?.memberUid) {
          positionMembers[pos] = String(posData.memberUid);
        }
      }
    }

    // Pure derivation delegating to math kernel
    const projection = deriveCyclePeriodStructure({
      tenantId: unit.tenantId,
      allocationUnitId: unit.unitId,
      memberCount: unit.memberCount,
      periodicContributionMinor: unit.contributionMinor,
      currency: unit.currency,
      positionMembers,
    });

    if (persist) {
      const projectionRef = this.db.doc(getUnitPeriodProjectionPath(unitId, projection.projectionId));
      await projectionRef.set(cyclePeriodProjectionToDoc(projection));
    }

    return projection;
  }

  /**
   * Generates or retrieves a member's personal period projection for a confirmed allocation.
   * Strictly enforces tenant isolation and member ownership isolation.
   */
  async getMemberPeriodProjection(
    callerTenantId: string,
    callerMemberUid: string,
    allocationId: string,
    persist = true
  ): Promise<MemberPeriodProjection> {
    if (!callerTenantId || !callerTenantId.trim()) {
      throw new PeriodProjectionAccessDeniedError('callerTenantId is required');
    }
    if (!callerMemberUid || !callerMemberUid.trim()) {
      throw new PeriodProjectionAccessDeniedError('callerMemberUid is required');
    }
    if (!allocationId || !allocationId.trim()) {
      throw new PeriodProjectionMismatchError('allocationId is required');
    }

    // 1. Read member confirmed allocation projection receipt
    const allocRef = this.db.doc(getAllocationReceiptPath(callerMemberUid, allocationId));
    const allocSnap = await allocRef.get();
    if (!allocSnap.exists) {
      throw new EntityNotFoundError('ConfirmedAllocation', allocationId);
    }

    const allocData = allocSnap.data();
    if (!allocData) {
      throw new EntityNotFoundError('ConfirmedAllocation', allocationId);
    }
    const alloc = docToConfirmedAllocation(allocData);

    // 2. Tenant Isolation
    if (alloc.tenantId !== callerTenantId) {
      throw new PeriodProjectionAccessDeniedError(
        `tenant mismatch: allocation belongs to ${alloc.tenantId}, caller is ${callerTenantId}`
      );
    }

    // 3. Member Ownership Isolation
    if (alloc.memberUid !== callerMemberUid) {
      throw new PeriodProjectionAccessDeniedError(
        `member ownership violation: allocation belongs to ${alloc.memberUid}, caller is ${callerMemberUid}`
      );
    }

    // 4. Fetch associated ContributionSchedule if it exists
    let contributionSchedule: any = undefined;
    const obligationId = computeObligationId(alloc.tenantId, alloc.allocationId);
    const scheduleId = computeContributionScheduleId(alloc.tenantId, obligationId);
    const scheduleRef = this.db.doc(getContributionSchedulePath(scheduleId));
    const scheduleSnap = await scheduleRef.get();
    if (scheduleSnap.exists) {
      const schedData = scheduleSnap.data();
      if (schedData) {
        contributionSchedule = docToContributionSchedule(schedData);
      }
    }

    // 5. Pure derivation delegating to math kernel
    const projection = deriveMemberPeriodProjection({
      tenantId: alloc.tenantId,
      memberUid: alloc.memberUid,
      allocationId: alloc.allocationId,
      allocationUnitId: alloc.allocationUnitId,
      positionNumber: alloc.allocatedPosition,
      totalPeriods: alloc.durationPeriods,
      periodicContributionMinor: alloc.contributionMinor,
      currency: alloc.currency,
      contributionSchedule,
    });

    if (persist) {
      const projectionRef = this.db.doc(getMemberPeriodProjectionPath(callerMemberUid, projection.projectionId));
      await projectionRef.set(memberPeriodProjectionToDoc(projection));
    }

    return projection;
  }

  /**
   * Queries details for a specific period in a member's confirmed allocation.
   */
  async queryPeriodTimeline(
    callerTenantId: string,
    callerMemberUid: string,
    allocationId: string,
    periodNumber: number
  ): Promise<MemberPeriodDetail> {
    const projection = await this.getMemberPeriodProjection(callerTenantId, callerMemberUid, allocationId, false);
    validatePeriodNumberInRange(periodNumber, projection.totalPeriods);

    const periodDetail = projection.periods[periodNumber - 1];
    if (!periodDetail) {
      throw new PeriodProjectionMismatchError(`period ${periodNumber} not found in projection`);
    }

    return periodDetail;
  }

  /**
   * Computes period readiness summary for a cycle period.
   */
  async queryCyclePeriodReadiness(
    callerTenantId: string,
    unitId: string,
    periodNumber: number,
    recordedContributionsMinor = 0
  ): Promise<PeriodReadiness> {
    const projection = await this.getCyclePeriodProjection(callerTenantId, unitId, false);
    validatePeriodNumberInRange(periodNumber, projection.memberCount);

    const summary = projection.periods[periodNumber - 1];
    return computePeriodReadiness(summary, recordedContributionsMinor);
  }
}
