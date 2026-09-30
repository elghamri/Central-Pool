/**
 * Central Pool TypeScript Mathematical Kernel - Validation Functions
 * Reference: services/cooperative-service/allocation_mathematical_kernel.go
 */

import {
  InvalidMemberCountError,
  InvalidPeriodicContributionError,
  InvalidPositionNumberError,
  InvalidPeriodNumberError,
  SafeIntegerOverflowError,
  OddEntitlementRejectionError,
} from './math_errors';
import { MAX_SAFE_CONTRIBUTION_MINOR } from './math_types';

/**
 * Validates member count N.
 * Go reference requires N >= 2. Central Pool contract defines N in [2..12].
 */
export function validateMemberCount(memberCount: number, strictCentralPoolBounds = false): void {
  if (!Number.isSafeInteger(memberCount)) {
    throw new InvalidMemberCountError('allocation error: member count N must be a safe integer');
  }
  if (strictCentralPoolBounds) {
    if (memberCount < 2 || memberCount > 12) {
      throw new InvalidMemberCountError(`allocation error: member count N must be between 2 and 12, got ${memberCount}`);
    }
  } else {
    if (memberCount < 2) {
      throw new InvalidMemberCountError(`allocation error: member count N must be >= 2, got ${memberCount}`);
    }
  }
}

/**
 * Validates periodic contribution C.
 * Must be a positive safe integer and within the safe lifecycle pot limit.
 */
export function validatePeriodicContribution(periodicContributionMinor: number, memberCount?: number): void {
  if (!Number.isSafeInteger(periodicContributionMinor)) {
    throw new InvalidPeriodicContributionError('allocation error: periodic contribution must be a safe integer');
  }
  if (periodicContributionMinor <= 0) {
    throw new InvalidPeriodicContributionError(
      `allocation error: periodic contribution must be positive and non-zero, got ${periodicContributionMinor}`
    );
  }

  // Check pre-multiplication limit for max member count
  if (periodicContributionMinor > MAX_SAFE_CONTRIBUTION_MINOR) {
    throw new SafeIntegerOverflowError(
      `allocation error: periodic contribution ${periodicContributionMinor} exceeds MAX_SAFE_CONTRIBUTION_MINOR (${MAX_SAFE_CONTRIBUTION_MINOR})`
    );
  }

  // If memberCount is provided, check exact N^2 * C multiplication safety
  if (memberCount !== undefined && Number.isSafeInteger(memberCount) && memberCount >= 2) {
    const nSquared = memberCount * memberCount;
    validateSafeMultiplication(nSquared, periodicContributionMinor);
  }
}

/**
 * Validates position number in [1..N].
 */
export function validatePositionNumber(position: number, memberCount: number): void {
  if (!Number.isSafeInteger(position)) {
    throw new InvalidPositionNumberError('allocation error: position must be a safe integer');
  }
  if (position < 1 || position > memberCount) {
    throw new InvalidPositionNumberError(
      `allocation error: position number must be between 1 and N (position=${position}, memberCount=${memberCount})`
    );
  }
}

/**
 * Validates period number in [1..N].
 */
export function validatePeriodNumber(period: number, memberCount: number): void {
  if (!Number.isSafeInteger(period)) {
    throw new InvalidPeriodNumberError('allocation error: period must be a safe integer');
  }
  if (period < 1 || period > memberCount) {
    throw new InvalidPeriodNumberError(
      `allocation error: period number must be between 1 and N (period=${period}, memberCount=${memberCount})`
    );
  }
}

/**
 * Guards multiplication before performing the operation.
 * Guarantees that a * b does not exceed Number.MAX_SAFE_INTEGER.
 */
export function validateSafeMultiplication(a: number, b: number): void {
  if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b)) {
    throw new SafeIntegerOverflowError('allocation error: multiplication operands must be safe integers');
  }
  if (a === 0 || b === 0) return;

  const maxAllowed = Math.floor(Number.MAX_SAFE_INTEGER / Math.abs(a));
  if (Math.abs(b) > maxAllowed) {
    throw new SafeIntegerOverflowError(
      `allocation error: multiplication ${a} * ${b} exceeds Number.MAX_SAFE_INTEGER (${Number.MAX_SAFE_INTEGER})`
    );
  }
}

/**
 * Central Pool Guardrail: Asserts that total contractual entitlement E = N * C is an even integer
 * for unskewed 50/50 symmetrical split disbursements.
 */
export function validateSymmetricalEvenEntitlement(totalEntitlementMinor: number): void {
  if (!Number.isSafeInteger(totalEntitlementMinor)) {
    throw new SafeIntegerOverflowError('allocation error: total entitlement must be a safe integer');
  }
  if (totalEntitlementMinor % 2 !== 0) {
    throw new OddEntitlementRejectionError(
      `allocation error: total entitlement ${totalEntitlementMinor} is odd; symmetrical 50/50 split requires an even integer`
    );
  }
}
