/**
 * Central Pool Step 6: Contribution Recording Service
 * Orchestrates atomic recording of an internal simulation contribution event:
 * - Creates ContributionEvent (Authoritative: /contribution_events/{contributionEventId})
 * - Updates ContributionSchedule (Authoritative: /contribution_schedules/{scheduleId}, period -> RECORDED)
 * - Updates FinancialObligation (Authoritative: /financial_obligations/{obligationId}, fulfilledAmountMinor += C, status -> ACTIVE | FULFILLED)
 * - Updates Member Presentation Projection (Projection: /users/{uid}/financial_obligations/{obligationId})
 *
 * ACCOUNTING PROVENANCE & CLOSURE (F6-BLOCKER-01):
 * - Double-entry General Ledger posting (including account codes 1000, 1100) is classified as
 *   UNRESOLVED_ACCOUNTING_DECISION and quarantined from authoritative execution.
 * - All executed inside an atomic Firestore Transaction with strict idempotency.
 */

import { Firestore, Transaction } from 'firebase-admin/firestore';
import {
  FinancialObligation,
  ContributionSchedule,
  ContributionEvent,
  validateFinancialObligation,
  validateContributionSchedule,
  validateContributionEvent,
} from '../domain';
import {
  computeContributionEventId,
  computeContributionScheduleId,
} from '../identities';
import {
  financialObligationToDoc,
  docToFinancialObligation,
  contributionScheduleToDoc,
  docToContributionSchedule,
  contributionEventToDoc,
  docToContributionEvent,
  financialObligationToProjectionDoc,
} from '../dto';
import {
  getFinancialObligationPath,
  getContributionSchedulePath,
  getContributionEventPath,
  getMemberObligationReceiptPath,
} from '../../domain/domain_paths';
import { sha256Hex } from '../../matching/compatibility_key';
import { MissingTenantIdError, MissingMemberUidError } from '../../domain/domain_errors';
import {
  InvalidContributionEventError,
  ContributionAlreadyRecordedError,
  PeriodOutOfBoundsError,
} from '../domain/financial_errors';
import { EntityNotFoundError } from '../../persistence/persistence_errors';

export interface RecordContributionInput {
  tenantId: string;
  memberUid: string;
  obligationId: string;
  periodNumber: number;
  idempotencyKey?: string;
  nowIso?: string;
}

export interface RecordContributionResult {
  contributionEvent: ContributionEvent;
  updatedObligation: FinancialObligation;
  updatedSchedule: ContributionSchedule;
  isIdempotentReplay: boolean;
}

export function computeContributionIdempotencyId(
  tenantId: string,
  memberUid: string,
  clientKey: string
): string {
  return `idemp_ce_${sha256Hex(`${tenantId}:${memberUid}:${clientKey}`)}`;
}

export class ContributionRecordingService {
  constructor(private readonly db: Firestore) {}

  /**
   * Records a contribution period inside an atomic Firestore Transaction.
   */
  async recordContribution(
    input: RecordContributionInput,
    existingTransaction?: Transaction
  ): Promise<RecordContributionResult> {
    if (existingTransaction) {
      return this.executeInTransaction(input, existingTransaction);
    }
    return this.db.runTransaction((tx) => this.executeInTransaction(input, tx));
  }

  private async executeInTransaction(
    input: RecordContributionInput,
    tx: Transaction
  ): Promise<RecordContributionResult> {
    const { tenantId, memberUid, obligationId, periodNumber, idempotencyKey } = input;

    if (!tenantId || typeof tenantId !== 'string') {
      throw new MissingTenantIdError('ContributionRecordingService');
    }
    if (!memberUid || typeof memberUid !== 'string') {
      throw new MissingMemberUidError('ContributionRecordingService');
    }
    if (!obligationId || typeof obligationId !== 'string') {
      throw new InvalidContributionEventError('obligationId is required');
    }
    if (!Number.isSafeInteger(periodNumber) || periodNumber < 1) {
      throw new InvalidContributionEventError(`periodNumber must be positive integer >= 1, got ${periodNumber}`);
    }

    const nowIso = input.nowIso || new Date().toISOString();

    const contributionEventId = computeContributionEventId(tenantId, obligationId, periodNumber);
    const scheduleId = computeContributionScheduleId(tenantId, obligationId);
    const idempotencyId = idempotencyKey
      ? computeContributionIdempotencyId(tenantId, memberUid, idempotencyKey)
      : `idemp_${contributionEventId}`;

    const eventRef = this.db.doc(getContributionEventPath(contributionEventId));
    const obligationRef = this.db.doc(getFinancialObligationPath(obligationId));
    const scheduleRef = this.db.doc(getContributionSchedulePath(scheduleId));
    const memberObligationRef = this.db.doc(getMemberObligationReceiptPath(memberUid, obligationId));

    // Check if event already exists (Idempotent replay)
    const eventSnap = await tx.get(eventRef);
    if (eventSnap.exists) {
      const contributionEvent = docToContributionEvent(eventSnap.data());
      const obligationSnap = await tx.get(obligationRef);
      const scheduleSnap = await tx.get(scheduleRef);

      const updatedObligation = docToFinancialObligation(obligationSnap.data());
      const updatedSchedule = docToContributionSchedule(scheduleSnap.data());

      return {
        contributionEvent,
        updatedObligation,
        updatedSchedule,
        isIdempotentReplay: true,
      };
    }

    // Read obligation
    const obligationSnap = await tx.get(obligationRef);
    if (!obligationSnap.exists) {
      throw new EntityNotFoundError('FinancialObligation', obligationId);
    }
    const obligation = docToFinancialObligation(obligationSnap.data());

    // Boundary & tenant validation
    if (obligation.tenantId !== tenantId) {
      throw new InvalidContributionEventError(`Tenant ID mismatch: obligation tenant is '${obligation.tenantId}', requested '${tenantId}'`);
    }
    if (obligation.memberUid !== memberUid) {
      throw new InvalidContributionEventError(`Member UID mismatch: obligation member is '${obligation.memberUid}', requested '${memberUid}'`);
    }
    if (periodNumber > obligation.totalPeriods) {
      throw new PeriodOutOfBoundsError(periodNumber, obligation.totalPeriods);
    }

    // Read schedule
    const scheduleSnap = await tx.get(scheduleRef);
    if (!scheduleSnap.exists) {
      throw new EntityNotFoundError('ContributionSchedule', scheduleId);
    }
    const schedule = docToContributionSchedule(scheduleSnap.data());

    const targetPeriod = schedule.periods.find((p) => p.periodNumber === periodNumber);
    if (!targetPeriod) {
      throw new PeriodOutOfBoundsError(periodNumber, schedule.totalPeriods);
    }
    if (targetPeriod.status === 'RECORDED') {
      throw new ContributionAlreadyRecordedError(obligationId, periodNumber);
    }

    // Advance financial state
    const contributionAmount = targetPeriod.scheduledAmountMinor;
    const newFulfilledAmount = obligation.fulfilledAmountMinor + contributionAmount;
    const newStatus = newFulfilledAmount >= obligation.totalObligationMinor ? 'FULFILLED' : 'ACTIVE';

    const updatedObligation: FinancialObligation = {
      ...obligation,
      fulfilledAmountMinor: newFulfilledAmount,
      status: newStatus,
      updatedAt: nowIso,
      version: obligation.version + 1,
    };

    const updatedPeriods = schedule.periods.map((p) => {
      if (p.periodNumber === periodNumber) {
        return {
          ...p,
          status: 'RECORDED' as const,
          recordedAt: nowIso,
          contributionEventId,
        };
      }
      return p;
    });

    const updatedSchedule: ContributionSchedule = {
      ...schedule,
      periods: updatedPeriods,
      updatedAt: nowIso,
      version: schedule.version + 1,
    };

    const contributionEvent: ContributionEvent = {
      contributionEventId,
      tenantId,
      memberUid,
      obligationId,
      allocationUnitId: obligation.allocationUnitId,
      periodNumber,
      amountMinor: contributionAmount,
      currency: obligation.currency,
      recordedAt: nowIso,
      idempotencyId,
    };

    // Validate authoritative entities
    validateContributionEvent(contributionEvent);
    validateFinancialObligation(updatedObligation);
    validateContributionSchedule(updatedSchedule);

    // Stage atomic mutations for authoritative entities and member projections
    tx.set(eventRef, contributionEventToDoc(contributionEvent));
    tx.set(obligationRef, financialObligationToDoc(updatedObligation));
    tx.set(scheduleRef, contributionScheduleToDoc(updatedSchedule));
    tx.set(memberObligationRef, financialObligationToProjectionDoc(updatedObligation));

    return {
      contributionEvent,
      updatedObligation,
      updatedSchedule,
      isIdempotentReplay: false,
    };
  }
}

