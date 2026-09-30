/**
 * Central Pool Domain Errors: Period Engine & Projections
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 7)
 */

export { InvalidPeriodNumberError } from '../../math/math_errors';

export class PeriodProjectionAccessDeniedError extends Error {
  constructor(reason: string) {
    super(`period access error: unauthorized projection access; ${reason}`);
    this.name = 'PeriodProjectionAccessDeniedError';
  }
}

export class PeriodProjectionMismatchError extends Error {
  constructor(message: string) {
    super(`period error: projection mismatch; ${message}`);
    this.name = 'PeriodProjectionMismatchError';
  }
}

export class PeriodMathConservationError extends Error {
  constructor(message: string) {
    super(`period invariant violation: mathematical conservation check failed; ${message}`);
    this.name = 'PeriodMathConservationError';
  }
}
