/**
 * Central Pool Step 7: Period Engine Pure Derivation Test Suite
 * Tests deterministic period generation, 1..N numbering, permutation invariance, and immutability.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import {
  deriveCyclePeriodStructure,
  deriveMemberPeriodProjection,
} from '../domain/period_engine';

describe('CENTRAL POOL — Step 7: Period Engine Pure Derivation', () => {
  const tenantId = 'tenant_pure_01';
  const unitId = 'unit_pure_01';
  const memberUid = 'usr_alice';
  const allocationId = 'alloc_alice_01';
  const currency = 'USD';
  const fixedNowIso = '2026-09-09T12:00:00.000Z';

  it('generates 1..N deterministic period numbering with DERIVED_PROJECTION classification', () => {
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 5,
      periodicContributionMinor: 20000,
      currency,
      nowIso: fixedNowIso,
    });

    assert.equal(projection.isProjection, true);
    assert.equal(projection.classification, 'DERIVED_PROJECTION');
    assert.equal(projection.generatedAt, fixedNowIso);
    assert.equal(projection.periods.length, 5);

    // Verify 1..N numbering strictly
    for (let i = 0; i < 5; i++) {
      assert.equal(projection.periods[i].periodNumber, i + 1);
    }
  });

  it('guarantees permutation invariance on position assignments', () => {
    // Permutation 1
    const p1 = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 4,
      periodicContributionMinor: 10000,
      currency,
      positionMembers: { 1: 'usr_a', 2: 'usr_b', 3: 'usr_c', 4: 'usr_d' },
      nowIso: fixedNowIso,
    });

    // Permutation 2
    const p2 = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 4,
      periodicContributionMinor: 10000,
      currency,
      positionMembers: { 4: 'usr_d', 1: 'usr_a', 3: 'usr_c', 2: 'usr_b' },
      nowIso: fixedNowIso,
    });

    assert.deepEqual(p1, p2);
  });

  it('generates member-specific period timeline with combined contribution and payout details', () => {
    const memberProj = deriveMemberPeriodProjection({
      tenantId,
      memberUid,
      allocationId,
      allocationUnitId: unitId,
      positionNumber: 1, // In N=6, Pos 1 primary is Period 1, mirror is Period 6
      totalPeriods: 6,
      periodicContributionMinor: 50000,
      currency,
      nowIso: fixedNowIso,
    });

    assert.equal(memberProj.isProjection, true);
    assert.equal(memberProj.classification, 'DERIVED_PROJECTION');
    assert.equal(memberProj.totalPeriods, 6);
    assert.equal(memberProj.periods.length, 6);

    // Period 1: Contribution 50k, Payout 150k (50%), Net Delta +100k
    const p1 = memberProj.periods[0];
    assert.equal(p1.periodNumber, 1);
    assert.equal(p1.contribution.dueAmountMinor, 50000);
    assert.equal(p1.contribution.status, 'SCHEDULED');
    assert.equal(p1.payout.isPayoutPeriod, true);
    assert.equal(p1.payout.entitledAmountMinor, 150000);
    assert.equal(p1.payout.basisPoints, 5000);
    assert.equal(p1.payout.mirrorPeriod, 6);
    assert.equal(p1.netEntitlementDeltaMinor, 100000);

    // Periods 2-5: Contribution 50k, Payout 0, Net Delta -50k
    for (let i = 1; i <= 4; i++) {
      const p = memberProj.periods[i];
      assert.equal(p.periodNumber, i + 1);
      assert.equal(p.contribution.dueAmountMinor, 50000);
      assert.equal(p.payout.isPayoutPeriod, false);
      assert.equal(p.payout.entitledAmountMinor, 0);
      assert.equal(p.netEntitlementDeltaMinor, -50000);
    }

    // Period 6: Contribution 50k, Payout 150k (50%), Net Delta +100k
    const p6 = memberProj.periods[5];
    assert.equal(p6.periodNumber, 6);
    assert.equal(p6.contribution.dueAmountMinor, 50000);
    assert.equal(p6.payout.isPayoutPeriod, true);
    assert.equal(p6.payout.entitledAmountMinor, 150000);
    assert.equal(p6.payout.basisPoints, 5000);
    assert.equal(p6.payout.mirrorPeriod, 1);
    assert.equal(p6.netEntitlementDeltaMinor, 100000);
  });

  it('guarantees complete immutability of input structures', () => {
    const input = {
      tenantId,
      allocationUnitId: unitId,
      memberCount: 4,
      periodicContributionMinor: 10000,
      currency,
      positionMembers: Object.freeze({ 1: 'usr_a', 2: 'usr_b', 3: 'usr_c', 4: 'usr_d' }),
    };

    const beforeJson = JSON.stringify(input);
    deriveCyclePeriodStructure(input);
    const afterJson = JSON.stringify(input);

    assert.equal(beforeJson, afterJson);
  });
});
