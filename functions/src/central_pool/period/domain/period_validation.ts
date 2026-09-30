/**
 * Central Pool Domain Validation: Period Engine & Projections
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 7)
 */

import { MissingTenantIdError, MissingMemberUidError, InvalidCurrencyError } from '../../domain/domain_errors';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validatePositionNumber,
  validatePeriodNumber,
  validateSymmetricalEvenEntitlement,
} from '../../math/math_validation';
import { validateSafeMinorAmount } from '../../financial/domain/financial_validation';
import { PeriodProjectionMismatchError } from './period_errors';

/**
 * Validates that period number is an integer in [1..durationPeriods].
 */
export function validatePeriodNumberInRange(periodNumber: number, durationPeriods: number): void {
  validateMemberCount(durationPeriods);
  validatePeriodNumber(periodNumber, durationPeriods);
}

/**
 * Validates member projection context parameters.
 */
export function validatePeriodProjectionContext(tenantId: string, memberUid: string, allocationId: string): void {
  if (!tenantId || typeof tenantId !== 'string' || tenantId.trim().length === 0) {
    throw new MissingTenantIdError('validatePeriodProjectionContext');
  }
  if (!memberUid || typeof memberUid !== 'string' || memberUid.trim().length === 0) {
    throw new MissingMemberUidError('validatePeriodProjectionContext');
  }
  if (!allocationId || typeof allocationId !== 'string' || allocationId.trim().length === 0) {
    throw new PeriodProjectionMismatchError('allocationId must be a non-empty string');
  }
}

/**
 * Validates currency string.
 */
export function validatePeriodCurrency(currency: string): void {
  if (!currency || typeof currency !== 'string' || !/^[A-Z]{3}$/.test(currency)) {
    throw new InvalidCurrencyError(currency);
  }
}

export {
  validateMemberCount,
  validatePeriodicContribution,
  validatePositionNumber,
  validatePeriodNumber,
  validateSymmetricalEvenEntitlement,
  validateSafeMinorAmount,
};
