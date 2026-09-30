/**
 * Central Pool TypeScript Mathematical Kernel - Error Definitions
 * Reference: services/cooperative-service/allocation_mathematical_kernel.go
 */

export class CentralPoolMathError extends Error {
  public readonly code: string;

  constructor(message: string, code: string = 'MATH_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class InvalidMemberCountError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: member count N must be >= 2') {
    super(message, 'INVALID_MEMBER_COUNT');
  }
}

export class InvalidPeriodicContributionError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: periodic contribution must be positive and non-zero') {
    super(message, 'INVALID_PERIODIC_CONTRIBUTION');
  }
}

export class InvalidPositionNumberError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: position number must be between 1 and N') {
    super(message, 'INVALID_POSITION_NUMBER');
  }
}

export class InvalidPeriodNumberError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: period number must be between 1 and N') {
    super(message, 'INVALID_PERIOD_NUMBER');
  }
}

export class UnsupportedAllocationModeError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: unsupported allocation mode; only STANDARD_SPLIT and DEFERRED_FULL_ALLOCATION are permitted') {
    super(message, 'UNSUPPORTED_ALLOCATION_MODE');
  }
}

export class EntitlementMismatchError extends CentralPoolMathError {
  constructor(message: string = 'allocation invariant violation: sum of split disbursements does not equal total contractual entitlement') {
    super(message, 'ENTITLEMENT_MISMATCH');
  }
}

export class MirrorInvolutionError extends CentralPoolMathError {
  constructor(message: string = 'allocation invariant violation: mirror involution failed; Mirror(Mirror(P)) != P') {
    super(message, 'MIRROR_INVOLUTION_FAILED');
  }
}

export class NegativeAllocationAmountError extends CentralPoolMathError {
  constructor(message: string = 'allocation invariant violation: allocation amount cannot be negative') {
    super(message, 'NEGATIVE_ALLOCATION_AMOUNT');
  }
}

export class DuplicatePositionAssignmentError extends CentralPoolMathError {
  constructor(message: string = 'allocation invariant violation: duplicate position assignment detected in cycle roster') {
    super(message, 'DUPLICATE_POSITION_ASSIGNMENT');
  }
}

export class IncompleteRosterError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: all positions 1..N must be assigned prior to matrix generation') {
    super(message, 'INCOMPLETE_ROSTER');
  }
}

// Contract-level guardrail errors:

export class OddEntitlementRejectionError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: total entitlement E must be an even integer for 50/50 symmetrical disbursement') {
    super(message, 'ODD_ENTITLEMENT_REJECTED');
  }
}

export class SafeIntegerOverflowError extends CentralPoolMathError {
  constructor(message: string = 'allocation error: calculation exceeds maximum safe integer range (Number.MAX_SAFE_INTEGER)') {
    super(message, 'SAFE_INTEGER_OVERFLOW');
  }
}
