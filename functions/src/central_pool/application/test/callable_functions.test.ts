/**
 * Central Pool Step 8: Callable Functions & Auth Extraction Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import { extractTrustedAuthContext } from '../callable_functions';

describe('CENTRAL POOL — Step 8: Callable Functions & Auth Extraction', () => {
  it('throws unauthenticated HttpsError when request.auth is missing', () => {
    const unauthenticatedReq = {
      auth: undefined,
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(unauthenticatedReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('throws unauthenticated HttpsError when uid is empty or whitespace', () => {
    const emptyUidReq = {
      auth: {
        uid: '   ',
        token: { tenantId: 'tenant_001' },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(emptyUidReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('throws unauthenticated HttpsError when tenantId claim is missing from token', () => {
    const noTenantReq = {
      auth: {
        uid: 'usr_basic_001',
        token: {},
      },
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(noTenantReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('throws unauthenticated HttpsError when tenantId claim is empty or whitespace', () => {
    const emptyTenantReq = {
      auth: {
        uid: 'usr_basic_001',
        token: { tenantId: '   ' },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(emptyTenantReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('defaults safely to lowest-privilege MEMBER role when role claim is not stamped', () => {
    const standardMemberReq = {
      auth: {
        uid: 'usr_member_001',
        token: {
          tenantId: 'tenant_std_01',
        },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    const auth = extractTrustedAuthContext(standardMemberReq);
    assert.equal(auth.uid, 'usr_member_001');
    assert.equal(auth.tenantId, 'tenant_std_01');
    assert.equal(auth.role, 'MEMBER');
  });

  it('extracts explicit tenantId and role from custom token claims', () => {
    const staffReq = {
      auth: {
        uid: 'usr_staff_001',
        token: {
          tenantId: 'tenant_custom_42',
          role: 'FINOPS',
          email: 'staff@example.com',
        },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    const auth = extractTrustedAuthContext(staffReq);
    assert.equal(auth.uid, 'usr_staff_001');
    assert.equal(auth.tenantId, 'tenant_custom_42');
    assert.equal(auth.role, 'FINOPS');
    assert.equal(auth.email, 'staff@example.com');
  });

  it('rejects invalid, unknown, or spoofed role claims with unauthenticated error', () => {
    const invalidRoleReq = {
      auth: {
        uid: 'usr_hacker_001',
        token: {
          tenantId: 'tenant_custom_42',
          role: 'SUPERUSER', // Unknown / unauthorized role
        },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(invalidRoleReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('rejects non-string role claims with unauthenticated error', () => {
    const numericRoleReq = {
      auth: {
        uid: 'usr_hacker_002',
        token: {
          tenantId: 'tenant_custom_42',
          role: 999 as any,
        },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    assert.throws(
      () => extractTrustedAuthContext(numericRoleReq),
      (err: any) => err instanceof HttpsError && err.code === 'unauthenticated'
    );
  });

  it('handles snake_case tenant_id claim format gracefully', () => {
    const req = {
      auth: {
        uid: 'usr_snake_001',
        token: {
          tenant_id: 'tenant_snake_99',
          role: 'ADMIN',
        },
      },
      data: {},
    } as unknown as CallableRequest<any>;

    const auth = extractTrustedAuthContext(req);
    assert.equal(auth.tenantId, 'tenant_snake_99');
    assert.equal(auth.role, 'ADMIN');
  });
});
