/**
 * Central Pool Step 6: Financial Validation & Pure Math Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import {
  validateSafeMinorAmount,
  validateFinancialCurrency,
  calculateFinancialTotalEntitlement,
  calculateFinancialTotalPoolPot,
  calculateSymmetricalDisbursementSplits,
  validateFinancialObligation,
  validateContributionSchedule,
  validateContributionEvent,
  validatePayoutEntitlement,
  validateAccountingJournalEntry,
  FinancialObligation,
  ContributionSchedule,
  ContributionEvent,
  PayoutEntitlement,
  AccountingJournalEntry,
  ACCOUNT_CODES,
  OddEntitlementError,
  InvalidMinorAmountError,
  InvalidObligationError,
  InvalidContributionScheduleError,
  InvalidContributionEventError,
  InvalidPayoutEntitlementError,
  JournalEntryUnbalancedError,
  PeriodOutOfBoundsError,
} from '../index';
import { MissingTenantIdError, MissingMemberUidError, InvalidCurrencyError } from '../../domain/domain_errors';

describe('CENTRAL POOL — Step 6: Financial Validation & Pure Math', () => {
  describe('Minor Unit Safety & Validation', () => {
    it('accepts safe positive integer amounts', () => {
      assert.doesNotThrow(() => validateSafeMinorAmount(100, 'testAmount'));
      assert.doesNotThrow(() => validateSafeMinorAmount(50000, 'testAmount'));
      assert.doesNotThrow(() => validateSafeMinorAmount(Number.MAX_SAFE_INTEGER, 'testAmount'));
    });

    it('accepts zero only when explicitly allowed', () => {
      assert.throws(() => validateSafeMinorAmount(0, 'testAmount', false), InvalidMinorAmountError);
      assert.doesNotThrow(() => validateSafeMinorAmount(0, 'testAmount', true));
    });

    it('rejects floats, negatives, NaN, Infinity, and non-numbers', () => {
      assert.throws(() => validateSafeMinorAmount(10.5, 'testAmount'), InvalidMinorAmountError);
      assert.throws(() => validateSafeMinorAmount(-50, 'testAmount'), InvalidMinorAmountError);
      assert.throws(() => validateSafeMinorAmount(NaN, 'testAmount'), InvalidMinorAmountError);
      assert.throws(() => validateSafeMinorAmount(Infinity, 'testAmount'), InvalidMinorAmountError);
      assert.throws(() => validateSafeMinorAmount('100', 'testAmount'), InvalidMinorAmountError);
      assert.throws(() => validateSafeMinorAmount(null, 'testAmount'), InvalidMinorAmountError);
    });

    it('validates ISO 4217 currencies', () => {
      assert.doesNotThrow(() => validateFinancialCurrency('USD'));
      assert.doesNotThrow(() => validateFinancialCurrency('EUR'));
      assert.doesNotThrow(() => validateFinancialCurrency('SAR'));
      assert.throws(() => validateFinancialCurrency('usd'), InvalidCurrencyError);
      assert.throws(() => validateFinancialCurrency('US'), InvalidCurrencyError);
      assert.throws(() => validateFinancialCurrency(''), InvalidCurrencyError);
    });
  });

  describe('Entitlement & Pot Mathematical Formulas', () => {
    it('calculates total entitlement E = N * C correctly', () => {
      const e = calculateFinancialTotalEntitlement(6, 50000);
      assert.equal(e, 300000);
    });

    it('calculates total pool pot = N^2 * C correctly', () => {
      const pot = calculateFinancialTotalPoolPot(6, 50000);
      assert.equal(pot, 1800000);
      assert.equal(pot, 6 * 300000);
    });

    it('rejects odd entitlement under Central Pool even-split guardrail', () => {
      assert.throws(() => calculateFinancialTotalEntitlement(3, 1), OddEntitlementError);
      assert.throws(() => calculateFinancialTotalEntitlement(5, 3), OddEntitlementError);
    });

    it('enforces duration range in [2..12]', () => {
      assert.throws(() => calculateFinancialTotalEntitlement(1, 1000), InvalidObligationError);
      assert.throws(() => calculateFinancialTotalEntitlement(13, 1000), InvalidObligationError);
      assert.throws(() => calculateFinancialTotalPoolPot(0, 1000), InvalidObligationError);
      assert.throws(() => calculateFinancialTotalPoolPot(15, 1000), InvalidObligationError);
    });
  });

  describe('SYMMETRICAL_V1 Disbursement Splits Calculation', () => {
    it('calculates splits for even duration N=6 correctly (all pairs 50%/50%)', () => {
      const totalEntitlement = 300000;
      const duration = 6;

      // Pos 1 & 2 -> P1=1, P2=6
      const splitsPos1 = calculateSymmetricalDisbursementSplits(1, duration, totalEntitlement);
      assert.equal(splitsPos1.length, 2);
      assert.deepEqual(splitsPos1, [
        { periodNumber: 1, amountMinor: 150000, basisPoints: 5000, isCenter: false },
        { periodNumber: 6, amountMinor: 150000, basisPoints: 5000, isCenter: false },
      ]);

      const splitsPos2 = calculateSymmetricalDisbursementSplits(2, duration, totalEntitlement);
      assert.deepEqual(splitsPos2, splitsPos1);

      // Pos 3 & 4 -> P1=2, P2=5
      const splitsPos3 = calculateSymmetricalDisbursementSplits(3, duration, totalEntitlement);
      assert.deepEqual(splitsPos3, [
        { periodNumber: 2, amountMinor: 150000, basisPoints: 5000, isCenter: false },
        { periodNumber: 5, amountMinor: 150000, basisPoints: 5000, isCenter: false },
      ]);

      // Pos 5 & 6 -> P1=3, P2=4
      const splitsPos5 = calculateSymmetricalDisbursementSplits(5, duration, totalEntitlement);
      assert.deepEqual(splitsPos5, [
        { periodNumber: 3, amountMinor: 150000, basisPoints: 5000, isCenter: false },
        { periodNumber: 4, amountMinor: 150000, basisPoints: 5000, isCenter: false },
      ]);
    });

    it('calculates splits for odd duration N=5 correctly with single center position 100%', () => {
      const totalEntitlement = 100000; // N=5, C=20000
      const duration = 5;

      // Pos 1 & 2 -> Pair 1: P1=1, P2=5
      const splitsPos1 = calculateSymmetricalDisbursementSplits(1, duration, totalEntitlement);
      assert.deepEqual(splitsPos1, [
        { periodNumber: 1, amountMinor: 50000, basisPoints: 5000, isCenter: false },
        { periodNumber: 5, amountMinor: 50000, basisPoints: 5000, isCenter: false },
      ]);
      const splitsPos2 = calculateSymmetricalDisbursementSplits(2, duration, totalEntitlement);
      assert.deepEqual(splitsPos2, splitsPos1);

      // Pos 3 -> Center (M=3): P1=3, P2=3 -> 100% single disbursement
      const splitsPos3 = calculateSymmetricalDisbursementSplits(3, duration, totalEntitlement);
      assert.deepEqual(splitsPos3, [
        { periodNumber: 3, amountMinor: 100000, basisPoints: 10000, isCenter: true },
      ]);

      // Pos 4 & 5 -> Pair 2: P1=2, P2=4
      const splitsPos4 = calculateSymmetricalDisbursementSplits(4, duration, totalEntitlement);
      assert.deepEqual(splitsPos4, [
        { periodNumber: 2, amountMinor: 50000, basisPoints: 5000, isCenter: false },
        { periodNumber: 4, amountMinor: 50000, basisPoints: 5000, isCenter: false },
      ]);
      const splitsPos5 = calculateSymmetricalDisbursementSplits(5, duration, totalEntitlement);
      assert.deepEqual(splitsPos5, splitsPos4);
    });

    it('rejects out of bounds position numbers', () => {
      assert.throws(() => calculateSymmetricalDisbursementSplits(0, 6, 300000), PeriodOutOfBoundsError);
      assert.throws(() => calculateSymmetricalDisbursementSplits(7, 6, 300000), PeriodOutOfBoundsError);
    });
  });

  describe('Entity Invariant Validators', () => {
    it('validates a correct FinancialObligation', () => {
      const ob: FinancialObligation = {
        obligationId: 'ob_123',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        allocationUnitId: 'unit_01',
        allocationId: 'alloc_01',
        positionNumber: 1,
        totalObligationMinor: 300000,
        contributionMinor: 50000,
        totalPeriods: 6,
        fulfilledAmountMinor: 0,
        currency: 'USD',
        status: 'ACTIVE',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      };
      assert.doesNotThrow(() => validateFinancialObligation(ob));
    });

    it('rejects FinancialObligation with total mismatch or invalid fulfilled amount', () => {
      const invalidOb: FinancialObligation = {
        obligationId: 'ob_123',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        allocationUnitId: 'unit_01',
        allocationId: 'alloc_01',
        positionNumber: 1,
        totalObligationMinor: 350000, // Should be 300000 (6 * 50000)
        contributionMinor: 50000,
        totalPeriods: 6,
        fulfilledAmountMinor: 0,
        currency: 'USD',
        status: 'ACTIVE',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      };
      assert.throws(() => validateFinancialObligation(invalidOb), InvalidObligationError);

      const overfulfilled: FinancialObligation = {
        ...invalidOb,
        totalObligationMinor: 300000,
        fulfilledAmountMinor: 350000, // exceeds total
      };
      assert.throws(() => validateFinancialObligation(overfulfilled), InvalidObligationError);
    });

    it('validates a correct ContributionEvent (with and without optional journalEntryId)', () => {
      const eventWithoutJournal: ContributionEvent = {
        contributionEventId: 'ce_123',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        obligationId: 'ob_123',
        allocationUnitId: 'unit_01',
        periodNumber: 1,
        amountMinor: 50000,
        currency: 'USD',
        recordedAt: new Date().toISOString(),
        idempotencyId: 'idemp_01',
      };
      assert.doesNotThrow(() => validateContributionEvent(eventWithoutJournal));

      const eventWithJournal: ContributionEvent = {
        ...eventWithoutJournal,
        journalEntryId: 'je_123',
      };
      assert.doesNotThrow(() => validateContributionEvent(eventWithJournal));
    });

    it('rejects ContributionEvent with invalid periodNumber or amount', () => {
      const invalidEvent: ContributionEvent = {
        contributionEventId: 'ce_123',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        obligationId: 'ob_123',
        allocationUnitId: 'unit_01',
        periodNumber: 0, // Invalid: must be >= 1
        amountMinor: 50000,
        currency: 'USD',
        recordedAt: new Date().toISOString(),
        idempotencyId: 'idemp_01',
      };
      assert.throws(() => validateContributionEvent(invalidEvent), InvalidContributionEventError);
    });

    it('validates a balanced double-entry AccountingJournalEntry', () => {

      const journal: AccountingJournalEntry = {
        journalEntryId: 'je_123',
        tenantId: 'tenant_01',
        entryType: 'OBLIGATION_RECOGNITION',
        referenceType: 'CONFIRMED_ALLOCATION',
        referenceId: 'alloc_01',
        lines: [
          {
            accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
            accountName: 'Member Obligation Receivable',
            debitMinor: 300000,
            creditMinor: 0,
          },
          {
            accountCode: ACCOUNT_CODES.POOL_OBLIGATION_RESERVE,
            accountName: 'Central Pool Obligation Reserve',
            debitMinor: 0,
            creditMinor: 300000,
          },
        ],
        totalDebitMinor: 300000,
        totalCreditMinor: 300000,
        currency: 'USD',
        postedAt: new Date().toISOString(),
        idempotencyId: 'idemp_je_123',
      };
      assert.doesNotThrow(() => validateAccountingJournalEntry(journal));
    });

    it('rejects unbalanced journal entries', () => {
      const unbalanced: AccountingJournalEntry = {
        journalEntryId: 'je_123',
        tenantId: 'tenant_01',
        entryType: 'OBLIGATION_RECOGNITION',
        referenceType: 'CONFIRMED_ALLOCATION',
        referenceId: 'alloc_01',
        lines: [
          {
            accountCode: ACCOUNT_CODES.MEMBER_RECEIVABLE,
            accountName: 'Member Obligation Receivable',
            debitMinor: 300000,
            creditMinor: 0,
          },
          {
            accountCode: ACCOUNT_CODES.POOL_OBLIGATION_RESERVE,
            accountName: 'Central Pool Obligation Reserve',
            debitMinor: 0,
            creditMinor: 250000, // Unbalanced!
          },
        ],
        totalDebitMinor: 300000,
        totalCreditMinor: 250000,
        currency: 'USD',
        postedAt: new Date().toISOString(),
        idempotencyId: 'idemp_je_123',
      };
      assert.throws(() => validateAccountingJournalEntry(unbalanced), JournalEntryUnbalancedError);
    });
  });

  describe('Mathematical Kernel Parity Verification across all N in [2..12]', () => {
    it('matches Step 1 Mathematical Kernel across all durations N in [2..12] and all positions 1..N', () => {
      const contributionMinor = 10000;

      for (let n = 2; n <= 12; n++) {
        const totalEntitlement = calculateFinancialTotalEntitlement(n, contributionMinor);
        const totalPot = calculateFinancialTotalPoolPot(n, contributionMinor);

        // Prove E = N * C and Pot = N^2 * C = N * E
        assert.equal(totalEntitlement, n * contributionMinor);
        assert.equal(totalPot, n * n * contributionMinor);
        assert.equal(totalPot, n * totalEntitlement);

        for (let pos = 1; pos <= n; pos++) {
          const splits = calculateSymmetricalDisbursementSplits(pos, n, totalEntitlement);
          const splitSum = splits.reduce((acc, s) => acc + s.amountMinor, 0);
          const bpsSum = splits.reduce((acc, s) => acc + s.basisPoints, 0);

          assert.equal(splitSum, totalEntitlement, `Failed sum conservation for N=${n}, pos=${pos}`);
          assert.equal(bpsSum, 10000, `Failed bps conservation for N=${n}, pos=${pos}`);

          if (n % 2 !== 0 && pos === (n + 1) / 2) {
            assert.equal(splits.length, 1);
            assert.equal(splits[0].isCenter, true);
            assert.equal(splits[0].periodNumber, (n + 1) / 2);
            assert.equal(splits[0].amountMinor, totalEntitlement);
          } else {
            assert.equal(splits.length, 2);
            assert.equal(splits[0].isCenter, false);
            assert.equal(splits[1].isCenter, false);
            assert.equal(splits[0].amountMinor, totalEntitlement / 2);
            assert.equal(splits[1].amountMinor, totalEntitlement / 2);
          }
        }
      }
    });
  });

  describe('ContributionSchedule Lifecycle States Validation', () => {
    it('accepts SCHEDULED and RECORDED states only', () => {
      const validSchedule: ContributionSchedule = {
        scheduleId: 'cs_001',
        obligationId: 'ob_001',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        allocationUnitId: 'unit_001',
        totalPeriods: 2,
        periods: [
          { periodNumber: 1, scheduledAmountMinor: 50000, status: 'RECORDED', recordedAt: new Date().toISOString() },
          { periodNumber: 2, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      };
      assert.doesNotThrow(() => validateContributionSchedule(validSchedule));
    });

    it('rejects unratified schedule states', () => {
      const invalidSchedule: ContributionSchedule = {
        scheduleId: 'cs_001',
        obligationId: 'ob_001',
        tenantId: 'tenant_01',
        memberUid: 'usr_alice',
        allocationUnitId: 'unit_001',
        totalPeriods: 2,
        periods: [
          { periodNumber: 1, scheduledAmountMinor: 50000, status: 'UNRATIFIED_STATE' as any },
          { periodNumber: 2, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        version: 1,
      };
      assert.throws(() => validateContributionSchedule(invalidSchedule), InvalidContributionScheduleError);
    });
  });
});
