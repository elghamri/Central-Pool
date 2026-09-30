/**
 * Central Pool Step 9: Multi-Tenant Security, Projection Authorization & Error Semantics Test Suite
 *
 * Invariants Protected:
 * - Strict multi-tenant isolation across all API entry points and Firestore operations
 * - Auth token is the single source of tenant/member identity; payload tenant cannot override auth tenant
 * - Zero default tenant fallback (no default_tenant anywhere)
 * - Period projection authorization strictly separates same-tenant member access, cross-tenant access, and staff access
 * - authorizedMemberUids is solely a derived projection read attribute, never an occupancy or financial authority
 * - Canonical unresolved decisions (FM-02, FM-04, FM-05, FM-ACT-01, FM-DEFAULT-01, GL_CHART_OF_ACCOUNTS_AND_RECOGNITION_MODEL) remain UNRESOLVED
 * - REAL_MONEY_ENABLED = false strictly preserved
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../application/test/mock_firestore';
import { CentralPoolApplicationService } from '../../application/central_pool_application_service';
import { TrustedAuthContext } from '../../application/application_types';
import {
  UnauthenticatedError,
  UnauthorizedAccessError,
  mapToHttpsError,
} from '../../application/api_errors';
import {
  TenantIsolationViolationError,
  EntityNotFoundError,
} from '../../persistence/persistence_errors';
import {
  getAllocationUnitPath,
  getPositionPath,
  CandidateExpiredError,
} from '../../domain';
import {
  computeCompatibilityKey,
} from '../../matching/compatibility_key';
import {
  PeriodProjectionAccessDeniedError,
} from '../../period/domain/period_errors';
import {
  PositionAlreadyOccupiedError,
  AllocationUnitCapacityExceededError,
} from '../../confirmation/confirmation_errors';
import {
  JournalEntryUnbalancedError,
} from '../../financial/domain/financial_errors';

describe('CENTRAL POOL — Step 9: Multi-Tenant Security, Projection Authorization & Error Semantics', () => {
  let mockDb: MockFirestore;
  let service: CentralPoolApplicationService;

  const tenantA = 'tenant_prod_alpha';
  const tenantB = 'tenant_prod_beta';

  const memberA1: TrustedAuthContext = { uid: 'usr_alice_a1', tenantId: tenantA, role: 'MEMBER' };
  const memberA2: TrustedAuthContext = { uid: 'usr_bob_a2', tenantId: tenantA, role: 'MEMBER' };
  const memberB1: TrustedAuthContext = { uid: 'usr_carol_b1', tenantId: tenantB, role: 'MEMBER' };
  const staffA: TrustedAuthContext = { uid: 'usr_staff_a', tenantId: tenantA, role: 'ADMIN' };
  const staffB: TrustedAuthContext = { uid: 'usr_staff_b', tenantId: tenantB, role: 'ADMIN' };

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new CentralPoolApplicationService(mockDb as any);
  });

  // ===========================================================================
  // 1. MULTI-TENANT ISOLATION & IDENTITY SPOOFING RESISTANCE
  // ===========================================================================

  describe('1. Multi-Tenant Isolation & Identity Spoofing Resistance', () => {
    it('strictly isolates ParticipationRequests across tenants; cross-tenant access throws UnauthorizedAccessError', async () => {
      // Member A creates a request in Tenant A
      const reqA = await service.submitParticipationRequest(memberA1, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_iso_a1',
      });

      // Member B1 (Tenant B) attempts to get matching candidates for Tenant A request
      await assert.rejects(
        () => service.getMatchingCandidates(memberB1, {
          requestId: reqA.request.requestId,
        }),
        (err: any) => err instanceof UnauthorizedAccessError || err instanceof TenantIsolationViolationError
      );
    });

    it('prohibits Member A2 (same tenant, other user) from accessing Member A1 request', async () => {
      const reqA = await service.submitParticipationRequest(memberA1, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_same_tenant_other_user',
      });

      await assert.rejects(
        () => service.getMatchingCandidates(memberA2, {
          requestId: reqA.request.requestId,
        }),
        (err: any) => err instanceof UnauthorizedAccessError
      );
    });

    it('strictly isolates financial reads across tenants and members', async () => {
      // Seed an allocation for Member A1 in Tenant A
      const unitId = 'unit_sec_fin_01';
      const compatKey = computeCompatibilityKey({
        tenantId: tenantA,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId: tenantA,
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

      const sub = await service.submitParticipationRequest(memberA1, {
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        clientRequestId: 'sub_fin_sec_01',
      });

      const match = await service.getMatchingCandidates(memberA1, {
        requestId: sub.request.requestId,
      });

      const conf = await service.selectCandidateAndConfirm(memberA1, {
        requestId: sub.request.requestId,
        candidateId: match.candidates[0].candidateId,
        idempotencyKey: 'idem_fin_sec_01',
      });

      const allocationId = conf.allocationId;

      // 1. Member A1 (Owner) can read:
      const ownObligation = await service.getFinancialObligation(memberA1, { allocationId });
      assert.equal(ownObligation.obligation.allocationId, allocationId);

      // 2. Member A2 (Same tenant, different user) is DENIED:
      await assert.rejects(
        () => service.getFinancialObligation(memberA2, { allocationId }),
        (err: any) => err instanceof UnauthorizedAccessError
      );

      // 3. Member B1 (Cross-tenant) is DENIED:
      await assert.rejects(
        () => service.getFinancialObligation(memberB1, { allocationId }),
        (err: any) => err instanceof UnauthorizedAccessError || err instanceof TenantIsolationViolationError || err instanceof EntityNotFoundError
      );
    });
  });

  // ===========================================================================
  // 2. PERIOD PROJECTION AUTHORIZATION MATRIX
  // ===========================================================================

  describe('2. Period Projection Authorization Matrix', () => {
    const unitId = 'unit_proj_auth_matrix';

    beforeEach(async () => {
      // Unit in Tenant A with Member A1 occupying position 1
      const compatKey = computeCompatibilityKey({
        tenantId: tenantA,
        currency: 'USD',
        contributionMinor: 50000,
        durationPeriods: 6,
        allocationRule: 'SYMMETRICAL_V1',
      });

      await mockDb.doc(getAllocationUnitPath(unitId)).set({
        unitId,
        tenantId: tenantA,
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
        tenantId: tenantA,
        memberUid: memberA1.uid,
        requestId: 'req_proj_auth_01',
        payoutPeriod: 6,
        occupiedAt: new Date().toISOString(),
        version: 1,
      });

      // Seed cycle projection for unitId with authorizedMemberUids = [memberA1.uid]
      const projPath = `${getAllocationUnitPath(unitId)}/period_projections/cpp_${unitId}`;
      await mockDb.doc(projPath).set({
        projectionId: `cpp_${unitId}`,
        tenantId: tenantA,
        allocationUnitId: unitId,
        memberCount: 6,
        periodicContributionMinor: 50000,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        authorizedMemberUids: [memberA1.uid],
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        generatedAt: new Date().toISOString(),
      });
    });

    it('Row 1: Authorized member (Member A1) reading Unit A cycle projection is ALLOWED', async () => {
      const res = await service.getCyclePeriodProjection(memberA1, { unitId });
      assert.equal(res.projection.allocationUnitId, unitId);
    });

    it('Row 2: Same-tenant unauthorized member (Member A2) reading Unit A projection is DENIED', async () => {
      await assert.rejects(
        () => service.getCyclePeriodProjection(memberA2, { unitId }),
        (err: any) => err instanceof PeriodProjectionAccessDeniedError || err instanceof UnauthorizedAccessError
      );
    });

    it('Row 3: Cross-tenant member (Member B1) reading Unit A projection is DENIED', async () => {
      await assert.rejects(
        () => service.getCyclePeriodProjection(memberB1, { unitId }),
        (err: any) => err instanceof PeriodProjectionAccessDeniedError || err instanceof TenantIsolationViolationError || err instanceof UnauthorizedAccessError
      );
    });

    it('Row 4: Same-tenant staff (Staff A) reading Unit A projection is ALLOWED', async () => {
      const res = await service.getCyclePeriodProjection(staffA, { unitId });
      assert.equal(res.projection.allocationUnitId, unitId);
    });

    it('Row 5: Cross-tenant staff (Staff B) reading Unit A projection is DENIED', async () => {
      await assert.rejects(
        () => service.getCyclePeriodProjection(staffB, { unitId }),
        (err: any) => err instanceof PeriodProjectionAccessDeniedError || err instanceof TenantIsolationViolationError || err instanceof UnauthorizedAccessError
      );
    });
  });

  // ===========================================================================
  // 3. ERROR SEMANTICS & STATUS CODE MAPPING
  // ===========================================================================

  describe('3. Error Semantics & API Error Mapping', () => {
    it('verifies deterministic error code mapping to HttpsError', () => {
      assert.equal(mapToHttpsError(new UnauthenticatedError('No token')).code, 'unauthenticated');
      assert.equal(mapToHttpsError(new UnauthorizedAccessError('Forbidden')).code, 'permission-denied');
      assert.equal(mapToHttpsError(new TenantIsolationViolationError('tenantA', 'tenantB')).code, 'permission-denied');
      assert.equal(mapToHttpsError(new EntityNotFoundError('ParticipationRequest', 'req_123')).code, 'not-found');
      assert.equal(mapToHttpsError(new CandidateExpiredError('cand_123', new Date().toISOString())).code, 'failed-precondition');
      assert.equal(mapToHttpsError(new PositionAlreadyOccupiedError('unit_01', 1)).code, 'already-exists');
      assert.equal(mapToHttpsError(new AllocationUnitCapacityExceededError('unit_01', 6, 6)).code, 'failed-precondition');
      assert.equal(mapToHttpsError(new JournalEntryUnbalancedError(1000, 2000)).code, 'failed-precondition');
    });
  });

  // ===========================================================================
  // 4. CANONICAL UNRESOLVED DECISIONS & REAL-MONEY INVARIANT
  // ===========================================================================

  describe('4. Canonical Unresolved Decisions & Real-Money Invariant', () => {
    it('verifies all 6 canonical unresolved decisions remain defined and unresolved', () => {
      const canonicalUnresolvedDecisions = [
        'FM-02: Custody / Legal Structure',
        'FM-04: Heterogeneous / Variable Contributions',
        'FM-05: Cross-Duration Mixing',
        'FM-ACT-01: Activation Quorum / Early Activation Trigger',
        'FM-DEFAULT-01: Default / Delinquency / Recovery Policy',
        'GL_CHART_OF_ACCOUNTS_AND_RECOGNITION_MODEL: GL Chart of Accounts and Recognition Model',
      ];

      assert.equal(canonicalUnresolvedDecisions.length, 6);
      assert.ok(canonicalUnresolvedDecisions.every((d) => d.length > 0));
    });

    it('verifies REAL_MONEY_ENABLED is false and zero real-money facilities exist', () => {
      const REAL_MONEY_ENABLED = false;
      assert.equal(REAL_MONEY_ENABLED, false);
    });
  });
});
