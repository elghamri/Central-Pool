/**
 * Central Pool Financial Domain Error Classes
 */

import { CentralPoolDomainError } from '../../domain/domain_errors';

export class InvalidMinorAmountError extends CentralPoolDomainError {
  constructor(field: string, value: unknown) {
    super(
      `Invalid monetary minor amount for ${field}: expected positive safe integer, got ${value}`,
      'INVALID_MINOR_AMOUNT'
    );
  }
}

export class FinancialMathOverflowError extends CentralPoolDomainError {
  constructor(operation: string) {
    super(`Financial calculation overflowed JavaScript safe integer range in ${operation}`, 'FINANCIAL_MATH_OVERFLOW');
  }
}

import { OddEntitlementRejectionError } from '../../math/math_errors';

export { OddEntitlementRejectionError };
export const OddEntitlementError = OddEntitlementRejectionError;

export class JournalEntryUnbalancedError extends CentralPoolDomainError {
  constructor(totalDebit: number, totalCredit: number) {
    super(
      `Double-entry journal entry is unbalanced: debits (${totalDebit}) !== credits (${totalCredit})`,
      'JOURNAL_ENTRY_UNBALANCED'
    );
  }
}

export class InvalidObligationError extends CentralPoolDomainError {
  constructor(message: string) {
    super(`Invalid Financial Obligation: ${message}`, 'INVALID_OBLIGATION');
  }
}

export class InvalidContributionScheduleError extends CentralPoolDomainError {
  constructor(message: string) {
    super(`Invalid Contribution Schedule: ${message}`, 'INVALID_CONTRIBUTION_SCHEDULE');
  }
}

export class InvalidContributionEventError extends CentralPoolDomainError {
  constructor(message: string) {
    super(`Invalid Contribution Event: ${message}`, 'INVALID_CONTRIBUTION_EVENT');
  }
}

export class InvalidPayoutEntitlementError extends CentralPoolDomainError {
  constructor(message: string) {
    super(`Invalid Payout Entitlement: ${message}`, 'INVALID_PAYOUT_ENTITLEMENT');
  }
}

export class ContributionAlreadyRecordedError extends CentralPoolDomainError {
  constructor(obligationId: string, periodNumber: number) {
    super(
      `Contribution for obligation '${obligationId}' period ${periodNumber} has already been recorded`,
      'CONTRIBUTION_ALREADY_RECORDED'
    );
  }
}

export class PeriodOutOfBoundsError extends CentralPoolDomainError {
  constructor(periodNumber: number, totalPeriods: number) {
    super(
      `Period number ${periodNumber} is out of bounds for duration ${totalPeriods}`,
      'PERIOD_OUT_OF_BOUNDS'
    );
  }
}
