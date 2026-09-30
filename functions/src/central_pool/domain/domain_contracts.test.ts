/**
 * Central Pool Step 2: Domain Contracts & Transition Guard Test Suite
 * Reconciled against S2-01, S2-02, S2-03 micro-corrections.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  ConfirmedAllocation,
  validateParticipationRequest,
  validateAllocationUnit,
  validateAllocationPosition,
  validateAllocationCandidate,
  validateConfirmedAllocation,
  validateParticipationRequestStateTransition,
  validateAllocationUnitStateTransition,
  MissingTenantIdError,
  MissingMemberUidError,
  InvalidCurrencyError,
  InvalidAllocationRuleError,
  InvalidStateTransitionError,
  EntityValidationError,
  getParticipationRequestPath,
  getAllocationUnitPath,
  getPositionPath,
  getAllocationUnitIndexPath,
  getIdempotencyRecordPath,
  getAllocationReceiptPath,
} from './index';
import {
  calculateTotalEntitlement,
  calculateTotalPot,
} from '../math/allocation_math';
import {
  InvalidMemberCountError,
  InvalidPeriodicContributionError,
  InvalidPositionNumberError,
  InvalidPeriodNumberError,
} from '../math/math_errors';

describe('CENTRAL POOL — Step 2: Domain Entity Validation', () => {
  describe('1. ParticipationRequest Contract & Duration Bounds (S2-02)', () => {
    const validRequest: ParticipationRequest = {
      requestId: 'req_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice_123',
      contributionMinor: 50000,
      currency: 'USD',
      durationPeriods: 10,
      preferredPayoutPeriod: 5,
      status: 'SUBMITTED',
      clientSubmissionId: 'sub_uuid_1234',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      requestExpiresAt: '2026-09-15T12:00:00.000Z',
      version: 1,
    };

    it('validates a well-formed ParticipationRequest successfully', () => {
      assert.doesNotThrow(() => validateParticipationRequest(validRequest));
    });

    it('accepts minimum duration N = 2 (provenance: frozen Go ErrInvalidMemberCount for N < 2)', () => {
      assert.doesNotThrow(() =>
        validateParticipationRequest({ ...validRequest, durationPeriods: 2, preferredPayoutPeriod: 2 })
      );
    });

    it('accepts maximum duration N = 12 (provenance: ratified MAX_DURATION_PERIODS = 12)', () => {
      assert.doesNotThrow(() =>
        validateParticipationRequest({ ...validRequest, durationPeriods: 12, preferredPayoutPeriod: 12 })
      );
    });

    it('rejects duration below minimum N = 2 (N = 1 rejected)', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, durationPeriods: 1 }),
        (err: any) => err instanceof InvalidMemberCountError
      );
    });

    it('rejects duration above maximum N = 12 (N = 13 rejected)', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, durationPeriods: 13 }),
        (err: any) => err instanceof InvalidMemberCountError
      );
    });

    it('rejects missing or empty tenantId', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, tenantId: '' }),
        (err: any) => err instanceof MissingTenantIdError
      );
    });

    it('rejects missing or empty memberUid', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, memberUid: '' }),
        (err: any) => err instanceof MissingMemberUidError
      );
    });

    it('rejects invalid currency codes', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, currency: 'US' }),
        (err: any) => err instanceof InvalidCurrencyError
      );
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, currency: 'usd' }),
        (err: any) => err instanceof InvalidCurrencyError
      );
    });

    it('rejects zero or negative periodic contribution', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, contributionMinor: 0 }),
        (err: any) => err instanceof InvalidPeriodicContributionError
      );
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, contributionMinor: -500 }),
        (err: any) => err instanceof InvalidPeriodicContributionError
      );
    });

    it('rejects preferredPayoutPeriod out of range [1..N]', () => {
      assert.throws(
        () => validateParticipationRequest({ ...validRequest, preferredPayoutPeriod: 11 }),
        (err: any) => err instanceof InvalidPeriodNumberError
      );
    });
  });

  describe('2. AllocationUnit Contract & Invariants (S2-02)', () => {
    const validUnit: AllocationUnit = {
      unitId: 'unit_8f9c1a2b',
      tenantId: 'tenant_prod_01',
      compatibilityKey: 'cp_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      memberCount: 10,
      occupiedCount: 3,
      status: 'FORMING',
      contributionMinor: 50000,
      currency: 'USD',
      durationPeriods: 10,
      allocationRule: 'SYMMETRICAL_V1',
      createdAt: '2026-09-08T12:00:00.000Z',
      updatedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    };

    it('validates a well-formed AllocationUnit successfully', () => {
      assert.doesNotThrow(() => validateAllocationUnit(validUnit));
    });

    it('accepts minimum capacity N = 2 and maximum capacity N = 12', () => {
      assert.doesNotThrow(() =>
        validateAllocationUnit({ ...validUnit, memberCount: 2, durationPeriods: 2, occupiedCount: 1 })
      );
      assert.doesNotThrow(() =>
        validateAllocationUnit({ ...validUnit, memberCount: 12, durationPeriods: 12, occupiedCount: 1 })
      );
    });

    it('rejects capacity out of bounds [2..12]', () => {
      assert.throws(
        () => validateAllocationUnit({ ...validUnit, memberCount: 1, durationPeriods: 1 }),
        (err: any) => err instanceof InvalidMemberCountError
      );
      assert.throws(
        () => validateAllocationUnit({ ...validUnit, memberCount: 13, durationPeriods: 13 }),
        (err: any) => err instanceof InvalidMemberCountError
      );
    });

    it('rejects occupiedCount exceeding member capacity', () => {
      assert.throws(
        () => validateAllocationUnit({ ...validUnit, occupiedCount: 11 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('rejects COMMITTED_FULL when unit is not completely occupied', () => {
      assert.throws(
        () => validateAllocationUnit({ ...validUnit, status: 'COMMITTED_FULL', occupiedCount: 9 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('allows COMMITTED_FULL when occupiedCount exactly equals memberCount', () => {
      assert.doesNotThrow(() =>
        validateAllocationUnit({ ...validUnit, status: 'COMMITTED_FULL', occupiedCount: 10 })
      );
    });

    it('rejects unknown allocation rules', () => {
      assert.throws(
        () => validateAllocationUnit({ ...validUnit, allocationRule: 'RANDOM_V1' as any }),
        (err: any) => err instanceof InvalidAllocationRuleError
      );
    });
  });

  describe('3. AllocationPosition Contract (Authoritative Occupancy Truth - S2-03)', () => {
    const validPosition: AllocationPosition = {
      unitId: 'unit_8f9c1a2b',
      positionNumber: 3,
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice_123',
      requestId: 'req_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      payoutPeriod: 3,
      occupiedAt: '2026-09-08T12:05:00.000Z',
      version: 1,
    };

    it('validates a well-formed AllocationPosition', () => {
      assert.doesNotThrow(() => validateAllocationPosition(validPosition, 10));
    });

    it('rejects position number out of bounds [1..N]', () => {
      assert.throws(
        () => validateAllocationPosition({ ...validPosition, positionNumber: 0 }, 10),
        (err: any) => err instanceof InvalidPositionNumberError
      );
      assert.throws(
        () => validateAllocationPosition({ ...validPosition, positionNumber: 11 }, 10),
        (err: any) => err instanceof InvalidPositionNumberError
      );
    });

    it('rejects missing member ownership', () => {
      assert.throws(
        () => validateAllocationPosition({ ...validPosition, memberUid: '' }, 10),
        (err: any) => err instanceof MissingMemberUidError
      );
    });
  });

  describe('4. AllocationCandidate Contract & Math Kernel Delegation (S2-01)', () => {
    const validCandidate: AllocationCandidate = {
      candidateId: 'cand_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      requestId: 'req_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice_123',
      allocationUnitId: 'unit_8f9c1a2b',
      allocatedPosition: 3,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 10,
      totalEntitlementMinor: 500000, // E = N * C = 10 * 50000
      totalPotMinor: 5000000,        // TotalPot = N^2 * C = 100 * 50000
      currency: 'USD',
      allocationRule: 'SYMMETRICAL_V1',
      issuedAt: '2026-09-08T12:00:00.000Z',
      expiresAt: '2026-09-08T12:05:00.000Z',
      isProvisional: true,
    };

    it('validates a well-formed AllocationCandidate', () => {
      assert.doesNotThrow(() => validateAllocationCandidate(validCandidate));
    });

    it('explicitly proves TotalEntitlement (N * C) !== TotalPot (N^2 * C) for N=4, C=2', () => {
      const N = 4;
      const C = 2;
      const entitlement = calculateTotalEntitlement(C, N);
      const pot = calculateTotalPot(C, N);

      assert.equal(entitlement, 8, 'TotalEntitlement must equal N * C = 4 * 2 = 8');
      assert.equal(pot, 32, 'TotalPot must equal N^2 * C = 16 * 2 = 32');
      assert.notEqual(entitlement, pot, 'TotalEntitlement must NOT equal TotalPot');
    });

    it('rejects candidate with mismatched totalEntitlementMinor (N * C)', () => {
      assert.throws(
        () => validateAllocationCandidate({ ...validCandidate, totalEntitlementMinor: 499999 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('rejects candidate with mismatched totalPotMinor (N^2 * C)', () => {
      assert.throws(
        () => validateAllocationCandidate({ ...validCandidate, totalPotMinor: 4999999 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('rejects candidate without explicit provisional flag', () => {
      assert.throws(
        () => validateAllocationCandidate({ ...validCandidate, isProvisional: false as any }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('proves candidate TTL (300s) is distinct from Request TTL (7 days)', () => {
      const candidateExpiresAt = new Date(validCandidate.expiresAt).getTime();
      const candidateIssuedAt = new Date(validCandidate.issuedAt).getTime();
      const candidateTtlSeconds = (candidateExpiresAt - candidateIssuedAt) / 1000;
      assert.equal(candidateTtlSeconds, 300, 'Candidate TTL must be exactly 300 seconds');

      const requestCreatedAt = new Date('2026-09-08T12:00:00.000Z').getTime();
      const requestExpiresAt = new Date('2026-09-15T12:00:00.000Z').getTime();
      const requestTtlDays = (requestExpiresAt - requestCreatedAt) / (1000 * 60 * 60 * 24);
      assert.equal(requestTtlDays, 7, 'Request TTL must be 7 days');

      assert.ok(requestExpiresAt > candidateExpiresAt, 'Request TTL must far outlive candidate TTL');
    });
  });

  describe('5. ConfirmedAllocation Contract & Derived Projection Classification (S2-01, S2-03)', () => {
    const validConfirmed: ConfirmedAllocation = {
      allocationId: 'alloc_req_0123456789abcdef',
      requestId: 'req_0123456789abcdef',
      tenantId: 'tenant_prod_01',
      memberUid: 'usr_alice_123',
      allocationUnitId: 'unit_8f9c1a2b',
      allocatedPosition: 3,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 10,
      totalEntitlementMinor: 500000, // E = N * C = 10 * 50000
      totalPotMinor: 5000000,        // TotalPot = N^2 * C = 100 * 50000
      currency: 'USD',
      allocationRule: 'SYMMETRICAL_V1',
      confirmedAt: '2026-09-08T12:01:00.000Z',
      isProjection: true,
      classification: 'DERIVED_PROJECTION',
      version: 1,
    };

    it('validates a well-formed ConfirmedAllocation', () => {
      assert.doesNotThrow(() => validateConfirmedAllocation(validConfirmed));
    });

    it('rejects confirmed allocation without isProjection: true flag', () => {
      assert.throws(
        () => validateConfirmedAllocation({ ...validConfirmed, isProjection: false as any }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it("rejects confirmed allocation without classification: 'DERIVED_PROJECTION'", () => {
      assert.throws(
        () => validateConfirmedAllocation({ ...validConfirmed, classification: 'AUTHORITATIVE' as any }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('rejects confirmed allocation with mismatched totalEntitlementMinor', () => {
      assert.throws(
        () => validateConfirmedAllocation({ ...validConfirmed, totalEntitlementMinor: 499999 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('rejects confirmed allocation with mismatched totalPotMinor', () => {
      assert.throws(
        () => validateConfirmedAllocation({ ...validConfirmed, totalPotMinor: 4999999 }),
        (err: any) => err instanceof EntityValidationError
      );
    });

    it('proves ConfirmedAllocation path is a member receipt projection distinct from authoritative position path', () => {
      const receiptPath = getAllocationReceiptPath('usr_alice_123', validConfirmed.allocationId);
      const positionPath = getPositionPath(validConfirmed.allocationUnitId, validConfirmed.allocatedPosition);

      assert.equal(receiptPath, 'users/usr_alice_123/allocations/alloc_req_0123456789abcdef');
      assert.equal(positionPath, 'allocation_units/unit_8f9c1a2b/positions/3');
      assert.notEqual(receiptPath, positionPath, 'Receipt projection path must be distinct from authoritative position path');
    });
  });
});

describe('CENTRAL POOL — Step 2: State Machine Transition Guard', () => {
  describe('1. ParticipationRequest Legal Transitions', () => {
    it('allows legal forward lifecycle transitions', () => {
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('DRAFT', 'SUBMITTED'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('SUBMITTED', 'AWAITING_SELECTION'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('AWAITING_SELECTION', 'REVALIDATING'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('REVALIDATING', 'CONFIRMED'));
    });

    it('allows legal failure and recovery transitions', () => {
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('SUBMITTED', 'NO_MATCH'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('SUBMITTED', 'CANCELLED'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('SUBMITTED', 'EXPIRED'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('REVALIDATING', 'REVALIDATION_FAILED'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('REVALIDATION_FAILED', 'AWAITING_SELECTION'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('REVALIDATION_FAILED', 'CANCELLED'));
    });

    it('allows rematching from AWAITING_SELECTION', () => {
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('AWAITING_SELECTION', 'AWAITING_SELECTION'));
    });
  });

  describe('2. ParticipationRequest Prohibited Transitions & State Nomenclature (F6-BLOCKER-02)', () => {
    it('prohibits mutating CONFIRMED to REVALIDATION_FAILED (Terminal State Protection)', () => {
      assert.throws(
        () => validateParticipationRequestStateTransition('CONFIRMED', 'REVALIDATION_FAILED'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });

    it('prohibits mutating EXPIRED or CANCELLED into active states', () => {
      assert.throws(
        () => validateParticipationRequestStateTransition('EXPIRED', 'AWAITING_SELECTION'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
      assert.throws(
        () => validateParticipationRequestStateTransition('CANCELLED', 'REVALIDATING'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });

    it('strictly prohibits direct transition SUBMITTED -> CONFIRMED (skipping revalidation)', () => {
      assert.throws(
        () => validateParticipationRequestStateTransition('SUBMITTED', 'CONFIRMED'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });

    it('strictly proves AWAITING_SELECTION -> REVALIDATING -> CONFIRMED is the authoritative confirmation path', () => {
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('AWAITING_SELECTION', 'REVALIDATING'));
      assert.doesNotThrow(() => validateParticipationRequestStateTransition('REVALIDATING', 'CONFIRMED'));
    });

    it('strictly rejects unratified states SELECTING and MATCHED_PROVISIONAL', () => {
      assert.throws(
        () => validateParticipationRequestStateTransition('SUBMITTED', 'SELECTING' as any),
        (err: any) => err instanceof InvalidStateTransitionError
      );
      assert.throws(
        () => validateParticipationRequestStateTransition('SELECTING' as any, 'CONFIRMED'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
      assert.throws(
        () => validateParticipationRequestStateTransition('SUBMITTED', 'MATCHED_PROVISIONAL' as any),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });
  });


  describe('3. AllocationUnit Formation Transitions', () => {
    it('allows FORMING -> COMMITTED_FULL', () => {
      assert.doesNotThrow(() => validateAllocationUnitStateTransition('FORMING', 'COMMITTED_FULL'));
    });

    it('allows FORMING -> DEFECT_QUARANTINE and COMMITTED_FULL -> DEFECT_QUARANTINE', () => {
      assert.doesNotThrow(() => validateAllocationUnitStateTransition('FORMING', 'DEFECT_QUARANTINE'));
      assert.doesNotThrow(() => validateAllocationUnitStateTransition('COMMITTED_FULL', 'DEFECT_QUARANTINE'));
    });

    it('prohibits reopening COMMITTED_FULL to FORMING (Terminal Formation State)', () => {
      assert.throws(
        () => validateAllocationUnitStateTransition('COMMITTED_FULL', 'FORMING'),
        (err: any) => err instanceof InvalidStateTransitionError
      );
    });
  });
});

describe('CENTRAL POOL — Step 2: Firestore Path Contracts', () => {
  it('generates exact canonical document paths', () => {
    assert.equal(getParticipationRequestPath('req_123'), 'participation_requests/req_123');
    assert.equal(getAllocationUnitPath('unit_abc'), 'allocation_units/unit_abc');
    assert.equal(getPositionPath('unit_abc', 3), 'allocation_units/unit_abc/positions/3');
    assert.equal(getAllocationUnitIndexPath('cp_xyz'), 'allocation_unit_indexes/cp_xyz');
    assert.equal(getIdempotencyRecordPath('idemp_99'), 'idempotency_records/idemp_99');
    assert.equal(getAllocationReceiptPath('usr_1', 'alloc_req_1'), 'users/usr_1/allocations/alloc_req_1');
  });
});
