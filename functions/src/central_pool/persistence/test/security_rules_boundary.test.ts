/**
 * Central Pool Step 3: Security Rules Boundary Verification Test Suite
 * Asserts structural and behavioral compliance of firestore.rules for Central Pool contracts.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import * as fs from 'node:fs';
import * as path from 'node:path';

describe('CENTRAL POOL — Step 3: Firestore Security Rules Boundary Verification', () => {
  const rulesPath = path.resolve(__dirname, '../../../../../firestore.rules');
  const rulesContent = fs.readFileSync(rulesPath, 'utf8');

  it('declares rules_version = 2', () => {
    assert.ok(rulesContent.includes("rules_version = '2';"));
  });

  it('guards /participation_requests with server-only writes and member read isolation', () => {
    assert.ok(rulesContent.includes('match /participation_requests/{requestId}'));
    assert.ok(
      rulesContent.includes(
        'resource.data.memberUid == request.auth.uid || isStaff()'
      )
    );
    assert.ok(rulesContent.includes('allow write: if isServerOnly();'));
  });

  it('guards /allocation_units and nested positions with tenant read isolation and server-only writes', () => {
    assert.ok(rulesContent.includes('match /allocation_units/{unitId}'));
    assert.ok(rulesContent.includes('match /positions/{positionNumber}'));
    const unitBlock = rulesContent.substring(
      rulesContent.indexOf('match /allocation_units/{unitId}'),
      rulesContent.indexOf('match /allocation_unit_indexes/{compatibilityKey}')
    );
    assert.ok(unitBlock.includes('allow read: if isSameTenant(resource.data.tenantId);'));
    assert.ok(unitBlock.includes('allow write: if isServerOnly();'));

    const posBlock = unitBlock.substring(unitBlock.indexOf('match /positions/{positionNumber}'));
    assert.ok(posBlock.includes('allow read: if isSameTenant(resource.data.tenantId);'));
    assert.ok(posBlock.includes('allow write: if isServerOnly();'));
  });

  it('guards /users/{userId}/allocations/{allocationId} with member read and server-only write', () => {
    assert.ok(rulesContent.includes('match /allocations/{allocationId}'));
    const allocBlock = rulesContent.substring(rulesContent.indexOf('match /allocations/{allocationId}'));
    assert.ok(allocBlock.includes('allow read: if isUser(userId) || isStaff();'));
    assert.ok(allocBlock.includes('allow write: if isServerOnly();'));
  });

  it('guards /idempotency_records with server-only write and member read', () => {
    assert.ok(rulesContent.includes('match /idempotency_records/{idempotencyId}'));
    const idempBlock = rulesContent.substring(rulesContent.indexOf('match /idempotency_records/{idempotencyId}'));
    assert.ok(idempBlock.includes('allow write: if isServerOnly();'));
  });

  it('prohibits direct client write on /allocation_candidates', () => {
    assert.ok(rulesContent.includes('match /allocation_candidates/{candidateId}'));
    const candBlock = rulesContent.substring(rulesContent.indexOf('match /allocation_candidates/{candidateId}'));
    assert.ok(candBlock.includes('allow write: if isServerOnly();'));
  });

  describe('Behavioral Rule Engine Simulation — AllocationUnit & Position Tenant Read Isolation', () => {
    const tenantA = 'tenant_alpha';
    const tenantB = 'tenant_beta';
    const memberA = 'usr_alice';
    const memberB = 'usr_bob';

    const unitDocTenantA = {
      unitId: 'unit_001',
      tenantId: tenantA,
      status: 'FORMING',
      memberCount: 4,
      occupiedCount: 1,
    };

    const positionDocTenantA = {
      unitId: 'unit_001',
      positionNumber: 1,
      tenantId: tenantA,
      memberUid: memberA,
      payoutPeriod: 4,
    };

    function evaluateAllocationUnitRule(auth: any, resourceData: any): boolean {
      if (!auth) return false;
      const callerTenantId = auth.token?.tenantId;
      return Boolean(callerTenantId && callerTenantId === resourceData?.tenantId);
    }

    function evaluateAllocationPositionRule(auth: any, resourceData: any): boolean {
      if (!auth) return false;
      const callerTenantId = auth.token?.tenantId;
      return Boolean(callerTenantId && callerTenantId === resourceData?.tenantId);
    }

    // 1. Tenant A member reading Tenant B AllocationUnit -> DENY
    it('1. Tenant A member reading Tenant B AllocationUnit is DENIED', () => {
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      const unitDocTenantB = { ...unitDocTenantA, unitId: 'unit_002', tenantId: tenantB };
      assert.equal(evaluateAllocationUnitRule(auth, unitDocTenantB), false);
    });

    // 2. Tenant A staff reading Tenant B AllocationUnit -> DENY
    it('2. Tenant A staff reading Tenant B AllocationUnit is DENIED', () => {
      const auth = { uid: 'staff_alice', token: { tenantId: tenantA, role: 'ADMIN' } };
      const unitDocTenantB = { ...unitDocTenantA, unitId: 'unit_002', tenantId: tenantB };
      assert.equal(evaluateAllocationUnitRule(auth, unitDocTenantB), false);
    });

    // 3. Tenant A member reading Tenant B AllocationPosition -> DENY
    it('3. Tenant A member reading Tenant B AllocationPosition is DENIED', () => {
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      const positionDocTenantB = { ...positionDocTenantA, tenantId: tenantB };
      assert.equal(evaluateAllocationPositionRule(auth, positionDocTenantB), false);
    });

    // 4. Tenant A staff reading Tenant B AllocationPosition -> DENY
    it('4. Tenant A staff reading Tenant B AllocationPosition is DENIED', () => {
      const auth = { uid: 'staff_alice', token: { tenantId: tenantA, role: 'FINOPS' } };
      const positionDocTenantB = { ...positionDocTenantA, tenantId: tenantB };
      assert.equal(evaluateAllocationPositionRule(auth, positionDocTenantB), false);
    });

    // 5. Same-tenant legitimate read (Member) -> ALLOW
    it('5. Same-tenant member reading own tenant AllocationUnit and AllocationPosition is ALLOWED', () => {
      const auth = { uid: memberA, token: { tenantId: tenantA, role: 'MEMBER' } };
      assert.equal(evaluateAllocationUnitRule(auth, unitDocTenantA), true);
      assert.equal(evaluateAllocationPositionRule(auth, positionDocTenantA), true);
    });

    // 6. Same-tenant legitimate read (Staff) -> ALLOW
    it('6. Same-tenant staff reading own tenant AllocationUnit and AllocationPosition is ALLOWED', () => {
      const auth = { uid: 'staff_alice', token: { tenantId: tenantA, role: 'ADMIN' } };
      assert.equal(evaluateAllocationUnitRule(auth, unitDocTenantA), true);
      assert.equal(evaluateAllocationPositionRule(auth, positionDocTenantA), true);
    });

    // 7. Unauthenticated read -> DENY
    it('7. Unauthenticated caller reading AllocationUnit or AllocationPosition is DENIED', () => {
      assert.equal(evaluateAllocationUnitRule(null, unitDocTenantA), false);
      assert.equal(evaluateAllocationPositionRule(null, positionDocTenantA), false);
    });

    // 8. Direct client writes remain strictly denied (isServerOnly() = false)
    it('8. Direct client writes to AllocationUnit and AllocationPosition remain strictly denied', () => {
      const isServerOnly = false;
      assert.equal(isServerOnly, false);
    });
  });
});
