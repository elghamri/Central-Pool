/**
 * Central Pool Financial Validation Rules & Pure Calculations
 * Strictly adheres to integer minor math and SYMMETRICAL_V1 rules.
 */

import { FinancialObligation } from './financial_obligation';
import { ContributionSchedule } from './contribution_schedule';
import { ContributionEvent } from './contribution_event';
import { PayoutEntitlement, FinancialDisbursementSlot } from './payout_entitlement';
import { AccountingJournalEntry } from './accounting_journal_entry';
import {
  FinancialMathOverflowError,
  InvalidMinorAmountError,
  InvalidObligationError,
  InvalidContributionScheduleError,
  InvalidContributionEventError,
  InvalidPayoutEntitlementError,
  JournalEntryUnbalancedError,
  OddEntitlementError,
  PeriodOutOfBoundsError,
} from './financial_errors';
import { MissingTenantIdError, MissingMemberUidError, InvalidCurrencyError } from '../../domain/domain_errors';

/**
 * Validates that an amount is a safe, positive (or non-negative) integer minor unit.
 */
export function validateSafeMinorAmount(amount: unknown, fieldName: string, allowZero = false): asserts amount is number {
  if (typeof amount !== 'number' || !Number.isSafeInteger(amount)) {
    throw new InvalidMinorAmountError(fieldName, amount);
  }
  if (allowZero ? amount < 0 : amount <= 0) {
    throw new InvalidMinorAmountError(fieldName, amount);
  }
}

/**
 * Validates ISO 4217 Currency Code.
 */
export function validateFinancialCurrency(currency: string): void {
  if (!currency || typeof currency !== 'string' || !/^[A-Z]{3}$/.test(currency)) {
    throw new InvalidCurrencyError(currency);
  }
}

import {
  calculateTotalEntitlement as kernelCalculateTotalEntitlement,
  calculateTotalPot as kernelCalculateTotalPot,
  calculateMemberPrimaryPeriod,
  calculateMirrorPeriod,
  calculateDisbursementSplit,
} from '../../math/allocation_math';
import { validateSymmetricalEvenEntitlement } from '../../math/math_validation';

/**
 * Calculates member total entitlement E = N * C by directly invoking Step 1 Mathematical Kernel.
 * Provenance: services/cooperative-service/allocation_mathematical_kernel.go -> CalculateTotalEntitlement
 */
export function calculateFinancialTotalEntitlement(durationPeriods: number, contributionMinor: number): number {
  if (!Number.isSafeInteger(durationPeriods) || durationPeriods < 2 || durationPeriods > 12) {
    throw new InvalidObligationError(`durationPeriods must be integer in [2..12], got ${durationPeriods}`);
  }
  validateSafeMinorAmount(contributionMinor, 'contributionMinor');

  const entitlement = kernelCalculateTotalEntitlement(contributionMinor, durationPeriods);
  validateSymmetricalEvenEntitlement(entitlement);
  return entitlement;
}

/**
 * Calculates total pool pot = N^2 * C by directly invoking Step 1 Mathematical Kernel.
 * Provenance: services/cooperative-service/allocation_mathematical_kernel.go -> CalculateTotalPot
 */
export function calculateFinancialTotalPoolPot(durationPeriods: number, contributionMinor: number): number {
  if (!Number.isSafeInteger(durationPeriods) || durationPeriods < 2 || durationPeriods > 12) {
    throw new InvalidObligationError(`durationPeriods must be integer in [2..12], got ${durationPeriods}`);
  }
  validateSafeMinorAmount(contributionMinor, 'contributionMinor');

  return kernelCalculateTotalPot(contributionMinor, durationPeriods);
}

/**
 * Computes the SYMMETRICAL_V1 disbursement splits for a confirmed position by directly delegating
 * to Step 1 Mathematical Kernel: CalculateMemberPrimaryPeriod, CalculateMirrorPeriod, and CalculateDisbursementSplit.
 * Provenance: services/cooperative-service/allocation_mathematical_kernel.go
 */
export function calculateSymmetricalDisbursementSplits(
  positionNumber: number,
  durationPeriods: number,
  totalEntitlementMinor: number
): FinancialDisbursementSlot[] {
  if (!Number.isSafeInteger(positionNumber) || positionNumber < 1 || positionNumber > durationPeriods) {
    throw new PeriodOutOfBoundsError(positionNumber, durationPeriods);
  }
  validateSafeMinorAmount(totalEntitlementMinor, 'totalEntitlementMinor');

  // Step 1 Mathematical Kernel Delegation
  const { primaryPeriod: p1, isCenter } = calculateMemberPrimaryPeriod(durationPeriods, positionNumber);
  const p2 = calculateMirrorPeriod(durationPeriods, p1);
  const { primaryAmount, mirrorAmount, primaryBps, mirrorBps } = calculateDisbursementSplit(
    totalEntitlementMinor,
    'STANDARD_SPLIT',
    true // strictEvenSplit Central Pool guardrail
  );

  if (isCenter && p1 === p2) {
    return [
      {
        periodNumber: p1,
        amountMinor: totalEntitlementMinor,
        basisPoints: 10000,
        isCenter: true,
      },
    ];
  }

  const firstSlotPeriod = Math.min(p1, p2);
  const secondSlotPeriod = Math.max(p1, p2);
  const firstAmount = firstSlotPeriod === p1 ? primaryAmount : mirrorAmount;
  const secondAmount = firstSlotPeriod === p1 ? mirrorAmount : primaryAmount;
  const firstBps = firstSlotPeriod === p1 ? primaryBps : mirrorBps;
  const secondBps = firstSlotPeriod === p1 ? mirrorBps : primaryBps;

  return [
    {
      periodNumber: firstSlotPeriod,
      amountMinor: firstAmount,
      basisPoints: firstBps,
      isCenter: false,
    },
    {
      periodNumber: secondSlotPeriod,
      amountMinor: secondAmount,
      basisPoints: secondBps,
      isCenter: false,
    },
  ];
}

/**
 * Validates a FinancialObligation entity.
 */
export function validateFinancialObligation(obligation: FinancialObligation): void {
  if (!obligation.tenantId || typeof obligation.tenantId !== 'string') {
    throw new MissingTenantIdError('FinancialObligation');
  }
  if (!obligation.memberUid || typeof obligation.memberUid !== 'string') {
    throw new MissingMemberUidError('FinancialObligation');
  }
  if (!obligation.obligationId || typeof obligation.obligationId !== 'string') {
    throw new InvalidObligationError('obligationId is required and must be non-empty');
  }
  if (!obligation.allocationUnitId || typeof obligation.allocationUnitId !== 'string') {
    throw new InvalidObligationError('allocationUnitId is required and must be non-empty');
  }
  if (!obligation.allocationId || typeof obligation.allocationId !== 'string') {
    throw new InvalidObligationError('allocationId is required and must be non-empty');
  }

  validateFinancialCurrency(obligation.currency);
  validateSafeMinorAmount(obligation.contributionMinor, 'contributionMinor');
  validateSafeMinorAmount(obligation.totalObligationMinor, 'totalObligationMinor');
  validateSafeMinorAmount(obligation.fulfilledAmountMinor, 'fulfilledAmountMinor', true);

  if (!Number.isSafeInteger(obligation.totalPeriods) || obligation.totalPeriods < 2 || obligation.totalPeriods > 12) {
    throw new InvalidObligationError(`totalPeriods must be integer in [2..12], got ${obligation.totalPeriods}`);
  }
  if (!Number.isSafeInteger(obligation.positionNumber) || obligation.positionNumber < 1 || obligation.positionNumber > obligation.totalPeriods) {
    throw new InvalidObligationError(`positionNumber must be integer in [1..${obligation.totalPeriods}], got ${obligation.positionNumber}`);
  }

  const expectedTotal = obligation.totalPeriods * obligation.contributionMinor;
  if (obligation.totalObligationMinor !== expectedTotal) {
    throw new InvalidObligationError(
      `totalObligationMinor (${obligation.totalObligationMinor}) does not equal totalPeriods * contributionMinor (${expectedTotal})`
    );
  }

  validateSymmetricalEvenEntitlement(obligation.totalObligationMinor);

  if (obligation.fulfilledAmountMinor > obligation.totalObligationMinor) {
    throw new InvalidObligationError(
      `fulfilledAmountMinor (${obligation.fulfilledAmountMinor}) cannot exceed totalObligationMinor (${obligation.totalObligationMinor})`
    );
  }

  if (obligation.status === 'FULFILLED' && obligation.fulfilledAmountMinor !== obligation.totalObligationMinor) {
    throw new InvalidObligationError('Obligation marked FULFILLED must have fulfilledAmountMinor === totalObligationMinor');
  }
}

/**
 * Validates a ContributionSchedule entity.
 */
export function validateContributionSchedule(schedule: ContributionSchedule): void {
  if (!schedule.tenantId || typeof schedule.tenantId !== 'string') {
    throw new MissingTenantIdError('ContributionSchedule');
  }
  if (!schedule.memberUid || typeof schedule.memberUid !== 'string') {
    throw new MissingMemberUidError('ContributionSchedule');
  }
  if (!schedule.scheduleId || typeof schedule.scheduleId !== 'string') {
    throw new InvalidContributionScheduleError('scheduleId is required');
  }
  if (!schedule.obligationId || typeof schedule.obligationId !== 'string') {
    throw new InvalidContributionScheduleError('obligationId is required');
  }
  if (!schedule.allocationUnitId || typeof schedule.allocationUnitId !== 'string') {
    throw new InvalidContributionScheduleError('allocationUnitId is required');
  }

  if (!Number.isSafeInteger(schedule.totalPeriods) || schedule.totalPeriods < 2 || schedule.totalPeriods > 12) {
    throw new InvalidContributionScheduleError(`totalPeriods must be in [2..12], got ${schedule.totalPeriods}`);
  }

  if (!Array.isArray(schedule.periods) || schedule.periods.length !== schedule.totalPeriods) {
    throw new InvalidContributionScheduleError(`periods array must have exactly ${schedule.totalPeriods} elements`);
  }

  for (let i = 0; i < schedule.periods.length; i++) {
    const p = schedule.periods[i];
    if (p.periodNumber !== i + 1) {
      throw new InvalidContributionScheduleError(`Period at index ${i} must have periodNumber ${i + 1}`);
    }
    validateSafeMinorAmount(p.scheduledAmountMinor, `period[${i}].scheduledAmountMinor`);
    if (!['SCHEDULED', 'RECORDED'].includes(p.status)) {
      throw new InvalidContributionScheduleError(`Invalid status '${p.status}' for period ${p.periodNumber}`);
    }
  }
}

/**
 * Validates a ContributionEvent entity.
 */
export function validateContributionEvent(event: ContributionEvent): void {
  if (!event.tenantId || typeof event.tenantId !== 'string') {
    throw new MissingTenantIdError('ContributionEvent');
  }
  if (!event.memberUid || typeof event.memberUid !== 'string') {
    throw new MissingMemberUidError('ContributionEvent');
  }
  if (!event.contributionEventId || typeof event.contributionEventId !== 'string') {
    throw new InvalidContributionEventError('contributionEventId is required');
  }
  if (!event.obligationId || typeof event.obligationId !== 'string') {
    throw new InvalidContributionEventError('obligationId is required');
  }
  if (!event.allocationUnitId || typeof event.allocationUnitId !== 'string') {
    throw new InvalidContributionEventError('allocationUnitId is required');
  }
  if (event.journalEntryId !== undefined && (typeof event.journalEntryId !== 'string' || event.journalEntryId === '')) {
    throw new InvalidContributionEventError('journalEntryId must be a non-empty string when provided');
  }
  if (!event.idempotencyId || typeof event.idempotencyId !== 'string') {
    throw new InvalidContributionEventError('idempotencyId is required');
  }


  validateFinancialCurrency(event.currency);
  validateSafeMinorAmount(event.amountMinor, 'amountMinor');

  if (!Number.isSafeInteger(event.periodNumber) || event.periodNumber < 1) {
    throw new InvalidContributionEventError(`periodNumber must be positive integer >= 1, got ${event.periodNumber}`);
  }
}

/**
 * Validates a PayoutEntitlement entity.
 */
export function validatePayoutEntitlement(entitlement: PayoutEntitlement): void {
  if (!entitlement.tenantId || typeof entitlement.tenantId !== 'string') {
    throw new MissingTenantIdError('PayoutEntitlement');
  }
  if (!entitlement.memberUid || typeof entitlement.memberUid !== 'string') {
    throw new MissingMemberUidError('PayoutEntitlement');
  }
  if (!entitlement.payoutEntitlementId || typeof entitlement.payoutEntitlementId !== 'string') {
    throw new InvalidPayoutEntitlementError('payoutEntitlementId is required');
  }
  if (!entitlement.allocationUnitId || typeof entitlement.allocationUnitId !== 'string') {
    throw new InvalidPayoutEntitlementError('allocationUnitId is required');
  }
  if (!entitlement.allocationId || typeof entitlement.allocationId !== 'string') {
    throw new InvalidPayoutEntitlementError('allocationId is required');
  }

  validateFinancialCurrency(entitlement.currency);
  validateSafeMinorAmount(entitlement.totalEntitlementMinor, 'totalEntitlementMinor');
  validateSymmetricalEvenEntitlement(entitlement.totalEntitlementMinor);

  if (!Array.isArray(entitlement.splits) || entitlement.splits.length < 1 || entitlement.splits.length > 2) {
    throw new InvalidPayoutEntitlementError('splits must contain 1 or 2 disbursement slots');
  }

  let sumAmount = 0;
  let sumBps = 0;

  for (const slot of entitlement.splits) {
    validateSafeMinorAmount(slot.amountMinor, 'slot.amountMinor');
    if (!Number.isSafeInteger(slot.periodNumber) || slot.periodNumber < 1) {
      throw new InvalidPayoutEntitlementError(`slot periodNumber must be positive integer, got ${slot.periodNumber}`);
    }
    sumAmount += slot.amountMinor;
    sumBps += slot.basisPoints;
  }

  if (sumAmount !== entitlement.totalEntitlementMinor) {
    throw new InvalidPayoutEntitlementError(
      `Disbursement splits sum (${sumAmount}) does not equal totalEntitlementMinor (${entitlement.totalEntitlementMinor})`
    );
  }
  if (sumBps !== 10000) {
    throw new InvalidPayoutEntitlementError(`Disbursement splits basis points sum (${sumBps}) must equal 10000`);
  }
}

/**
 * Validates an AccountingJournalEntry entity for strict double-entry balance.
 */
export function validateAccountingJournalEntry(entry: AccountingJournalEntry): void {
  if (!entry.tenantId || typeof entry.tenantId !== 'string') {
    throw new MissingTenantIdError('AccountingJournalEntry');
  }
  if (!entry.journalEntryId || typeof entry.journalEntryId !== 'string') {
    throw new JournalEntryUnbalancedError(0, 0);
  }
  if (!entry.referenceId || typeof entry.referenceId !== 'string') {
    throw new InvalidObligationError('referenceId is required for JournalEntry');
  }
  if (!entry.idempotencyId || typeof entry.idempotencyId !== 'string') {
    throw new InvalidObligationError('idempotencyId is required for JournalEntry');
  }

  validateFinancialCurrency(entry.currency);
  validateSafeMinorAmount(entry.totalDebitMinor, 'totalDebitMinor');
  validateSafeMinorAmount(entry.totalCreditMinor, 'totalCreditMinor');

  if (entry.totalDebitMinor !== entry.totalCreditMinor) {
    throw new JournalEntryUnbalancedError(entry.totalDebitMinor, entry.totalCreditMinor);
  }

  if (!Array.isArray(entry.lines) || entry.lines.length < 2) {
    throw new InvalidObligationError('AccountingJournalEntry must contain at least 2 lines');
  }

  let sumDebits = 0;
  let sumCredits = 0;

  for (const line of entry.lines) {
    if (!line.accountCode || typeof line.accountCode !== 'string') {
      throw new InvalidObligationError('Each journal line must specify accountCode');
    }
    validateSafeMinorAmount(line.debitMinor, 'line.debitMinor', true);
    validateSafeMinorAmount(line.creditMinor, 'line.creditMinor', true);

    if (line.debitMinor > 0 && line.creditMinor > 0) {
      throw new InvalidObligationError(`Journal line on ${line.accountCode} cannot have both debit and credit > 0`);
    }
    if (line.debitMinor === 0 && line.creditMinor === 0) {
      throw new InvalidObligationError(`Journal line on ${line.accountCode} must have either debit > 0 or credit > 0`);
    }

    sumDebits += line.debitMinor;
    sumCredits += line.creditMinor;
  }

  if (sumDebits !== entry.totalDebitMinor || sumCredits !== entry.totalCreditMinor || sumDebits !== sumCredits) {
    throw new JournalEntryUnbalancedError(sumDebits, sumCredits);
  }
}
