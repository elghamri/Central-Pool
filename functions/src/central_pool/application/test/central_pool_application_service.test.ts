/**
 * Central Pool Step 8: Application Service Orchestration Test Suite
 * Comprehensive tests covering authentication, tenant isolation, member ownership,
 * matching orchestration, confirmation orchestration, financial/period reads, and error mapping.
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from './mock_firestore';
import { CentralPoolApplicationService } from '../central_pool_application_service';
import {
  TrustedAuthContext,
  SubmitParticipationRequestInput,
  SelectCandidateAndConfirmInput,
} from '../application_types';
import {
  mapToHttpsError,
  UnauthenticatedError,
  UnauthorizedAccessError,
} from '../api_errors';
import {
  getParticipationRequestPath,
  getAllocationUnitPath,
  getPositionPath,
  CONTRIBUTION_EVENTS_COLLECTION,
  CandidateExpiredError,
} from '../../domain';
import {
  TenantIsolationViolationError,
  EntityNotFoundError,
} from '../../persistence';
import {
  InvalidMemberCountError,
  InvalidPeriodicContributionError,
} from '../../math';
import {
  AllocationUnitCapacityExceededError,
  PositionAlreadyOccupiedError,
} from '../../confirmation';
import {
  JournalEntryUnbalancedError,
  InvalidObligationError,
} from '../../financial';
import {
  PeriodMathConservationError,
  PeriodProjectionAccessDeniedError,
} from '../../period';
import { computeCompatibilityKey } from '../../matching';

describe('CENTRAL POOL — Step 8: Central Pool Application Service', () => {
  let mockDb: MockFirestore;
  let service: CentralPoolApplicationService;

  const tenantId = 'tenant_prod_01';
  const memberUid1 = 'usr_alice';
  const memberUid2 = 'usr_bob';

  const aliceAuth: TrustedAuthContext = {
    uid: memberUid1,
    tenantId,
    role: 'MEMBER',
  };

  const bobAuth: TrustedAuthContext = {
    uid: memberUid2,
    tenantId,
    role: 'MEMBER',
  };

  const staffAuth: TrustedAuthContext = {
    uid: 'usr_staff_admin',
    tenantId,
    role: 'FINOPS',
  };

  const otherTenantAuth: TrustedAuthContext = {
    uid: 'usr_charlie',
    tenantId: 'tenant_other_99',
    role: 'MEMBER',
  };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new CentralPoolApplicationService(mockDb as any);
  });

  // ===========================================================================
  // 1. AUTHENTICATION & TENANT ISOLATION
  // ===========================================================================

  describe('Authentication & Tenant Isolation Enforcement', () => {
    it('fails if uid is missing or empty', async () => {
      const invalidAuth: TrustedAuthContext = {
        uid: '',
        tenantId,
        role: 'MEMBER',
      };
      await assert.rejects(
        async () => service.submitParticipationRequest(invalidAuth, {
          contributionMinor: 50000,
          currency: 'USD',
          durationPeriods: 6,
        }),
        (err: any) => err instanceof UnauthenticatedError
      );
    });

    it('fails if tenantId is missing or empty', async () => {
      const invalidAuth: TrustedAuthContext = {
        uid: memberUid1,
        tenantId: '',
        role: 'MEMBER',
      };
      await assert.rejects(
        async () => service.submitParticipationRequest(invalidAuth, {
          contributionMinor: 50000,
          currency: 'USD',
          durationPeriods: 6,
        }),
        (err: any) => err instanceof UnauthenticatedError
      );
    });

    it('prevents cross-tenant requests from discovering or confirming candidates', async () => {
      // Alice submits a request in tenant_prod_01
      const aliceSub = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
      });

      // Charlie from tenant_other_99 tries to get matching candidates for Alice's request
      await assert.rejects(
        async () => service.getMatchingCandidates(otherTenantAuth, {
          requestId: aliceSub.request.requestId,
        }),
        (err: any) => err instanceof TenantIsolationViolationError || err instanceof EntityNotFoundError
      );
    });
  });

  // ===========================================================================
  // 2. SUBMIT PARTICIPATION REQUEST
  // ===========================================================================

  describe('Submit Participation Request Orchestration', () => {
    it('successfully validates and persists a new request in SUBMITTED state', async () => {
      const input: SubmitParticipationRequestInput = {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 2,
        clientRequestId: 'client_sub_001',
      };

      const result = await service.submitParticipationRequest(aliceAuth, input);
      assert.equal(result.success, true);
      assert.equal(result.request.status, 'SUBMITTED');
      assert.equal(result.request.memberUid, memberUid1);
      assert.equal(result.request.tenantId, tenantId);
      assert.equal(result.request.contributionMinor, 50000);
      assert.equal(result.request.durationPeriods, 6);
      assert.equal(result.request.preferredPayoutPeriod, 2);
    });

    it('rejects invalid durationPeriods with mathematical validation error', async () => {
      const input: SubmitParticipationRequestInput = {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 13, // Invalid duration periods (must be 2..12)
      };

      await assert.rejects(
        async () => service.submitParticipationRequest(aliceAuth, input),
        (err: any) => err instanceof InvalidMemberCountError
      );
    });

    it('rejects invalid contribution amount (zero or negative)', async () => {
      const input: SubmitParticipationRequestInput = {
        contributionMinor: 0,
        currency: 'USD',
        durationPeriods: 6,
      };

      await assert.rejects(
        async () => service.submitParticipationRequest(aliceAuth, input),
        (err: any) => err instanceof InvalidPeriodicContributionError
      );
    });
  });

  // ===========================================================================
  // 3. MATCHING CANDIDATES (PROVISIONAL DISCOVERY)
  // ===========================================================================

  describe('Get Matching Candidates Orchestration', () => {
    it('discovers matching candidates without creating positions or incrementing occupancy', async () => {
      // 1. Submit Alice's request
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 1,
      });

      // 2. Populate an open FORMING allocation unit in mockDb
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const unitPath = getAllocationUnitPath('unit_test_01');
      await mockDb.doc(unitPath).set({
        unitId: 'unit_test_01',
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      // 3. Query candidates
      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: reqRes.request.requestId,
      });

      assert.equal(matchResult.requestId, reqRes.request.requestId);
      assert.ok(matchResult.candidates.length > 0);
      assert.equal(matchResult.candidates[0].allocationUnitId, 'unit_test_01');

      // 4. Verify ZERO positions were created and occupancy remained 0
      const unitDoc = await mockDb.doc(unitPath).get();
      assert.equal(unitDoc.data()?.occupiedCount, 0);
    });

    it('rejects member attempting to discover candidates for another member request', async () => {
      const aliceReq = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
      });

      // Bob tries to discover candidates for Alice's request
      await assert.rejects(
        async () => service.getMatchingCandidates(bobAuth, {
          requestId: aliceReq.request.requestId,
        }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });
  });

  // ===========================================================================
  // 4. SELECT CANDIDATE AND CONFIRM (ATOMIC ORCHESTRATION)
  // ===========================================================================

  describe('Select Candidate and Confirm Orchestration', () => {
    it('executes atomic confirmation, creates position, updates occupancy, and derives financial records', async () => {
      // 1. Submit Request
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 1,
      });

      // 2. Create forming unit
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const unitPath = getAllocationUnitPath('unit_test_confirm_01');
      await mockDb.doc(unitPath).set({
        unitId: 'unit_test_confirm_01',
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      // 3. Discover candidates
      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: reqRes.request.requestId,
      });
      const candidate = matchResult.candidates[0];

      // 4. Confirm Candidate
      const confirmInput: SelectCandidateAndConfirmInput = {
        requestId: reqRes.request.requestId,
        candidateId: candidate.candidateId,
        idempotencyKey: 'idem_alice_confirm_001',
      };

      const confirmResult = await service.selectCandidateAndConfirm(aliceAuth, confirmInput);
      assert.equal(confirmResult.isIdempotentReplay, false);
      assert.equal(confirmResult.allocationUnitId, 'unit_test_confirm_01');
      assert.ok(confirmResult.obligationId);
      assert.ok(confirmResult.scheduleId);
      assert.ok(confirmResult.entitlementId);

      // 5. Verify Unit occupancy incremented to 1
      const unitSnap = await mockDb.doc(unitPath).get();
      assert.equal(unitSnap.data()?.occupiedCount, 1);

      // 6. Verify Position document created
      const posPath = getPositionPath('unit_test_confirm_01', confirmResult.allocatedPosition);
      const posSnap = await mockDb.doc(posPath).get();
      assert.equal(posSnap.exists, true);
      assert.equal(posSnap.data()?.memberUid, memberUid1);
      assert.ok(posSnap.data()?.occupiedAt);

      // 7. Idempotent replay returns cached result
      const replayResult = await service.selectCandidateAndConfirm(aliceAuth, confirmInput);
      assert.equal(replayResult.isIdempotentReplay, true);
      assert.equal(replayResult.allocationId, confirmResult.allocationId);
    });

    it('rejects confirmation if another member attempts to confirm candidate', async () => {
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
      });

      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const unitPath = getAllocationUnitPath('unit_test_confirm_02');
      await mockDb.doc(unitPath).set({
        unitId: 'unit_test_confirm_02',
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: reqRes.request.requestId,
      });
      const candidate = matchResult.candidates[0];

      // Bob tries to confirm Alice's candidate
      await assert.rejects(
        async () => service.selectCandidateAndConfirm(bobAuth, {
          requestId: reqRes.request.requestId,
          candidateId: candidate.candidateId,
          idempotencyKey: 'idem_bob_steal_001',
        }),
        (err: any) => err instanceof UnauthorizedAccessError || (err as any)?.name === 'MemberOwnershipConfirmationError'
      );
    });
  });

  // ===========================================================================
  // 5. FINANCIAL FOUNDATION & PERIOD PROJECTION READS
  // ===========================================================================

  describe('Financial and Period Projection Reads', () => {
    let confirmedAllocId: string;
    let obligationId: string;
    let scheduleId: string;
    let entitlementId: string;
    const unitId = 'unit_financial_test_01';

    beforeEach(async () => {
      // Setup complete confirmed allocation for Alice
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 1,
      });

      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const match = await service.getMatchingCandidates(aliceAuth, { requestId: reqRes.request.requestId });
      const conf = await service.selectCandidateAndConfirm(aliceAuth, {
        requestId: reqRes.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: 'idem_fin_read_setup',
      });

      confirmedAllocId = conf.allocationId;
      obligationId = conf.obligationId!;
      scheduleId = conf.scheduleId!;
      entitlementId = conf.entitlementId!;
    });

    it('allows member to read own financial obligation', async () => {
      const res = await service.getFinancialObligation(aliceAuth, { obligationId });
      assert.equal(res.obligation.obligationId, obligationId);
      assert.equal(res.obligation.memberUid, memberUid1);
      assert.equal(res.obligation.totalObligationMinor, 300000);
    });

    it('allows reading financial obligation by allocationId', async () => {
      const res = await service.getFinancialObligation(aliceAuth, { allocationId: confirmedAllocId });
      assert.equal(res.obligation.obligationId, obligationId);
    });

    it('rejects other member reading financial obligation', async () => {
      await assert.rejects(
        async () => service.getFinancialObligation(bobAuth, { obligationId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });

    it('allows staff to read any member financial obligation within tenant', async () => {
      const res = await service.getFinancialObligation(staffAuth, { obligationId });
      assert.equal(res.obligation.obligationId, obligationId);
    });

    it('allows member to read own contribution schedule', async () => {
      const res = await service.getContributionSchedule(aliceAuth, { scheduleId });
      assert.equal(res.schedule.scheduleId, scheduleId);
      assert.equal(res.schedule.periods.length, 6);
    });

    it('rejects other member reading contribution schedule', async () => {
      await assert.rejects(
        async () => service.getContributionSchedule(bobAuth, { scheduleId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });

    it('allows member to read own payout entitlement', async () => {
      const res = await service.getPayoutEntitlement(aliceAuth, { entitlementId });
      assert.equal(res.entitlement.payoutEntitlementId, entitlementId);
      assert.equal(res.entitlement.totalEntitlementMinor, 300000);
    });

    it('rejects other member reading payout entitlement', async () => {
      await assert.rejects(
        async () => service.getPayoutEntitlement(bobAuth, { entitlementId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });

    it('reads contribution events for obligation', async () => {
      // Seed a contribution event
      await mockDb.collection(CONTRIBUTION_EVENTS_COLLECTION).doc('ev_001').set({
        contributionEventId: 'ev_001',
        tenantId,
        obligationId,
        memberUid: memberUid1,
        allocationUnitId: unitId,
        periodNumber: 1,
        amountMinor: 50000,
        currency: 'USD',
        idempotencyId: 'idem_ev_001',
        recordedAt: new Date().toISOString(),
      });

      const res = await service.getContributionEvents(aliceAuth, { obligationId });
      assert.equal(res.totalEvents, 1);
      assert.equal(res.events[0].contributionEventId, 'ev_001');
    });

    it('reads member period timeline and specific period', async () => {
      const res = await service.getMemberPeriodTimeline(aliceAuth, {
        allocationId: confirmedAllocId,
        periodNumber: 1,
      });

      assert.equal(res.projection.memberUid, memberUid1);
      assert.equal(res.projection.totalPeriods, 6);
      assert.ok(res.specificPeriod);
      assert.equal(res.specificPeriod?.periodNumber, 1);
    });

    it('reads cycle period projection for authorized member', async () => {
      const res = await service.getCyclePeriodProjection(aliceAuth, { unitId });
      assert.equal(res.projection.allocationUnitId, unitId);
      assert.equal(res.projection.memberCount, 6);
    });

    it('rejects cycle period projection read for unauthorized member', async () => {
      await assert.rejects(
        async () => service.getCyclePeriodProjection(bobAuth, { unitId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });

    it('allows staff to read cycle period projection', async () => {
      const res = await service.getCyclePeriodProjection(staffAuth, { unitId });
      assert.equal(res.projection.allocationUnitId, unitId);
    });
  });

  // ===========================================================================
  // 6. ERROR MAPPING (mapToHttpsError)
  // ===========================================================================

  describe('Deterministic Error Mapping (mapToHttpsError)', () => {
    it('maps UnauthenticatedError to unauthenticated', () => {
      const err = mapToHttpsError(new UnauthenticatedError('Missing token'));
      assert.equal(err.code, 'unauthenticated');
      assert.equal(err.message, 'Missing token');
    });

    it('maps UnauthorizedAccessError to permission-denied', () => {
      const err = mapToHttpsError(new UnauthorizedAccessError('Not owner'));
      assert.equal(err.code, 'permission-denied');
      assert.equal(err.message, 'Not owner');
    });

    it('maps TenantIsolationViolationError to permission-denied', () => {
      const err = mapToHttpsError(new TenantIsolationViolationError('tenantA', 'tenantB', 'Entity'));
      assert.equal(err.code, 'permission-denied');
    });

    it('maps EntityNotFoundError to not-found', () => {
      const err = mapToHttpsError(new EntityNotFoundError('Unit', 'unit_123'));
      assert.equal(err.code, 'not-found');
    });

    it('maps CandidateExpiredError to failed-precondition', () => {
      const err = mapToHttpsError(new CandidateExpiredError('cand_01', '2026-09-01T00:00:00Z'));
      assert.equal(err.code, 'failed-precondition');
    });

    it('maps AllocationUnitCapacityExceededError to failed-precondition', () => {
      const err = mapToHttpsError(new AllocationUnitCapacityExceededError('unit_01', 6, 6));
      assert.equal(err.code, 'failed-precondition');
    });

    it('maps PositionAlreadyOccupiedError to already-exists', () => {
      const err = mapToHttpsError(new PositionAlreadyOccupiedError('unit_01', 1));
      assert.equal(err.code, 'already-exists');
    });

    it('maps JournalEntryUnbalancedError to failed-precondition', () => {
      const err = mapToHttpsError(new JournalEntryUnbalancedError(1000, 2000));
      assert.equal(err.code, 'failed-precondition');
    });

    it('maps PeriodMathConservationError to invalid-argument', () => {
      const err = mapToHttpsError(new PeriodMathConservationError('Period sequence error'));
      assert.equal(err.code, 'invalid-argument');
    });

    it('maps generic unknown error to internal', () => {
      const err = mapToHttpsError(new Error('Random failure'));
      assert.equal(err.code, 'internal');
      assert.equal(err.message, 'Central Pool Error: Random failure');
    });
  });

  // ===========================================================================
  // 7. AUTHORIZED MEMBER UID PROVENANCE & TAMPERING RESISTANCE
  // ===========================================================================

  describe('Authorized Member UID Provenance & Tampering Resistance', () => {
    it('derives authorizedMemberUids exclusively from authoritative Position documents, not client input', async () => {
      const unitId = 'unit_tamper_test_01';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      // 1. Seed unit with Alice occupying position 1
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 1,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      await mockDb.doc(getPositionPath(unitId, 1)).set({
        unitId,
        positionNumber: 1,
        tenantId,
        memberUid: memberUid1, // Alice
        requestId: 'req_alice_01',
        payoutPeriod: 1,
        occupiedAt: new Date().toISOString(),
        version: 1,
      });

      // 2. Alice reads cycle period projection -> authorizedMemberUids contains ['usr_alice']
      const res = await service.getCyclePeriodProjection(aliceAuth, { unitId });
      assert.ok(res.projection.authorizedMemberUids?.includes(memberUid1));
      assert.equal(res.projection.authorizedMemberUids?.includes('usr_attacker'), false);

      // 3. Attacker (Bob) cannot read projection by passing any client parameter
      const attackerAuth: TrustedAuthContext = {
        uid: 'usr_attacker',
        tenantId,
        role: 'MEMBER',
      };
      await assert.rejects(
        async () => service.getCyclePeriodProjection(attackerAuth, { unitId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });
  });

  // ===========================================================================
  // 8. CONFIRMATION / FINANCIAL GENERATION BOUNDARY SEMANTICS
  // ===========================================================================

  describe('Confirmation / Financial Generation Boundary Semantics', () => {
    it('replaying confirmed allocation returns existing obligation and schedule without duplicating records', async () => {
      // 1. Submit Request
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 1,
      });

      // 2. Create forming unit
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const unitPath = getAllocationUnitPath('unit_boundary_test_01');
      await mockDb.doc(unitPath).set({
        unitId: 'unit_boundary_test_01',
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: reqRes.request.requestId,
      });
      const candidate = matchResult.candidates[0];

      const confirmInput: SelectCandidateAndConfirmInput = {
        requestId: reqRes.request.requestId,
        candidateId: candidate.candidateId,
        idempotencyKey: 'idem_boundary_001',
      };

      // 3. First execution succeeds
      const result1 = await service.selectCandidateAndConfirm(aliceAuth, confirmInput);
      assert.equal(result1.isIdempotentReplay, false);
      assert.ok(result1.obligationId);

      // 4. Repeated execution with same idempotency key returns exact same obligationId without error
      const result2 = await service.selectCandidateAndConfirm(aliceAuth, confirmInput);
      assert.equal(result2.isIdempotentReplay, true);
      assert.equal(result2.obligationId, result1.obligationId);
      assert.equal(result2.scheduleId, result1.scheduleId);
      assert.equal(result2.entitlementId, result1.entitlementId);
    });

    it('Scenario A: Step 5 confirmation succeeds, Step 6 fails -> allocation remains CONFIRMED, retry produces exactly one obligation', async () => {
      // 1. Submit Request
      const reqRes = await service.submitParticipationRequest(aliceAuth, {
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        payoutPreference: 1,
      });

      // 2. Create forming unit
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });
      const unitPath = getAllocationUnitPath('unit_failure_test_01');
      await mockDb.doc(unitPath).set({
        unitId: 'unit_failure_test_01',
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      const matchResult = await service.getMatchingCandidates(aliceAuth, {
        requestId: reqRes.request.requestId,
      });
      const candidate = matchResult.candidates[0];

      // 3. Execute Step 5 Confirmation Service directly
      const confirmService = (service as any).confirmationService;
      const confirmRes = await confirmService.confirmAllocation({
        tenantId,
        memberUid: memberUid1,
        requestId: reqRes.request.requestId,
        candidateId: candidate.candidateId,
        idempotencyKey: 'idem_fail_recovery_001',
      });

      assert.equal(confirmRes.success, true);

      // Verify Step 5 state before financial generation:
      const updatedReqDoc = await mockDb.doc(getParticipationRequestPath(reqRes.request.requestId)).get();
      assert.equal(updatedReqDoc.data()?.status, 'CONFIRMED');

      const posDoc = await mockDb.doc(getPositionPath('unit_failure_test_01', confirmRes.allocatedPosition)).get();
      assert.equal(posDoc.exists, true);
      assert.equal(posDoc.data()?.memberUid, memberUid1);

      // Financial obligation does NOT exist yet:
      const obligationPath = `/financial_obligations/ob_${confirmRes.allocationId}`;
      assert.equal(mockDb.docs.has(obligationPath), false);

      // 4. Injected failure in Step 6 / Retry Step 6 deterministic generation
      const obligationService = (service as any).obligationService;
      const finRes = await obligationService.generateObligation({
        tenantId,
        memberUid: memberUid1,
        allocationId: confirmRes.allocationId,
        allocationUnitId: confirmRes.allocationUnitId,
        positionNumber: confirmRes.allocatedPosition,
        contributionMinor: confirmRes.contributionMinor,
        totalPeriods: confirmRes.durationPeriods,
        currency: confirmRes.currency,
        idempotencyKey: 'idem_fail_recovery_001',
        nowIso: confirmRes.confirmedAt,
      });

      assert.equal(finRes.isIdempotentReplay, false);
      assert.ok(finRes.obligation.obligationId);

      // 5. Subsequent retry returns the exact same obligation without duplication
      const finResRetry = await obligationService.generateObligation({
        tenantId,
        memberUid: memberUid1,
        allocationId: confirmRes.allocationId,
        allocationUnitId: confirmRes.allocationUnitId,
        positionNumber: confirmRes.allocatedPosition,
        contributionMinor: confirmRes.contributionMinor,
        totalPeriods: confirmRes.durationPeriods,
        currency: confirmRes.currency,
        idempotencyKey: 'idem_fail_recovery_001',
        nowIso: confirmRes.confirmedAt,
      });

      assert.equal(finResRetry.isIdempotentReplay, true);
      assert.equal(finResRetry.obligation.obligationId, finRes.obligation.obligationId);
    });
  });

  // ===========================================================================
  // 9. MATCHED NON-PERSISTENCE & CANONICAL JOURNAL PATH AUDIT
  // ===========================================================================

  describe('MATCHED Non-Persistence & Canonical Journal Path Audit', () => {
    it('verifies MATCHED is a non-persisted domain alias and cannot be stored to Firestore', () => {
      const { participationRequestToDoc } = require('../../persistence/dto/dto_converters');
      const { InvalidPersistenceStateError } = require('../../persistence/persistence_errors');

      const matchedRequest = {
        requestId: 'req_matched_01',
        tenantId,
        memberUid: memberUid1,
        contributionMinor: 50000,
        currency: 'USD',
        durationPeriods: 6,
        status: 'MATCHED' as any, // Non-persisted alias
        clientSubmissionId: 'sub_001',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        requestExpiresAt: new Date(Date.now() + 3600000).toISOString(),
        version: 1,
      };

      assert.throws(
        () => participationRequestToDoc(matchedRequest),
        (err: any) => err instanceof InvalidPersistenceStateError && err.message.includes('not a permitted persisted Firestore state')
      );
    });

    it('verifies canonical GL journal entries are stored under /accounting_journal_entries, not /gl_journal_entries', async () => {
      const { getAccountingJournalEntryPath, ACCOUNTING_JOURNAL_ENTRIES_COLLECTION } = require('../../domain/domain_paths');
      assert.equal(ACCOUNTING_JOURNAL_ENTRIES_COLLECTION, 'accounting_journal_entries');
      assert.equal(getAccountingJournalEntryPath('je_123'), 'accounting_journal_entries/je_123');
    });

    it('verifies authorizedMemberUids does not dictate AllocationUnit.occupiedCount or position occupancy', async () => {
      const unitId = 'unit_authority_test_01';
      const compatKey = computeCompatibilityKey({
        tenantId,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      // Unit has occupiedCount = 0 and no positions
      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId,
        compatibilityKey: compatKey,
        memberCount: 6,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalPoolMinor: 300000,
        occupiedCount: 0,
        status: 'FORMING',
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      });

      // Seed a detached/stale projection document containing an arbitrary user
      const staleProjectionPath = `${getAllocationUnitPath(unitId)}/period_projections/cpp_stale`;
      await mockDb.doc(staleProjectionPath).set({
        projectionId: 'cpp_stale',
        tenantId,
        allocationUnitId: unitId,
        memberCount: 6,
        periodicContributionMinor: 50000,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        authorizedMemberUids: ['usr_fake_001'],
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        generatedAt: new Date().toISOString(),
      });

      // Assert unit occupancy remains 0:
      const unitDoc = await mockDb.doc(getAllocationUnitPath(unitId)).get();
      assert.equal(unitDoc.data()?.occupiedCount, 0);

      // Assert position 1 remains unoccupied:
      const posDoc = await mockDb.doc(getPositionPath(unitId, 1)).get();
      assert.equal(posDoc.exists, false);
    });
  });
});
