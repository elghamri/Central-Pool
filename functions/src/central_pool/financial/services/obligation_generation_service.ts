/**
 * Central Pool Step 6: Financial Obligation Generation Service
 * Orchestrates atomic generation of:
 * - Financial Obligation (Authoritative: /financial_obligations/{obligationId})
 * - Contribution Schedule (Authoritative: /contribution_schedules/{scheduleId})
 * - Payout Entitlement (Authoritative: /payout_entitlements/{payoutEntitlementId})
 * - Member Presentation Projections (Projections: /users/{uid}/financial_obligations, /users/{uid}/payout_entitlements)
 *
 * ACCOUNTING PROVENANCE & CLOSURE (F6-BLOCKER-01):
 * - The General Ledger double-entry posting model (including OBLIGATION_RECOGNITION, 1100-MEMBER-RECEIVABLE,
 *   2100-POOL-OBLIGATION-RESERVE) is classified as UNRESOLVED_ACCOUNTING_DECISION because explicit account
 *   identities, recognition events, and debit/credit directions are not ratified in Step 1-5 contracts.
 * - In accordance with F6-BLOCKER-01, the initial journal entry posting is quarantined from authoritative execution.
 * - All executed inside an atomic Firestore Transaction with strict idempotency.
 */

import { Firestore, Transaction } from 'firebase-admin/firestore';
import {
  FinancialObligation,
  ContributionSchedule,
  ScheduledContributionPeriod,
  PayoutEntitlement,
  calculateFinancialTotalEntitlement,
  calculateSymmetricalDisbursementSplits,
  validateFinancialObligation,
  validateContributionSchedule,
  validatePayoutEntitlement,
  validateFinancialCurrency,
  validateSafeMinorAmount,
} from '../domain';
import {
  computeObligationId,
  computeContributionScheduleId,
  computePayoutEntitlementId,
} from '../identities';
import {
  financialObligationToDoc,
  docToFinancialObligation,
  contributionScheduleToDoc,
  docToContributionSchedule,
  payoutEntitlementToDoc,
  docToPayoutEntitlement,
  financialObligationToProjectionDoc,
  payoutEntitlementToProjectionDoc,
} from '../dto';
import {
  getFinancialObligationPath,
  getContributionSchedulePath,
  getPayoutEntitlementPath,
  getMemberObligationReceiptPath,
  getMemberPayoutEntitlementReceiptPath,
} from '../../domain/domain_paths';
import { sha256Hex } from '../../matching/compatibility_key';
import { MissingTenantIdError, MissingMemberUidError } from '../../domain/domain_errors';
import { InvalidObligationError } from '../domain/financial_errors';

export interface GenerateObligationInput {
  tenantId: string;
  memberUid: string;
  allocationId: string;
  allocationUnitId: string;
  positionNumber: number;
  contributionMinor: number;
  totalPeriods: number;
  currency: string;
  idempotencyKey?: string;
  nowIso?: string;
}

export interface GenerateObligationResult {
  obligation: FinancialObligation;
  contributionSchedule: ContributionSchedule;
  payoutEntitlement: PayoutEntitlement;
  isIdempotentReplay: boolean;
}

export function computeObligationIdempotencyId(
  tenantId: string,
  memberUid: string,
  clientKey: string
): string {
  return `idemp_ob_${sha256Hex(`${tenantId}:${memberUid}:${clientKey}`)}`;
}

export class ObligationGenerationService {
  constructor(private readonly db: Firestore) {}

  /**
   * Generates obligation, schedule, entitlement, and member projections.
   * If existingTransaction is provided, executes reads/writes against it; otherwise creates a new transaction.
   */
  async generateObligation(
    input: GenerateObligationInput,
    existingTransaction?: Transaction
  ): Promise<GenerateObligationResult> {
    if (existingTransaction) {
      return this.executeInTransaction(input, existingTransaction);
    }
    return this.db.runTransaction((tx) => this.executeInTransaction(input, tx));
  }

  private async executeInTransaction(
    input: GenerateObligationInput,
    tx: Transaction
  ): Promise<GenerateObligationResult> {
    const {
      tenantId,
      memberUid,
      allocationId,
      allocationUnitId,
      positionNumber,
      contributionMinor,
      totalPeriods,
      currency,
    } = input;

    if (!tenantId || typeof tenantId !== 'string') {
      throw new MissingTenantIdError('ObligationGenerationService');
    }
    if (!memberUid || typeof memberUid !== 'string') {
      throw new MissingMemberUidError('ObligationGenerationService');
    }
    if (!allocationId || typeof allocationId !== 'string') {
      throw new InvalidObligationError('allocationId is required');
    }
    if (!allocationUnitId || typeof allocationUnitId !== 'string') {
      throw new InvalidObligationError('allocationUnitId is required');
    }

    validateFinancialCurrency(currency);
    validateSafeMinorAmount(contributionMinor, 'contributionMinor');

    if (!Number.isSafeInteger(totalPeriods) || totalPeriods < 2 || totalPeriods > 12) {
      throw new InvalidObligationError(`totalPeriods must be in [2..12], got ${totalPeriods}`);
    }
    if (!Number.isSafeInteger(positionNumber) || positionNumber < 1 || positionNumber > totalPeriods) {
      throw new InvalidObligationError(`positionNumber must be in [1..${totalPeriods}], got ${positionNumber}`);
    }

    const nowIso = input.nowIso || new Date().toISOString();

    // Deterministic IDs
    const obligationId = computeObligationId(tenantId, allocationId);
    const scheduleId = computeContributionScheduleId(tenantId, obligationId);
    const payoutEntitlementId = computePayoutEntitlementId(tenantId, allocationId);

    const obligationRef = this.db.doc(getFinancialObligationPath(obligationId));
    const scheduleRef = this.db.doc(getContributionSchedulePath(scheduleId));
    const entitlementRef = this.db.doc(getPayoutEntitlementPath(payoutEntitlementId));
    const memberObligationRef = this.db.doc(getMemberObligationReceiptPath(memberUid, obligationId));
    const memberEntitlementRef = this.db.doc(getMemberPayoutEntitlementReceiptPath(memberUid, payoutEntitlementId));

    // Check existing (Idempotent replay)
    const existingObligationSnap = await tx.get(obligationRef);
    if (existingObligationSnap.exists) {
      const obligation = docToFinancialObligation(existingObligationSnap.data());
      const scheduleSnap = await tx.get(scheduleRef);
      const entitlementSnap = await tx.get(entitlementRef);

      const contributionSchedule = docToContributionSchedule(scheduleSnap.data());
      const payoutEntitlement = docToPayoutEntitlement(entitlementSnap.data());

      return {
        obligation,
        contributionSchedule,
        payoutEntitlement,
        isIdempotentReplay: true,
      };
    }

    // Pure Calculations
    const totalObligationMinor = calculateFinancialTotalEntitlement(totalPeriods, contributionMinor);
    const disbursementSplits = calculateSymmetricalDisbursementSplits(positionNumber, totalPeriods, totalObligationMinor);

    // Build Authoritative Entities
    const obligation: FinancialObligation = {
      obligationId,
      tenantId,
      memberUid,
      allocationUnitId,
      allocationId,
      positionNumber,
      totalObligationMinor,
      contributionMinor,
      totalPeriods,
      fulfilledAmountMinor: 0,
      currency,
      status: 'ACTIVE',
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 1,
    };

    const scheduledPeriods: ScheduledContributionPeriod[] = [];
    for (let p = 1; p <= totalPeriods; p++) {
      scheduledPeriods.push({
        periodNumber: p,
        scheduledAmountMinor: contributionMinor,
        status: 'SCHEDULED',
      });
    }

    const contributionSchedule: ContributionSchedule = {
      scheduleId,
      obligationId,
      tenantId,
      memberUid,
      allocationUnitId,
      totalPeriods,
      periods: scheduledPeriods,
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 1,
    };

    const payoutEntitlement: PayoutEntitlement = {
      payoutEntitlementId,
      tenantId,
      memberUid,
      allocationUnitId,
      allocationId,
      positionNumber,
      totalEntitlementMinor: totalObligationMinor,
      currency,
      splits: disbursementSplits,
      status: 'SCHEDULED',
      calculatedAt: nowIso,
      version: 1,
    };

    // Validate all authoritative entities before staging writes
    validateFinancialObligation(obligation);
    validateContributionSchedule(contributionSchedule);
    validatePayoutEntitlement(payoutEntitlement);

    // Stage atomic writes for authoritative entities and member projections
    tx.set(obligationRef, financialObligationToDoc(obligation));
    tx.set(scheduleRef, contributionScheduleToDoc(contributionSchedule));
    tx.set(entitlementRef, payoutEntitlementToDoc(payoutEntitlement));
    tx.set(memberObligationRef, financialObligationToProjectionDoc(obligation));
    tx.set(memberEntitlementRef, payoutEntitlementToProjectionDoc(payoutEntitlement));

    return {
      obligation,
      contributionSchedule,
      payoutEntitlement,
      isIdempotentReplay: false,
    };
  }
}

