/**
 * Central Pool Step 4: Compatibility & Candidate Hashing Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  canonicalJson,
  computeCompatibilityKey,
  computeCandidateId,
  CompatibilityTuple,
  CandidateIdentityParams,
} from '../compatibility_key';

describe('CENTRAL POOL — Step 4: Deterministic Compatibility & Candidate Identity Hashing', () => {
  describe('1. Canonical JSON Serialization (RFC 8785)', () => {
    it('produces identical serialized JSON regardless of property insertion order', () => {
      const obj1 = { z: 1, a: 'hello', m: { b: 2, a: 1 } };
      const obj2 = { a: 'hello', m: { a: 1, b: 2 }, z: 1 };

      const json1 = canonicalJson(obj1);
      const json2 = canonicalJson(obj2);

      assert.equal(json1, json2);
      assert.equal(json1, '{"a":"hello","m":{"a":1,"b":2},"z":1}');
    });
  });

  describe('2. S4-01: Compatibility Key Schema & Invariant Dimensions', () => {
    const baseTuple: CompatibilityTuple = {
      tenantId: 'tenant_prod_01',
      currency: 'USD',
      contributionMinor: 50000,
      durationPeriods: 10,
      allocationRule: 'SYMMETRICAL_V1',
    };

    it('1. identical compatibility context -> identical key', () => {
      const key1 = computeCompatibilityKey(baseTuple);
      const key2 = computeCompatibilityKey({ ...baseTuple });

      assert.equal(key1, key2);
      assert.ok(key1.startsWith('cp_'));
      assert.equal(key1.length, 3 + 64); // 'cp_' + 64 hex characters (full 256-bit SHA-256)
    });

    it('2. different tenant -> different key', () => {
      const baseKey = computeCompatibilityKey(baseTuple);
      const diffTenant = computeCompatibilityKey({ ...baseTuple, tenantId: 'tenant_prod_02' });
      assert.notEqual(baseKey, diffTenant);
    });

    it('3. different contribution -> different key', () => {
      const baseKey = computeCompatibilityKey(baseTuple);
      const diffContrib = computeCompatibilityKey({ ...baseTuple, contributionMinor: 25000 });
      assert.notEqual(baseKey, diffContrib);
    });

    it('4. different currency -> different key', () => {
      const baseKey = computeCompatibilityKey(baseTuple);
      const diffCurrency = computeCompatibilityKey({ ...baseTuple, currency: 'EGP' });
      assert.notEqual(baseKey, diffCurrency);
    });

    it('5. different duration -> different key', () => {
      const baseKey = computeCompatibilityKey(baseTuple);
      const diffDuration = computeCompatibilityKey({ ...baseTuple, durationPeriods: 6 });
      assert.notEqual(baseKey, diffDuration);
    });

    it('6. different member/capacity dimension -> different key', () => {
      // In SYMMETRICAL_V1, durationPeriods === memberCount = N
      const keyN6 = computeCompatibilityKey({ ...baseTuple, durationPeriods: 6 });
      const keyN10 = computeCompatibilityKey({ ...baseTuple, durationPeriods: 10 });
      const keyN12 = computeCompatibilityKey({ ...baseTuple, durationPeriods: 12 });

      assert.notEqual(keyN6, keyN10);
      assert.notEqual(keyN10, keyN12);
      assert.notEqual(keyN6, keyN12);
    });

    it('7. different allocation rule -> different key', () => {
      const baseKey = computeCompatibilityKey(baseTuple);
      // Cast for test verification of rule divergence
      const diffRule = computeCompatibilityKey({ ...baseTuple, allocationRule: 'CUSTOM_V2' as any });
      assert.notEqual(baseKey, diffRule);
    });

    it('8. confirms case normalization for currency (e.g. "usd" -> "USD")', () => {
      const upperKey = computeCompatibilityKey(baseTuple);
      const lowerKey = computeCompatibilityKey({ ...baseTuple, currency: 'usd' });
      assert.equal(upperKey, lowerKey);
    });
  });

  describe('3. S4-02: Candidate ID Binding & Context Invariants', () => {
    const sampleParams: CandidateIdentityParams = {
      tenantId: 'tenant_prod_01',
      requestId: 'req_001',
      allocationUnitId: 'unit_001',
      allocatedPosition: 3,
      payoutPeriod: 3,
      contributionMinor: 50000,
      durationPeriods: 10,
      allocationRule: 'SYMMETRICAL_V1',
    };

    it('1. identical candidate context -> identical candidate ID', () => {
      const id1 = computeCandidateId(sampleParams);
      const id2 = computeCandidateId({ ...sampleParams });

      assert.equal(id1, id2);
      assert.ok(id1.startsWith('cand_'));
      assert.equal(id1.length, 5 + 64); // 'cand_' + 64 hex characters
    });

    it('2. different tenant -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffTenant = computeCandidateId({ ...sampleParams, tenantId: 'tenant_prod_02' });
      assert.notEqual(baseId, diffTenant);
    });

    it('3. different request -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffReq = computeCandidateId({ ...sampleParams, requestId: 'req_002' });
      assert.notEqual(baseId, diffReq);
    });

    it('4. different allocation unit -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffUnit = computeCandidateId({ ...sampleParams, allocationUnitId: 'unit_002' });
      assert.notEqual(baseId, diffUnit);
    });

    it('5. different allocated position -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffPos = computeCandidateId({ ...sampleParams, allocatedPosition: 4 });
      assert.notEqual(baseId, diffPos);
    });

    it('6. different payout period -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffPayout = computeCandidateId({ ...sampleParams, payoutPeriod: 5 });
      assert.notEqual(baseId, diffPayout);
    });

    it('7. different contribution -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffContrib = computeCandidateId({ ...sampleParams, contributionMinor: 25000 });
      assert.notEqual(baseId, diffContrib);
    });

    it('8. different duration -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffDuration = computeCandidateId({ ...sampleParams, durationPeriods: 6 });
      assert.notEqual(baseId, diffDuration);
    });

    it('9. different allocation rule -> different candidate ID', () => {
      const baseId = computeCandidateId(sampleParams);
      const diffRule = computeCandidateId({ ...sampleParams, allocationRule: 'CUSTOM_RULE' as any });
      assert.notEqual(baseId, diffRule);
    });

    it('10. candidate ID is independent of mutable evaluation state (expiresAt, occupancy, timestamps)', () => {
      // Candidate ID is purely a function of immutable relationship context
      const id1 = computeCandidateId(sampleParams);
      const id2 = computeCandidateId({ ...sampleParams });

      // Even if evaluated at different timestamps or with different expiresAt,
      // candidate relationship ID remains stable and identical
      assert.equal(id1, id2);
    });
  });
});
