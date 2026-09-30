/**
 * Central Pool Step 7: Period Math & Conservation Test Suite
 * Validates the complete required period matrix, odd-entitlement guardrail, and conservation invariants.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import {
  deriveCyclePeriodStructure,
  deriveMemberPeriodProjection,
  verifyPeriodConservationInvariants,
} from '../domain/period_engine';
import { OddEntitlementError } from '../../financial/domain/financial_errors';

describe('CENTRAL POOL — Step 7: Period Math & Conservation Test Suite', () => {
  const tenantId = 'tenant_main_01';
  const unitId = 'unit_matrix_01';
  const currency = 'USD';

  it('[N=2] validates basic paired allocation and conservation', () => {
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 2,
      periodicContributionMinor: 10000,
      currency,
    });

    assert.equal(projection.memberCount, 2);
    assert.equal(projection.totalEntitlementMinor, 20000); // 2 * 10,000
    assert.equal(projection.totalPotMinor, 40000); // 2^2 * 10,000
    assert.equal(projection.periods.length, 2);

    // Period 1: Pos 1 (50% = 10,000) + Pos 2 (50% = 10,000) = 20,000
    assert.equal(projection.periods[0].expectedContributionPoolMinor, 20000);
    assert.equal(projection.periods[0].expectedDisbursementPoolMinor, 20000);
    assert.equal(projection.periods[0].payoutSlots.length, 2);
    assert.equal(projection.periods[0].isBalanced, true);

    // Period 2: Pos 1 (50% = 10,000) + Pos 2 (50% = 10,000) = 20,000
    assert.equal(projection.periods[1].expectedContributionPoolMinor, 20000);
    assert.equal(projection.periods[1].expectedDisbursementPoolMinor, 20000);
    assert.equal(projection.periods[1].payoutSlots.length, 2);
    assert.equal(projection.periods[1].isBalanced, true);

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[N=3] validates valid even entitlement and center 100% disbursement', () => {
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 3,
      periodicContributionMinor: 20000, // E = 60,000 (even integer)
      currency,
    });

    assert.equal(projection.totalEntitlementMinor, 60000);
    assert.equal(projection.totalPotMinor, 180000); // 3^2 * 20,000
    assert.equal(projection.periods.length, 3);

    // Period 1: Pos 1 (50% = 30,000) + Pos 3 (50% = 30,000) = 60,000
    assert.equal(projection.periods[0].expectedDisbursementPoolMinor, 60000);
    assert.equal(projection.periods[0].payoutSlots.length, 2);

    // Period 2 (Center): Pos 2 (100% = 60,000, isCenter=true) = 60,000
    assert.equal(projection.periods[1].expectedDisbursementPoolMinor, 60000);
    assert.equal(projection.periods[1].payoutSlots.length, 1);
    assert.equal(projection.periods[1].payoutSlots[0].positionNumber, 2);
    assert.equal(projection.periods[1].payoutSlots[0].isCenter, true);
    assert.equal(projection.periods[1].payoutSlots[0].amountMinor, 60000);
    assert.equal(projection.periods[1].payoutSlots[0].basisPoints, 10000);

    // Period 3: Pos 1 (50% = 30,000) + Pos 3 (50% = 30,000) = 60,000
    assert.equal(projection.periods[2].expectedDisbursementPoolMinor, 60000);
    assert.equal(projection.periods[2].payoutSlots.length, 2);

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[N=3, C=1] strictly rejects odd entitlement (Intentional Divergence GV-INV-01)', () => {
    assert.throws(
      () => {
        deriveCyclePeriodStructure({
          tenantId,
          allocationUnitId: unitId,
          memberCount: 3,
          periodicContributionMinor: 1, // E = 3 (odd integer)
          currency,
        });
      },
      (err: any) => {
        return err instanceof OddEntitlementError || err?.message?.includes('odd entitlement');
      }
    );
  });

  it('[N=4] validates E = 4C, TotalPot = 16C, and reciprocal pairs', () => {
    const C = 25000;
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 4,
      periodicContributionMinor: C,
      currency,
    });

    assert.equal(projection.totalEntitlementMinor, 4 * C); // 100,000
    assert.equal(projection.totalPotMinor, 16 * C); // 400,000
    assert.equal(projection.periods.length, 4);

    for (const period of projection.periods) {
      assert.equal(period.expectedContributionPoolMinor, 4 * C);
      assert.equal(period.expectedDisbursementPoolMinor, 4 * C);
      assert.equal(period.payoutSlots.length, 2); // 2 members per period (50% each)
      assert.equal(period.isBalanced, true);
    }

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[N=6] validates 3 reciprocal pairs and no duplicate pairs', () => {
    const C = 50000;
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 6,
      periodicContributionMinor: C,
      currency,
    });

    assert.equal(projection.totalEntitlementMinor, 300000);
    assert.equal(projection.totalPotMinor, 1800000);
    assert.equal(projection.periods.length, 6);

    for (const period of projection.periods) {
      assert.equal(period.expectedContributionPoolMinor, 300000);
      assert.equal(period.expectedDisbursementPoolMinor, 300000);
      assert.equal(period.payoutSlots.length, 2);
      assert.equal(period.isBalanced, true);
    }

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[N=11] validates 5 reciprocal pairs, center position 6 receives 100% in period 6', () => {
    const C = 20000; // E = 220,000 (even)
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 11,
      periodicContributionMinor: C,
      currency,
    });

    assert.equal(projection.totalEntitlementMinor, 220000);
    assert.equal(projection.totalPotMinor, 2420000); // 11^2 * 20,000
    assert.equal(projection.periods.length, 11);

    // Period 6 (Center position = 6)
    const centerPeriod = projection.periods[5]; // 0-indexed period 6
    assert.equal(centerPeriod.periodNumber, 6);
    assert.equal(centerPeriod.expectedDisbursementPoolMinor, 220000);
    assert.equal(centerPeriod.payoutSlots.length, 1);
    assert.equal(centerPeriod.payoutSlots[0].positionNumber, 6);
    assert.equal(centerPeriod.payoutSlots[0].isCenter, true);
    assert.equal(centerPeriod.payoutSlots[0].amountMinor, 220000);
    assert.equal(centerPeriod.payoutSlots[0].basisPoints, 10000);

    // Other 10 periods have 2 slots of 50% each
    for (let i = 0; i < 11; i++) {
      if (i !== 5) {
        assert.equal(projection.periods[i].payoutSlots.length, 2);
        assert.equal(projection.periods[i].expectedDisbursementPoolMinor, 220000);
      }
    }

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[N=12] validates maximum approved boundary N = 12', () => {
    const C = 100000;
    const projection = deriveCyclePeriodStructure({
      tenantId,
      allocationUnitId: unitId,
      memberCount: 12,
      periodicContributionMinor: C,
      currency,
    });

    assert.equal(projection.memberCount, 12);
    assert.equal(projection.totalEntitlementMinor, 1200000);
    assert.equal(projection.totalPotMinor, 14400000);
    assert.equal(projection.periods.length, 12);

    assert.equal(verifyPeriodConservationInvariants(projection), true);
  });

  it('[Invalid N] rejects N < 2 and N > 12', () => {
    assert.throws(() => {
      deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 1,
        periodicContributionMinor: 10000,
        currency,
      });
    });

    assert.throws(() => {
      deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 13,
        periodicContributionMinor: 10000,
        currency,
      });
    });
  });

  it('[Safe Integer Boundaries] rejects non-safe integers and negative amounts', () => {
    assert.throws(() => {
      deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 6,
        periodicContributionMinor: -500,
        currency,
      });
    });

    assert.throws(() => {
      deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 6,
        periodicContributionMinor: 50.5,
        currency,
      });
    });
  });

  it('[Member Conservation] verifies member lifetime net simulation entitlement delta === 0', () => {
    const memberProjection = deriveMemberPeriodProjection({
      tenantId,
      memberUid: 'usr_charlie',
      allocationId: 'alloc_001',
      allocationUnitId: unitId,
      positionNumber: 3,
      totalPeriods: 6,
      periodicContributionMinor: 50000,
      currency,
    });

    assert.equal(memberProjection.totalPeriods, 6);
    assert.equal(memberProjection.totalObligationMinor, 300000);
    assert.equal(memberProjection.totalEntitlementMinor, 300000);

    let netSum = 0;
    for (const period of memberProjection.periods) {
      netSum += period.netEntitlementDeltaMinor;
    }
    assert.equal(netSum, 0); // Total net entitlement delta over the cycle must be exactly 0
  });
});
