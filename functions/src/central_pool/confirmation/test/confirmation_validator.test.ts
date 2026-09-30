/**
 * Central Pool Step 5: Pure Authoritative Confirmation Validator Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationCandidate,
  CandidateExpiredError,
} from '../../domain';
import { computeCandidateId, computeCompatibilityKey } from '../../matching/compatibility_key';
import { validateConfirmationInvariants } from '../confirmation_validator';
import { AllocationConfirmationInput } from '../confirmation_types';
import {
  CandidateInvalidError,
  AllocationUnitNotFormingError,
  AllocationUnitCapacityExceededError,
  ParticipationRequestNotConfirmableError,
  TenantIsolationConfirmationError,
  MemberOwnershipConfirmationError,
} from '../confirmation_errors';

describe('CENTRAL POOL — Step 5: Pure Authoritative Confirmation Validator', () => {
  const tenantId = 'tenant_prod_01';
  const memberUid = 'usr_alice';
  const requestId = 'req_001';
  const unitId = 'unit_alpha';
  const currentTime = '2026-09-09T12:00:00.000Z';
  const currentTimeMs = new Date(currentTime).getTime();

  const compatibilityKey = computeCompatibilityKey({
    tenantId,
    currency: 'USD',
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const validRequest: ParticipationRequest = {
    requestId,
    tenantId,
    memberUid,
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 2,
    status: 'AWAITING_SELECTION',
    clientSubmissionId: 'sub_123',
    createdAt: '2026-09-09T11:55:00.000Z',
    updatedAt: '2026-09-09T11:55:00.000Z',
    requestExpiresAt: '2026-09-16T11:55:00.000Z',
    version: 1,
  };

  const validUnit: AllocationUnit = {
    unitId,
    tenantId,
    compatibilityKey,
    memberCount: 6,
    occupiedCount: 2,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-09T11:00:00.000Z',
    updatedAt: '2026-09-09T11:00:00.000Z',
    version: 1,
  };

  // Position 3 in N=6 maps to primary payout period 2
  const candidateId = computeCandidateId({
    tenantId,
    requestId,
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const validCandidate: AllocationCandidate = {
    candidateId,
    requestId,
    tenantId,
    memberUid,
    allocationUnitId: unitId,
    allocatedPosition: 3,
    payoutPeriod: 2,
    contributionMinor: 50000,
    durationPeriods: 6,
    totalEntitlementMinor: 300000,
    totalPotMinor: 1800000,
    currency: 'USD',
    allocationRule: 'SYMMETRICAL_V1',
    issuedAt: '2026-09-09T11:58:00.000Z',
    expiresAt: '2026-09-09T12:03:00.000Z', // 3 minutes ahead of currentTime
    isProvisional: true,
  };

  const validInput: AllocationConfirmationInput = {
    tenantId,
    memberUid,
    requestId,
    candidateId,
    idempotencyKey: 'idemp_key_123',
    evaluationTimestamp: currentTime,
  };

  it('accepts completely valid confirmation context and invariants', () => {
    assert.doesNotThrow(() => {
      validateConfirmationInvariants(validInput, validRequest, validCandidate, validUnit, currentTimeMs);
    });
  });

  it('rejects caller tenant mismatch against request, candidate, or unit', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          { ...validInput, tenantId: 'tenant_other' },
          validRequest,
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof TenantIsolationConfirmationError
    );

    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          { ...validRequest, tenantId: 'tenant_other' },
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof TenantIsolationConfirmationError
    );
  });

  it('rejects caller memberUid mismatch against request or candidate', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          { ...validInput, memberUid: 'usr_imposter' },
          validRequest,
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof MemberOwnershipConfirmationError
    );
  });

  it('rejects candidate token bound to a different request or unit', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          { ...validCandidate, requestId: 'req_other' },
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof CandidateInvalidError
    );

    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          { ...validCandidate, allocationUnitId: 'unit_other' },
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof CandidateInvalidError
    );
  });

  it('rejects candidate token tampering (computed hash mismatch)', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          { ...validCandidate, candidateId: 'cand_tampered_hash_value' },
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof CandidateInvalidError
    );
  });

  it('rejects expired candidate tokens', () => {
    // Current time is 12:00:00; candidate expired at 11:59:00
    const expiredCandidate: AllocationCandidate = {
      ...validCandidate,
      expiresAt: '2026-09-09T11:59:00.000Z',
    };

    assert.throws(
      () =>
        validateConfirmationInvariants(validInput, validRequest, expiredCandidate, validUnit, currentTimeMs),
      (err: any) => err instanceof CandidateExpiredError
    );
  });

  it('accepts REVALIDATING state as a valid predecessor state', () => {
    assert.doesNotThrow(() => {
      validateConfirmationInvariants(
        validInput,
        { ...validRequest, status: 'REVALIDATING' },
        validCandidate,
        validUnit,
        currentTimeMs
      );
    });
  });

  it('rejects non-confirmable request states (SUBMITTED, CONFIRMED, CANCELLED, EXPIRED)', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          { ...validRequest, status: 'SUBMITTED' },
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof ParticipationRequestNotConfirmableError
    );

    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          { ...validRequest, status: 'CONFIRMED' },
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof ParticipationRequestNotConfirmableError
    );

    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          { ...validRequest, status: 'CANCELLED' },
          validCandidate,
          validUnit,
          currentTimeMs
        ),
      (err: any) => err instanceof ParticipationRequestNotConfirmableError
    );
  });

  it('rejects units in COMMITTED_FULL or DEFECT_QUARANTINE status', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          validCandidate,
          { ...validUnit, status: 'COMMITTED_FULL', occupiedCount: 6 },
          currentTimeMs
        ),
      (err: any) => err instanceof AllocationUnitNotFormingError
    );

    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          validCandidate,
          { ...validUnit, status: 'DEFECT_QUARANTINE' },
          currentTimeMs
        ),
      (err: any) => err instanceof AllocationUnitNotFormingError
    );
  });

  it('rejects units that have reached full member capacity', () => {
    assert.throws(
      () =>
        validateConfirmationInvariants(
          validInput,
          validRequest,
          validCandidate,
          { ...validUnit, occupiedCount: 6 }, // 6/6 capacity reached
          currentTimeMs
        ),
      (err: any) => err instanceof AllocationUnitCapacityExceededError
    );
  });

  it('rejects position mapping that violates mathematical primary period formula', () => {
    // For N=6, pos 1 maps to P1=1. Candidate claiming payoutPeriod=2 for pos 1 is mathematically corrupted
    const corruptedCandidateId = computeCandidateId({
      tenantId,
      requestId,
      allocationUnitId: unitId,
      allocatedPosition: 1,
      payoutPeriod: 2, // WRONG: pos 1 in N=6 maps to period 1
      contributionMinor: 50000,
      durationPeriods: 6,
      allocationRule: 'SYMMETRICAL_V1',
    });

    const corruptedCandidate: AllocationCandidate = {
      ...validCandidate,
      candidateId: corruptedCandidateId,
      allocatedPosition: 1,
      payoutPeriod: 2,
    };

    assert.throws(
      () =>
        validateConfirmationInvariants(validInput, validRequest, corruptedCandidate, validUnit, currentTimeMs),
      (err: any) => err instanceof CandidateInvalidError
    );
  });
});
