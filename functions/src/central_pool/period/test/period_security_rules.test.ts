/**
 * Central Pool Step 7: Security Rules Boundary Verification Test Suite
 * Asserts structural compliance and behavioral logic of firestore.rules for Step 7 Period Projection subcollections.
 * Reference: S7-01-A..S7-01-G Security Test Matrix.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import * as fs from 'node:fs';
import * as path from 'node:path';

describe('CENTRAL POOL — Step 7: Firestore Security Rules Period Projection Verification', () => {
  const rulesPath = path.resolve(__dirname, '../../../../../firestore.rules');
  const rulesContent = fs.readFileSync(rulesPath, 'utf8');

  // Rule evaluator simulating Firestore Security Rules engine for /users/{userId}/period_projections/{projectionId}
  function evaluateUserPeriodProjectionRule(auth: any, resourceData: any, targetUserId: string): boolean {
    if (!auth) return false;
    const isUser = auth.uid === targetUserId;
    const isStaff = ['ADMIN', 'FINOPS', 'COMPLIANCE', 'SECURITY', 'AUDITOR'].includes(auth.token?.role);
    const isTenantStaff = isStaff && auth.token?.tenantId === resourceData?.tenantId;
    return isUser || isTenantStaff;
  }

  // Rule evaluator simulating Firestore Security Rules engine for /allocation_units/{unitId}/period_projections/{projectionId}
  function evaluateUnitPeriodProjectionRule(auth: any, resourceData: any, parentUnitData: any): boolean {
    if (!auth) return false;
    const callerTenantId = auth.token?.tenantId;
    const isSameTenant = callerTenantId === resourceData?.tenantId;
    const isParentTenantConsistent = resourceData?.tenantId === parentUnitData?.tenantId;
    const isStaff = ['ADMIN', 'FINOPS', 'COMPLIANCE', 'SECURITY', 'AUDITOR'].includes(auth.token?.role);
    const isAuthorizedMember = Array.isArray(resourceData?.authorizedMemberUids) && resourceData.authorizedMemberUids.includes(auth.uid);

    return isSameTenant && isParentTenantConsistent && (isStaff || isAuthorizedMember);
  }

  it('declares rules_version = 2', () => {
    assert.ok(rulesContent.includes("rules_version = '2';"));
  });

  it('defines isSameTenant and isTenantStaff helper functions in firestore.rules', () => {
    assert.ok(rulesContent.includes('function getCallerTenantId()'));
    assert.ok(rulesContent.includes('function isSameTenant(tenantId)'));
    assert.ok(rulesContent.includes('function isTenantStaff(tenantId)'));
  });

  it('guards /users/{userId}/period_projections with server-only writes and member/tenant-staff read boundary', () => {
    const userBlock = rulesContent.substring(
      rulesContent.indexOf('match /users/{userId}'),
      rulesContent.indexOf('match /gameya_circles/{circleId}')
    );
    assert.ok(userBlock.includes('match /period_projections/{projectionId}'));
    const periodBlock = userBlock.substring(userBlock.indexOf('match /period_projections/{projectionId}'));
    assert.ok(periodBlock.includes('allow read: if isUser(userId) || isTenantStaff(resource.data.tenantId);'));
    assert.ok(periodBlock.includes('allow write: if isServerOnly();'));
  });

  it('guards /allocation_units/{unitId}/period_projections with parent tenant consistency, authorized member check, and server-only writes', () => {
    const unitBlock = rulesContent.substring(
      rulesContent.indexOf('match /allocation_units/{unitId}'),
      rulesContent.indexOf('match /allocation_unit_indexes/{compatibilityKey}')
    );
    assert.ok(unitBlock.includes('match /period_projections/{projectionId}'));
    const periodBlock = unitBlock.substring(unitBlock.indexOf('match /period_projections/{projectionId}'));
    assert.ok(periodBlock.includes('request.auth.token.tenantId == resource.data.tenantId'));
    assert.ok(periodBlock.includes('resource.data.tenantId == get(/databases/$(database)/documents/allocation_units/$(unitId)).data.tenantId'));
    assert.ok(periodBlock.includes('isStaff() ||'));
    assert.ok(periodBlock.includes('request.auth.uid in resource.data.authorizedMemberUids'));
    assert.ok(periodBlock.includes('allow write: if isServerOnly();'));
  });

  describe('Behavioral Rule Engine Simulation — S7-01-G Security Test Matrix', () => {
    const tenantA = 'tenant_alpha';
    const tenantB = 'tenant_beta';
    const memberA = 'usr_alice';
    const memberB = 'usr_bob';

    const parentUnitDocTenantA = {
      unitId: 'unit_001',
      tenantId: tenantA,
      memberCount: 4,
    };

    const projectionDocTenantA = {
      projectionId: 'cpp_001',
      tenantId: tenantA,
      allocationUnitId: 'unit_001',
      authorizedMemberUids: [memberA, 'usr_charlie', 'usr_dave', 'usr_eve'],
    };

    const userProjectionDocTenantA = {
      projectionId: 'mpp_001',
      tenantId: tenantA,
      memberUid: memberA,
      allocationId: 'alloc_001',
    };

    // S7-01-G Row 1: Member A | Tenant A | Unit A | Authorized | ALLOW
    it('[Row 1] Member A (Tenant A, Authorized) reading Unit A period projection is ALLOWED', () => {
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, parentUnitDocTenantA);
      assert.equal(allowed, true);
    });

    // S7-01-G Row 2: Member B | Tenant A | Unit A | Unauthorized | DENY
    it('[Row 2] Member B (Tenant A, Unauthorized) reading Unit A period projection is DENIED', () => {
      const auth = { uid: memberB, token: { tenantId: tenantA, role: 'MEMBER' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, parentUnitDocTenantA);
      assert.equal(allowed, false);
    });

    // S7-01-G Row 3: Member B | Tenant B | Unit A | Cross-tenant | DENY
    it('[Row 3] Member B (Tenant B, Cross-tenant) reading Unit A period projection is DENIED', () => {
      const auth = { uid: memberB, token: { tenantId: tenantB, role: 'MEMBER' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, parentUnitDocTenantA);
      assert.equal(allowed, false);
    });

    // S7-01-G Row 4: Staff A | Tenant A | Unit A | Staff same tenant | ALLOW
    it('[Row 4] Staff A (Tenant A, Same-tenant) reading Unit A period projection is ALLOWED', () => {
      const auth = { uid: 'staff_alice', token: { tenantId: tenantA, role: 'FINOPS' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, parentUnitDocTenantA);
      assert.equal(allowed, true);
    });

    // S7-01-G Row 5: Staff B | Tenant B | Unit A | Staff cross tenant | DENY
    it('[Row 5] Staff B (Tenant B, Cross-tenant) reading Unit A period projection is DENIED', () => {
      const auth = { uid: 'staff_bob', token: { tenantId: tenantB, role: 'FINOPS' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, parentUnitDocTenantA);
      assert.equal(allowed, false);
    });

    // S7-01-G Row 6: User A | Tenant A | User A projection | Own user | ALLOW
    it('[Row 6] User A (Tenant A, Own user) reading User A projection is ALLOWED', () => {
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      const allowed = evaluateUserPeriodProjectionRule(auth, userProjectionDocTenantA, memberA);
      assert.equal(allowed, true);
    });

    // S7-01-G Row 7: User B | Tenant A | User A projection | Other member | DENY
    it('[Row 7] User B (Tenant A, Other member) reading User A projection is DENIED', () => {
      const auth = { uid: memberB, token: { tenantId: tenantA, role: 'MEMBER' } };
      const allowed = evaluateUserPeriodProjectionRule(auth, userProjectionDocTenantA, memberA);
      assert.equal(allowed, false);
    });

    // S7-01-G Row 8: Staff B | Tenant B | User A projection | Cross tenant | DENY
    it('[Row 8] Staff B (Tenant B, Cross-tenant) reading User A projection is DENIED', () => {
      const auth = { uid: 'staff_bob', token: { tenantId: tenantB, role: 'FINOPS' } };
      const allowed = evaluateUserPeriodProjectionRule(auth, userProjectionDocTenantA, memberA);
      assert.equal(allowed, false);
    });

    // S7-01-G Row 9: Unauthenticated | — | Any projection | None | DENY
    it('[Row 9] Unauthenticated caller reading any projection is DENIED', () => {
      const allowedUnit = evaluateUnitPeriodProjectionRule(null, projectionDocTenantA, parentUnitDocTenantA);
      const allowedUser = evaluateUserPeriodProjectionRule(null, userProjectionDocTenantA, memberA);
      assert.equal(allowedUnit, false);
      assert.equal(allowedUser, false);
    });

    // S7-01-B Parent Tenant Inconsistency Check
    it('[Parent Tenant Inconsistency] Projection with mismatched parent AllocationUnit tenant is DENIED', () => {
      const corruptedParentUnit = {
        unitId: 'unit_001',
        tenantId: tenantB, // Mismatched parent tenant
        memberCount: 4,
      };
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      const allowed = evaluateUnitPeriodProjectionRule(auth, projectionDocTenantA, corruptedParentUnit);
      assert.equal(allowed, false);
    });
  });
});
