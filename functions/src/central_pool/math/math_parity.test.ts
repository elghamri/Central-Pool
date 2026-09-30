/**
 * Central Pool Mathematical Kernel - Frozen Go Parity & Contract Guardrail Test Suite
 * Reference Baseline: services/cooperative-service/allocation_mathematical_kernel.go
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  calculateMirrorPeriod,
  calculateTotalEntitlement,
  calculateTotalPot,
  calculateMemberPrimaryPeriod,
  calculateDisbursementSplit,
  generateCycleScheduleMatrix,
  validateAllocationInvariants,
} from './allocation_math';
import {
  validateMemberCount,
  validatePeriodicContribution,
  validateSafeMultiplication,
  validateSymmetricalEvenEntitlement,
} from './math_validation';
import {
  GOLDEN_VECTORS_STANDARD,
  GOLDEN_VECTORS_EDGE,
  GOLDEN_VECTORS_INVALID,
} from './golden_vectors';
import {
  InvalidMemberCountError,
  InvalidPeriodicContributionError,
  OddEntitlementRejectionError,
  SafeIntegerOverflowError,
} from './math_errors';

describe('CENTRAL POOL — Suite A: Frozen Go Parity (34 Vectors)', () => {
  // 1. Standard 30 Valid Vectors (GV-01 .. GV-30)
  for (const v of GOLDEN_VECTORS_STANDARD) {
    it(`[${v.id}] Parity Check N=${v.N}, C=${v.C} minor units (FROZEN_GO)`, () => {
      // Entitlement Assertion
      const actualE = calculateTotalEntitlement(v.C, v.N);
      assert.equal(actualE, v.E, `Entitlement E for ${v.id} must match Go baseline exactly`);

      // Total Pot Assertion
      const actualPot = calculateTotalPot(v.C, v.N);
      assert.equal(actualPot, v.totalPot, `Total pot for ${v.id} must match Go baseline exactly`);

      // Construct positions roster [1..N]
      const memberPositions: Record<string, number> = {};
      for (let pos = 1; pos <= v.N; pos++) {
        memberPositions[`mem-${pos}`] = pos;
      }

      // Generate complete matrix
      const matrix = generateCycleScheduleMatrix(
        `cycle-${v.id}`,
        'tenant-parity-01',
        v.N,
        v.C,
        memberPositions
      );

      // Verify invariant verification flag
      assert.equal(matrix.invariantsVerified, true, 'Matrix invariants must be verified');
      assert.equal(matrix.totalPotMinor, v.totalPot, 'Matrix total pot must match');

      // Verify each period's scheduled amount equals E
      for (const period of matrix.periods) {
        assert.equal(
          period.scheduledMinor,
          v.E,
          `Period ${period.periodIndex} scheduled total must equal entitlement E (${v.E})`
        );
      }

      // Verify center period if odd N
      if (v.centerPeriod !== null) {
        const centerPeriodSummary = matrix.periods[v.centerPeriod - 1];
        const centerSlots = centerPeriodSummary.slots.filter((s) => s.isAggregatedCenter);
        assert.equal(centerSlots.length, 1, 'Odd N must produce exactly 1 aggregated center slot');
        assert.equal(
          centerSlots[0].amountMinor,
          v.centerPayout,
          'Center slot payout must equal full entitlement E'
        );
      } else {
        // Even N: every period must have exactly 2 standard split slots
        for (const period of matrix.periods) {
          assert.equal(period.slots.length, 2, 'Even N must produce exactly 2 split slots per period');
          for (const slot of period.slots) {
            assert.equal(
              slot.amountMinor,
              v.splitPayout,
              `Slot payout must equal 50% split (${v.splitPayout})`
            );
          }
        }
      }
    });
  }

  // 2. Edge Vector 1: GV-EDGE-01 (N=4, C=2)
  const gvEdge01 = GOLDEN_VECTORS_EDGE.find((v) => v.id === 'GV-EDGE-01')!;
  it(`[${gvEdge01.id}] Edge Parity Check N=${gvEdge01.N}, C=${gvEdge01.C} (FROZEN_GO)`, () => {
    const actualE = calculateTotalEntitlement(gvEdge01.C, gvEdge01.N);
    assert.equal(actualE, gvEdge01.E);

    const actualPot = calculateTotalPot(gvEdge01.C, gvEdge01.N);
    assert.equal(actualPot, gvEdge01.totalPot);

    const memberPositions: Record<string, number> = {
      'mem-1': 1,
      'mem-2': 2,
      'mem-3': 3,
      'mem-4': 4,
    };

    const matrix = generateCycleScheduleMatrix(
      'cycle-edge-01',
      'tenant-parity-01',
      gvEdge01.N,
      gvEdge01.C,
      memberPositions
    );

    assert.equal(matrix.invariantsVerified, true);
    for (const period of matrix.periods) {
      assert.equal(period.scheduledMinor, gvEdge01.E);
    }
  });

  // 3. Invalid Native Vector 1: GV-INV-02 (N=1)
  const gvInv02 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-02')!;
  it(`[${gvInv02.id}] Invalid Member Count N=1 Rejection (FROZEN_GO)`, () => {
    assert.throws(
      () => validateMemberCount(gvInv02.N),
      (err: any) => err instanceof InvalidMemberCountError && err.code === 'INVALID_MEMBER_COUNT'
    );
  });

  // 4. Invalid Native Vector 2: GV-INV-04 (C=0)
  const gvInv04 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-04')!;
  it(`[${gvInv04.id}] Zero Contribution C=0 Rejection (FROZEN_GO)`, () => {
    assert.throws(
      () => validatePeriodicContribution(gvInv04.C),
      (err: any) => err instanceof InvalidPeriodicContributionError && err.code === 'INVALID_PERIODIC_CONTRIBUTION'
    );
  });

  // 5. Invalid Native Vector 3: GV-INV-05 (C=-500)
  const gvInv05 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-05')!;
  it(`[${gvInv05.id}] Negative Contribution C=-500 Rejection (FROZEN_GO)`, () => {
    assert.throws(
      () => validatePeriodicContribution(gvInv05.C),
      (err: any) => err instanceof InvalidPeriodicContributionError && err.code === 'INVALID_PERIODIC_CONTRIBUTION'
    );
  });
});

describe('CENTRAL POOL — Suite B: Central Pool Contract Guardrails (4 Vectors)', () => {
  // 1. Edge Vector 2: GV-EDGE-02 (Maximum Safe Contribution for N=12)
  const gvEdge02 = GOLDEN_VECTORS_EDGE.find((v) => v.id === 'GV-EDGE-02')!;
  it(`[${gvEdge02.id}] Maximum Safe Contribution N=${gvEdge02.N}, C=${gvEdge02.C} (CONTRACT_DERIVED)`, () => {
    const actualE = calculateTotalEntitlement(gvEdge02.C, gvEdge02.N);
    assert.equal(actualE, gvEdge02.E);
    assert.equal(Number.isSafeInteger(actualE), true);

    const actualPot = calculateTotalPot(gvEdge02.C, gvEdge02.N);
    assert.equal(actualPot, gvEdge02.totalPot);
    assert.equal(Number.isSafeInteger(actualPot), true);
    assert.ok(actualPot <= Number.MAX_SAFE_INTEGER);

    const split = calculateDisbursementSplit(actualE, 'STANDARD_SPLIT', true);
    assert.equal(split.primaryAmount, gvEdge02.splitPayout);
    assert.equal(split.mirrorAmount, gvEdge02.splitPayout);
  });

  // 2. Invalid Vector 1: GV-INV-01 (Odd Entitlement Rejection: N=3, C=1 => E=3)
  const gvInv01 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-01')!;
  it(`[${gvInv01.id}] Intentional Divergence: Odd Entitlement E=3 Strict 50/50 Rejection (CONTRACT_DERIVED)`, () => {
    const E = calculateTotalEntitlement(gvInv01.C, gvInv01.N);
    assert.equal(E, 3);

    // In Go, this produces a floor/remainder split (1 and 2).
    // In Central Pool, strict 50/50 integer money invariant rejects this configuration.
    assert.throws(
      () => calculateDisbursementSplit(E, 'STANDARD_SPLIT', true),
      (err: any) => err instanceof OddEntitlementRejectionError && err.code === 'ODD_ENTITLEMENT_REJECTED'
    );
  });

  // 3. Invalid Vector 2: GV-INV-03 (Overflow Duration Periods N=13)
  const gvInv03 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-03')!;
  it(`[${gvInv03.id}] Upper Bound Duration Rejection N=13 (CONTRACT_DERIVED)`, () => {
    assert.throws(
      () => validateMemberCount(gvInv03.N, true),
      (err: any) => err instanceof InvalidMemberCountError && err.code === 'INVALID_MEMBER_COUNT'
    );
  });

  // 4. Invalid Vector 3: GV-INV-06 (Unsafe Multiplication Overflow N=12, C=10^15)
  const gvInv06 = GOLDEN_VECTORS_INVALID.find((v) => v.id === 'GV-INV-06')!;
  it(`[${gvInv06.id}] Multiplication Overflow Pre-Check Rejection (CONTRACT_DERIVED)`, () => {
    // Must be rejected BEFORE performing unsafe arithmetic
    assert.throws(
      () => validatePeriodicContribution(gvInv06.C, gvInv06.N),
      (err: any) => err instanceof SafeIntegerOverflowError && err.code === 'SAFE_INTEGER_OVERFLOW'
    );
  });
});
