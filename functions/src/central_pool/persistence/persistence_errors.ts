/**
 * Central Pool Persistence Error Hierarchy
 * Strictly typed errors for tenant isolation, ownership, immutability, and document lifecycle.
 */

export class CentralPoolPersistenceError extends Error {
  public readonly code: string;

  constructor(message: string, code = 'PERSISTENCE_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class TenantIsolationViolationError extends CentralPoolPersistenceError {
  constructor(expectedTenantId: string, actualTenantId: string, entityType = 'Entity') {
    super(
      `Tenant isolation violation on ${entityType}: operation tenant '${expectedTenantId}' does not match entity tenant '${actualTenantId}'`,
      'TENANT_ISOLATION_VIOLATION'
    );
  }
}

export class MemberOwnershipViolationError extends CentralPoolPersistenceError {
  constructor(expectedMemberUid: string, actualMemberUid: string, entityType = 'Entity') {
    super(
      `Member ownership violation on ${entityType}: authenticated user '${expectedMemberUid}' does not own resource belonging to '${actualMemberUid}'`,
      'MEMBER_OWNERSHIP_VIOLATION'
    );
  }
}

export class ImmutableFieldMutationError extends CentralPoolPersistenceError {
  constructor(fieldName: string, entityType = 'Entity') {
    super(
      `Immutable field violation on ${entityType}: field '${fieldName}' cannot be modified once persisted`,
      'IMMUTABLE_FIELD_MUTATION'
    );
  }
}

export class EntityNotFoundError extends CentralPoolPersistenceError {
  constructor(entityType: string, entityId: string) {
    super(`${entityType} with ID '${entityId}' was not found in persistence`, 'ENTITY_NOT_FOUND');
  }
}

export class DuplicateEntityError extends CentralPoolPersistenceError {
  constructor(entityType: string, entityId: string) {
    super(`${entityType} with ID '${entityId}' already exists in persistence`, 'DUPLICATE_ENTITY');
  }
}

export class ConcurrencyConflictError extends CentralPoolPersistenceError {
  constructor(entityType: string, entityId: string, expectedVersion: number, actualVersion: number) {
    super(
      `Optimistic concurrency conflict on ${entityType} '${entityId}': expected version ${expectedVersion}, found ${actualVersion}`,
      'CONCURRENCY_CONFLICT'
    );
  }
}

export class InvalidPersistenceStateError extends CentralPoolPersistenceError {
  constructor(message: string) {
    super(`Invalid persistence state: ${message}`, 'INVALID_PERSISTENCE_STATE');
  }
}
