/**
 * Central Pool Step 5: Confirmation Error Taxonomy
 * Strongly typed domain errors for allocation confirmation failures and concurrency collisions.
 */

import { CentralPoolDomainError, CandidateExpiredError } from '../domain';

export { CandidateExpiredError };

export class CandidateInvalidError extends CentralPoolDomainError {
  constructor(reason: string) {
    super(`Candidate validation failed: ${reason}`, 'CANDIDATE_INVALID');
  }
}

export class PositionAlreadyOccupiedError extends CentralPoolDomainError {
  constructor(unitId: string, positionNumber: number) {
    super(
      `Position ${positionNumber} in AllocationUnit '${unitId}' is already occupied`,
      'POSITION_ALREADY_OCCUPIED'
    );
  }
}

export class AllocationUnitNotFormingError extends CentralPoolDomainError {
  constructor(unitId: string, currentStatus: string) {
    super(
      `AllocationUnit '${unitId}' cannot accept confirmations in status '${currentStatus}' (only 'FORMING' allowed)`,
      'UNIT_NOT_FORMING'
    );
  }
}

export class AllocationUnitCapacityExceededError extends CentralPoolDomainError {
  constructor(unitId: string, occupiedCount: number, memberCount: number) {
    super(
      `AllocationUnit '${unitId}' capacity exceeded (${occupiedCount}/${memberCount})`,
      'UNIT_CAPACITY_EXCEEDED'
    );
  }
}

export class ParticipationRequestNotConfirmableError extends CentralPoolDomainError {
  constructor(requestId: string, currentStatus: string) {
    super(
      `ParticipationRequest '${requestId}' in status '${currentStatus}' cannot be confirmed`,
      'REQUEST_NOT_CONFIRMABLE'
    );
  }
}

export class TenantIsolationConfirmationError extends CentralPoolDomainError {
  constructor(expectedTenant: string, actualTenant: string, entityName: string) {
    super(
      `Tenant isolation violation in confirmation: expected '${expectedTenant}', got '${actualTenant}' for ${entityName}`,
      'TENANT_ISOLATION_VIOLATION'
    );
  }
}

export class MemberOwnershipConfirmationError extends CentralPoolDomainError {
  constructor(expectedUid: string, actualUid: string, entityName: string) {
    super(
      `Member ownership violation in confirmation: expected '${expectedUid}', got '${actualUid}' for ${entityName}`,
      'MEMBER_OWNERSHIP_VIOLATION'
    );
  }
}

export class ConfirmationRevalidationFailedError extends CentralPoolDomainError {
  constructor(reasons: string[]) {
    super(
      `Authoritative confirmation revalidation failed: ${reasons.join('; ')}`,
      'CONFIRMATION_REVALIDATION_FAILED'
    );
  }
}
