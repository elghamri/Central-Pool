/**
 * Central Pool Domain Error Hierarchy
 * Distinct from mathematical errors and application-level transport errors.
 */

export class CentralPoolDomainError extends Error {
  public readonly code: string;

  constructor(message: string, code = 'DOMAIN_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class InvalidStateTransitionError extends CentralPoolDomainError {
  constructor(fromState: string, toState: string, entityType: string) {
    super(
      `Invalid state transition for ${entityType}: cannot transition from '${fromState}' to '${toState}'`,
      'INVALID_STATE_TRANSITION'
    );
  }
}

export class MissingTenantIdError extends CentralPoolDomainError {
  constructor(entityName = 'Entity') {
    super(`${entityName} must carry an explicit, non-empty tenantId`, 'MISSING_TENANT_ID');
  }
}

export class MissingMemberUidError extends CentralPoolDomainError {
  constructor(entityName = 'Entity') {
    super(`${entityName} must carry an explicit, non-empty memberUid`, 'MISSING_MEMBER_UID');
  }
}

export class InvalidCurrencyError extends CentralPoolDomainError {
  constructor(currency: string) {
    super(`Invalid currency: '${currency}'. Must be a 3-letter uppercase ISO 4217 code`, 'INVALID_CURRENCY');
  }
}

export class InvalidAllocationRuleError extends CentralPoolDomainError {
  constructor(rule: string) {
    super(`Invalid allocation rule: '${rule}'. Approved rule is 'SYMMETRICAL_V1'`, 'INVALID_ALLOCATION_RULE');
  }
}

export class InvalidPositionIdentityError extends CentralPoolDomainError {
  constructor(message: string) {
    super(message, 'INVALID_POSITION_IDENTITY');
  }
}

export class CandidateExpiredError extends CentralPoolDomainError {
  constructor(candidateId: string, expiredAt: string) {
    super(`Candidate '${candidateId}' expired at ${expiredAt} and cannot be confirmed`, 'CANDIDATE_EXPIRED');
  }
}

export class EntityValidationError extends CentralPoolDomainError {
  constructor(message: string) {
    super(`Entity validation failed: ${message}`, 'ENTITY_VALIDATION_ERROR');
  }
}
