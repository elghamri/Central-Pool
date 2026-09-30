/**
 * Central Pool Step 8: Deterministic API Error Mapping
 * Translates domain, math, persistence, confirmation, financial, and period errors into standard Firebase HttpsError instances.
 */

import { HttpsError, FunctionsErrorCode } from 'firebase-functions/v2/https';

export class ApiError extends Error {
  constructor(
    public readonly code: FunctionsErrorCode,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }

  toHttpsError(): HttpsError {
    return new HttpsError(this.code, this.message, this.details);
  }
}

export class UnauthenticatedError extends Error {
  constructor(message = 'User is unauthenticated') {
    super(message);
    this.name = 'UnauthenticatedError';
  }
}

export class UnauthorizedAccessError extends Error {
  constructor(message = 'User is unauthorized to perform this action') {
    super(message);
    this.name = 'UnauthorizedAccessError';
  }
}

/**
 * Maps any internal error into a deterministic Firebase HttpsError.
 */
export function mapToHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) {
    return error;
  }

  if (error instanceof ApiError) {
    return error.toHttpsError();
  }

  const errName = (error as any)?.name || '';
  const message = (error as any)?.message || 'Internal application error';

  // 1. Unauthenticated
  if (
    errName === 'UnauthenticatedError' ||
    message.includes('unauthenticated') ||
    message.includes('auth token')
  ) {
    return new HttpsError('unauthenticated', message);
  }

  // 2. Permission Denied (Tenant / Member Ownership / Access Denied)
  if (
    errName === 'TenantIsolationViolationError' ||
    errName === 'PeriodProjectionAccessDeniedError' ||
    errName === 'UnauthorizedAccessError' ||
    message.includes('tenant mismatch') ||
    message.includes('member ownership violation') ||
    message.includes('access denied') ||
    message.includes('unauthorized')
  ) {
    return new HttpsError('permission-denied', message);
  }

  // 3. Not Found
  if (
    errName === 'EntityNotFoundError' ||
    errName === 'FinancialEntityNotFoundError' ||
    message.includes('not found') ||
    message.includes('does not exist')
  ) {
    return new HttpsError('not-found', message);
  }

  // 4. Already Exists / Idempotency Conflicts
  if (
    errName === 'EntityAlreadyExistsError' ||
    errName === 'DuplicateContributionEventError' ||
    errName === 'PositionAlreadyOccupiedError' ||
    message.includes('already exists') ||
    message.includes('duplicate') ||
    message.includes('already occupied')
  ) {
    return new HttpsError('already-exists', message);
  }

  // 5. Failed Precondition (Lifecycle state transitions, revalidation, expiration, invariant balances)
  if (
    errName === 'InvalidStateTransitionError' ||
    errName === 'InvalidRequestStateError' ||
    errName === 'InvalidUnitStateError' ||
    errName === 'CandidateExpiredError' ||
    errName === 'CandidateRevalidationFailedError' ||
    errName === 'CandidateInvalidError' ||
    errName === 'AllocationUnitNotFormingError' ||
    errName === 'AllocationUnitCapacityExceededError' ||
    errName === 'UnitCapacityExceededError' ||
    errName === 'ParticipationRequestNotConfirmableError' ||
    errName === 'ConfirmationRevalidationFailedError' ||
    errName === 'JournalEntryUnbalancedError' ||
    errName === 'InvalidObligationError' ||
    errName === 'InvalidContributionScheduleError' ||
    errName === 'InvalidContributionEventError' ||
    errName === 'InvalidPayoutEntitlementError' ||
    errName === 'ContributionAlreadyRecordedError' ||
    errName === 'PeriodOutOfBoundsError' ||
    errName === 'FinancialInvariantViolationError' ||
    errName === 'PeriodInvariantViolationError' ||
    message.includes('invalid state') ||
    message.includes('expired') ||
    message.includes('revalidation failed') ||
    message.includes('capacity exceeded') ||
    message.includes('unbalanced')
  ) {
    return new HttpsError('failed-precondition', message);
  }

  // 6. Invalid Argument (Math, numbers, bounds, currency validation)
  if (
    errName === 'InvalidMemberCountError' ||
    errName === 'InvalidPeriodicContributionError' ||
    errName === 'InvalidPositionNumberError' ||
    errName === 'InvalidPeriodNumberError' ||
    errName === 'InvalidCurrencyError' ||
    errName === 'OddEntitlementError' ||
    errName === 'MathValidationError' ||
    errName === 'SafeIntegerOverflowError' ||
    errName === 'FinancialValidationError' ||
    errName === 'PeriodProjectionMismatchError' ||
    errName === 'PeriodMathConservationError' ||
    message.includes('invalid') ||
    message.includes('must be') ||
    message.includes('odd entitlement') ||
    message.includes('safe integer')
  ) {
    return new HttpsError('invalid-argument', message);
  }

  // 7. Fallback: Internal
  return new HttpsError('internal', `Central Pool Error: ${message}`);
}
