/**
 * Central Pool DTO Converters
 * Explicit, type-safe serialization boundaries between Domain Entities and Firestore Document Schemas.
 * Guarantees zero unchecked type casting, strict validation on read/write, and safe-integer preservation.
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  ConfirmedAllocation,
  IdempotencyRecord,
  PERSISTED_PARTICIPATION_REQUEST_STATES,
  PersistedParticipationRequestState,
  validateParticipationRequest,
  validateAllocationUnit,
  validateAllocationPosition,
  validateAllocationCandidate,
  validateConfirmedAllocation,
} from '../../domain';
import { InvalidPersistenceStateError } from '../persistence_errors';
import { ParticipationRequestDoc } from './participation_request_dto';
import { AllocationUnitDoc } from './allocation_unit_dto';
import { AllocationPositionDoc } from './allocation_position_dto';
import { AllocationCandidateDoc } from './allocation_candidate_dto';
import { ConfirmedAllocationDoc } from './confirmed_allocation_dto';
import { IdempotencyRecordDoc } from './idempotency_record_dto';

/**
 * Converts a Date, ISO 8601 string, or Firestore Timestamp to an ISO 8601 UTC string.
 */
export function timestampToIsoString(value: unknown, fieldName: string): string {
  if (value instanceof Timestamp) {
    return value.toDate().toISOString();
  }
  if (value && typeof (value as any).toDate === 'function') {
    return (value as any).toDate().toISOString();
  }
  if (value && typeof (value as any)._seconds === 'number') {
    const millis = (value as any)._seconds * 1000 + Math.floor(((value as any)._nanoseconds || 0) / 1e6);
    return new Date(millis).toISOString();
  }
  if (value && typeof (value as any).seconds === 'number') {
    const millis = (value as any).seconds * 1000 + Math.floor(((value as any).nanoseconds || 0) / 1e6);
    return new Date(millis).toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const d = new Date(value);
    if (!isNaN(d.getTime())) {
      return d.toISOString();
    }
  }
  throw new InvalidPersistenceStateError(`Expected valid Timestamp for field '${fieldName}', got ${typeof value}`);
}

/**
 * Converts an ISO 8601 string or Date to a Firestore Timestamp.
 */
export function isoStringToTimestamp(value: string | undefined, fieldName: string): Timestamp {
  if (!value || typeof value !== 'string') {
    throw new InvalidPersistenceStateError(`Field '${fieldName}' must be a non-empty ISO date string`);
  }
  const d = new Date(value);
  if (isNaN(d.getTime())) {
    throw new InvalidPersistenceStateError(`Field '${fieldName}' contains invalid date string: '${value}'`);
  }
  return Timestamp.fromDate(d);
}

// =============================================================================
// 1. PARTICIPATION REQUEST CONVERTERS
// =============================================================================

export function participationRequestToDoc(
  req: ParticipationRequest,
  useServerTimestamps = false
): ParticipationRequestDoc {
  // Pre-serialization domain validation
  validateParticipationRequest(req);

  // Persistence rule: DRAFT, ANALYZING, MATCHED must not be persisted
  if (!PERSISTED_PARTICIPATION_REQUEST_STATES.has(req.status as PersistedParticipationRequestState)) {
    throw new InvalidPersistenceStateError(
      `State '${req.status}' is not a permitted persisted Firestore state for ParticipationRequest`
    );
  }

  const doc: ParticipationRequestDoc = {
    requestId: req.requestId,
    tenantId: req.tenantId,
    memberUid: req.memberUid,
    contributionMinor: req.contributionMinor,
    currency: req.currency,
    durationPeriods: req.durationPeriods,
    status: req.status as PersistedParticipationRequestState,
    clientSubmissionId: req.clientSubmissionId,
    createdAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(req.createdAt, 'createdAt'),
    updatedAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(req.updatedAt, 'updatedAt'),
    requestExpiresAt: isoStringToTimestamp(req.requestExpiresAt, 'requestExpiresAt'),
    version: req.version ?? 1,
  };

  if (req.preferredPayoutPeriod !== undefined) {
    doc.preferredPayoutPeriod = req.preferredPayoutPeriod;
  }
  if (req.allocationUnitId !== undefined) {
    doc.allocationUnitId = req.allocationUnitId;
  }
  if (req.allocatedPosition !== undefined) {
    doc.allocatedPosition = req.allocatedPosition;
  }
  if (req.payoutPeriod !== undefined) {
    doc.payoutPeriod = req.payoutPeriod;
  }
  if (req.confirmedAt !== undefined) {
    doc.confirmedAt = isoStringToTimestamp(req.confirmedAt, 'confirmedAt');
  }
  if (req.revalidationFailureReason !== undefined) {
    doc.revalidationFailureReason = req.revalidationFailureReason;
  }

  return doc;
}

export function docToParticipationRequest(data: Record<string, unknown>): ParticipationRequest {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('ParticipationRequest document data must be a non-null object');
  }

  const req: ParticipationRequest = {
    requestId: String(data.requestId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    memberUid: String(data.memberUid ?? ''),
    contributionMinor: Number(data.contributionMinor),
    currency: String(data.currency ?? ''),
    durationPeriods: Number(data.durationPeriods),
    status: data.status as any,
    clientSubmissionId: String(data.clientSubmissionId ?? ''),
    createdAt: timestampToIsoString(data.createdAt, 'createdAt'),
    updatedAt: timestampToIsoString(data.updatedAt, 'updatedAt'),
    requestExpiresAt: timestampToIsoString(data.requestExpiresAt, 'requestExpiresAt'),
    version: Number(data.version ?? 1),
  };

  if (data.preferredPayoutPeriod !== undefined && data.preferredPayoutPeriod !== null) {
    req.preferredPayoutPeriod = Number(data.preferredPayoutPeriod);
  }
  if (data.allocationUnitId !== undefined && data.allocationUnitId !== null) {
    req.allocationUnitId = String(data.allocationUnitId);
  }
  if (data.allocatedPosition !== undefined && data.allocatedPosition !== null) {
    req.allocatedPosition = Number(data.allocatedPosition);
  }
  if (data.payoutPeriod !== undefined && data.payoutPeriod !== null) {
    req.payoutPeriod = Number(data.payoutPeriod);
  }
  if (data.confirmedAt !== undefined && data.confirmedAt !== null) {
    req.confirmedAt = timestampToIsoString(data.confirmedAt, 'confirmedAt');
  }
  if (data.revalidationFailureReason !== undefined && data.revalidationFailureReason !== null) {
    req.revalidationFailureReason = String(data.revalidationFailureReason);
  }

  // Post-deserialization domain validation
  validateParticipationRequest(req);
  return req;
}

// =============================================================================
// 2. ALLOCATION UNIT CONVERTERS
// =============================================================================

export function allocationUnitToDoc(unit: AllocationUnit, useServerTimestamps = false): AllocationUnitDoc {
  validateAllocationUnit(unit);

  return {
    unitId: unit.unitId,
    tenantId: unit.tenantId,
    compatibilityKey: unit.compatibilityKey,
    memberCount: unit.memberCount,
    occupiedCount: unit.occupiedCount,
    status: unit.status,
    contributionMinor: unit.contributionMinor,
    currency: unit.currency,
    durationPeriods: unit.durationPeriods,
    allocationRule: unit.allocationRule,
    createdAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(unit.createdAt, 'createdAt'),
    updatedAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(unit.updatedAt, 'updatedAt'),
    version: unit.version ?? 1,
  };
}

export function docToAllocationUnit(data: Record<string, unknown>): AllocationUnit {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('AllocationUnit document data must be a non-null object');
  }

  const unit: AllocationUnit = {
    unitId: String(data.unitId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    compatibilityKey: String(data.compatibilityKey ?? ''),
    memberCount: Number(data.memberCount),
    occupiedCount: Number(data.occupiedCount),
    status: data.status as any,
    contributionMinor: Number(data.contributionMinor),
    currency: String(data.currency ?? ''),
    durationPeriods: Number(data.durationPeriods),
    allocationRule: data.allocationRule as any,
    createdAt: timestampToIsoString(data.createdAt, 'createdAt'),
    updatedAt: timestampToIsoString(data.updatedAt, 'updatedAt'),
    version: Number(data.version ?? 1),
  };

  validateAllocationUnit(unit);
  return unit;
}

// =============================================================================
// 3. ALLOCATION POSITION CONVERTERS
// =============================================================================

export function allocationPositionToDoc(
  pos: AllocationPosition,
  memberCount: number,
  useServerTimestamps = false
): AllocationPositionDoc {
  validateAllocationPosition(pos, memberCount);

  return {
    unitId: pos.unitId,
    positionNumber: pos.positionNumber,
    tenantId: pos.tenantId,
    memberUid: pos.memberUid,
    requestId: pos.requestId,
    payoutPeriod: pos.payoutPeriod,
    occupiedAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(pos.occupiedAt, 'occupiedAt'),
    version: pos.version ?? 1,
  };
}

export function docToAllocationPosition(data: Record<string, unknown>, memberCount: number): AllocationPosition {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('AllocationPosition document data must be a non-null object');
  }

  const pos: AllocationPosition = {
    unitId: String(data.unitId ?? ''),
    positionNumber: Number(data.positionNumber),
    tenantId: String(data.tenantId ?? ''),
    memberUid: String(data.memberUid ?? ''),
    requestId: String(data.requestId ?? ''),
    payoutPeriod: Number(data.payoutPeriod),
    occupiedAt: timestampToIsoString(data.occupiedAt, 'occupiedAt'),
    version: Number(data.version ?? 1),
  };

  validateAllocationPosition(pos, memberCount);
  return pos;
}

// =============================================================================
// 4. ALLOCATION CANDIDATE CONVERTERS
// =============================================================================

export function allocationCandidateToDoc(cand: AllocationCandidate, useServerTimestamps = false): AllocationCandidateDoc {
  validateAllocationCandidate(cand);

  const doc: AllocationCandidateDoc = {
    candidateId: cand.candidateId,
    requestId: cand.requestId,
    tenantId: cand.tenantId,
    memberUid: cand.memberUid,
    allocationUnitId: cand.allocationUnitId,
    allocatedPosition: cand.allocatedPosition,
    payoutPeriod: cand.payoutPeriod,
    contributionMinor: cand.contributionMinor,
    durationPeriods: cand.durationPeriods,
    totalEntitlementMinor: cand.totalEntitlementMinor,
    totalPotMinor: cand.totalPotMinor,
    currency: cand.currency,
    allocationRule: cand.allocationRule,
    issuedAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(cand.issuedAt, 'issuedAt'),
    expiresAt: isoStringToTimestamp(cand.expiresAt, 'expiresAt'),
    isProvisional: true,
  };

  if (cand.signature !== undefined) {
    doc.signature = cand.signature;
  }

  return doc;
}

export function docToAllocationCandidate(data: Record<string, unknown>): AllocationCandidate {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('AllocationCandidate document data must be a non-null object');
  }

  const cand: AllocationCandidate = {
    candidateId: String(data.candidateId ?? ''),
    requestId: String(data.requestId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    memberUid: String(data.memberUid ?? ''),
    allocationUnitId: String(data.allocationUnitId ?? ''),
    allocatedPosition: Number(data.allocatedPosition),
    payoutPeriod: Number(data.payoutPeriod),
    contributionMinor: Number(data.contributionMinor),
    durationPeriods: Number(data.durationPeriods),
    totalEntitlementMinor: Number(data.totalEntitlementMinor),
    totalPotMinor: Number(data.totalPotMinor),
    currency: String(data.currency ?? ''),
    allocationRule: data.allocationRule as any,
    issuedAt: timestampToIsoString(data.issuedAt, 'issuedAt'),
    expiresAt: timestampToIsoString(data.expiresAt, 'expiresAt'),
    isProvisional: true,
  };

  if (data.signature !== undefined && data.signature !== null) {
    cand.signature = String(data.signature);
  }

  validateAllocationCandidate(cand);
  return cand;
}

// =============================================================================
// 5. CONFIRMED ALLOCATION (PROJECTION) CONVERTERS
// =============================================================================

export function confirmedAllocationToDoc(alloc: ConfirmedAllocation, useServerTimestamps = false): ConfirmedAllocationDoc {
  validateConfirmedAllocation(alloc);

  return {
    allocationId: alloc.allocationId,
    requestId: alloc.requestId,
    tenantId: alloc.tenantId,
    memberUid: alloc.memberUid,
    allocationUnitId: alloc.allocationUnitId,
    allocatedPosition: alloc.allocatedPosition,
    payoutPeriod: alloc.payoutPeriod,
    contributionMinor: alloc.contributionMinor,
    durationPeriods: alloc.durationPeriods,
    totalEntitlementMinor: alloc.totalEntitlementMinor,
    totalPotMinor: alloc.totalPotMinor,
    currency: alloc.currency,
    allocationRule: alloc.allocationRule,
    confirmedAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(alloc.confirmedAt, 'confirmedAt'),
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    version: alloc.version ?? 1,
  };
}

export function docToConfirmedAllocation(data: Record<string, unknown>): ConfirmedAllocation {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('ConfirmedAllocation document data must be a non-null object');
  }

  const alloc: ConfirmedAllocation = {
    allocationId: String(data.allocationId ?? ''),
    requestId: String(data.requestId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    memberUid: String(data.memberUid ?? ''),
    allocationUnitId: String(data.allocationUnitId ?? ''),
    allocatedPosition: Number(data.allocatedPosition),
    payoutPeriod: Number(data.payoutPeriod),
    contributionMinor: Number(data.contributionMinor),
    durationPeriods: Number(data.durationPeriods),
    totalEntitlementMinor: Number(data.totalEntitlementMinor),
    totalPotMinor: Number(data.totalPotMinor),
    currency: String(data.currency ?? ''),
    allocationRule: data.allocationRule as any,
    confirmedAt: timestampToIsoString(data.confirmedAt, 'confirmedAt'),
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    version: Number(data.version ?? 1),
  };

  validateConfirmedAllocation(alloc);
  return alloc;
}

// =============================================================================
// 6. IDEMPOTENCY RECORD CONVERTERS
// =============================================================================

export function idempotencyRecordToDoc(record: IdempotencyRecord, useServerTimestamps = false): IdempotencyRecordDoc {
  if (!record.idempotencyId || typeof record.idempotencyId !== 'string' || record.idempotencyId.trim() === '') {
    throw new InvalidPersistenceStateError('IdempotencyRecord must carry a non-empty idempotencyId');
  }
  if (!record.tenantId || typeof record.tenantId !== 'string' || record.tenantId.trim() === '') {
    throw new InvalidPersistenceStateError('IdempotencyRecord must carry a non-empty tenantId');
  }
  if (!record.memberUid || typeof record.memberUid !== 'string' || record.memberUid.trim() === '') {
    throw new InvalidPersistenceStateError('IdempotencyRecord must carry a non-empty memberUid');
  }
  if (!record.clientKey || typeof record.clientKey !== 'string' || record.clientKey.trim() === '') {
    throw new InvalidPersistenceStateError('IdempotencyRecord must carry a non-empty clientKey');
  }
  if (!record.operation || typeof record.operation !== 'string' || record.operation.trim() === '') {
    throw new InvalidPersistenceStateError('IdempotencyRecord must carry a non-empty operation');
  }
  if (!['PENDING', 'COMPLETED', 'FAILED'].includes(record.status)) {
    throw new InvalidPersistenceStateError(`IdempotencyRecord has invalid status '${record.status}'`);
  }

  const doc: IdempotencyRecordDoc = {
    idempotencyId: record.idempotencyId,
    tenantId: record.tenantId,
    memberUid: record.memberUid,
    clientKey: record.clientKey,
    operation: record.operation,
    status: record.status,
    createdAt: useServerTimestamps ? FieldValue.serverTimestamp() : isoStringToTimestamp(record.createdAt, 'createdAt'),
    expiresAt: isoStringToTimestamp(record.expiresAt, 'expiresAt'),
    version: record.version ?? 1,
  };

  if (record.responsePayload !== undefined) {
    doc.responsePayload = record.responsePayload;
  }
  if (record.errorDetail !== undefined) {
    doc.errorDetail = record.errorDetail;
  }

  return doc;
}

export function docToIdempotencyRecord(data: Record<string, unknown>): IdempotencyRecord {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('IdempotencyRecord document data must be a non-null object');
  }

  const record: IdempotencyRecord = {
    idempotencyId: String(data.idempotencyId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    memberUid: String(data.memberUid ?? ''),
    clientKey: String(data.clientKey ?? ''),
    operation: String(data.operation ?? ''),
    status: data.status as any,
    createdAt: timestampToIsoString(data.createdAt, 'createdAt'),
    expiresAt: timestampToIsoString(data.expiresAt, 'expiresAt'),
    version: Number(data.version ?? 1),
  };

  if (data.responsePayload !== undefined && data.responsePayload !== null && typeof data.responsePayload === 'object') {
    record.responsePayload = data.responsePayload as Record<string, unknown>;
  }
  if (data.errorDetail !== undefined && data.errorDetail !== null) {
    record.errorDetail = String(data.errorDetail);
  }

  if (!record.idempotencyId || !record.tenantId || !record.memberUid || !record.clientKey || !record.operation) {
    throw new InvalidPersistenceStateError('IdempotencyRecord document missing required fields');
  }

  return record;
}
