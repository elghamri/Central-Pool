/**
 * Central Pool Step 6: Obligation Generation Service Test Suite
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../confirmation/test/mock_firestore';
import {
  ObligationGenerationService,
} from '../index';
import {
  getFinancialObligationPath,
  getContributionSchedulePath,
  getPayoutEntitlementPath,
  getMemberObligationReceiptPath,
  getMemberPayoutEntitlementReceiptPath,
} from '../../domain/domain_paths';

describe('CENTRAL POOL — Step 6: Obligation Generation Service', () => {
  let mockDb: MockFirestore;
  let service: ObligationGenerationService;

  const tenantId = 'tenant_prod_01';
  const memberUid = 'usr_alice';
  const allocationId = 'alloc_001';
  const allocationUnitId = 'unit_001';
  const positionNumber = 1;
  const contributionMinor = 50000;
  const totalPeriods = 6;
  const currency = 'USD';
  const nowIso = '2026-09-09T12:00:00.000Z';

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new ObligationGenerationService(mockDb as any);
  });

  it('generates obligation, schedule, entitlement, and member projections atomically', async () => {
    const result = await service.generateObligation({
      tenantId,
      memberUid,
      allocationId,
      allocationUnitId,
      positionNumber,
      contributionMinor,
      totalPeriods,
      currency,
      nowIso,
    });

    assert.equal(result.isIdempotentReplay, false);
    assert.equal(result.obligation.totalObligationMinor, 300000);
    assert.equal(result.obligation.fulfilledAmountMinor, 0);
    assert.equal(result.obligation.status, 'ACTIVE');

    assert.equal(result.contributionSchedule.periods.length, 6);
    assert.equal(result.contributionSchedule.periods[0].status, 'SCHEDULED');

    assert.equal(result.payoutEntitlement.totalEntitlementMinor, 300000);
    assert.equal(result.payoutEntitlement.splits.length, 2);

    // Verify authoritative documents exist in mock Firestore
    const obPath = getFinancialObligationPath(result.obligation.obligationId);
    const csPath = getContributionSchedulePath(result.contributionSchedule.scheduleId);
    const pePath = getPayoutEntitlementPath(result.payoutEntitlement.payoutEntitlementId);
    const memberObPath = getMemberObligationReceiptPath(memberUid, result.obligation.obligationId);
    const memberPePath = getMemberPayoutEntitlementReceiptPath(memberUid, result.payoutEntitlement.payoutEntitlementId);

    assert.ok(mockDb.docs.has(obPath));
    assert.ok(mockDb.docs.has(csPath));
    assert.ok(mockDb.docs.has(pePath));
    assert.ok(mockDb.docs.has(memberObPath));
    assert.ok(mockDb.docs.has(memberPePath));

    // Verify member projection metadata
    const memberObDoc = mockDb.docs.get(memberObPath)?.data;
    assert.equal(memberObDoc?.isProjection, true);
    assert.equal(memberObDoc?.classification, 'DERIVED_PROJECTION');
  });

  it('handles idempotent replays gracefully without modifying state', async () => {
    const firstResult = await service.generateObligation({
      tenantId,
      memberUid,
      allocationId,
      allocationUnitId,
      positionNumber,
      contributionMinor,
      totalPeriods,
      currency,
      nowIso,
    });
    assert.equal(firstResult.isIdempotentReplay, false);

    const secondResult = await service.generateObligation({
      tenantId,
      memberUid,
      allocationId,
      allocationUnitId,
      positionNumber,
      contributionMinor,
      totalPeriods,
      currency,
      nowIso,
    });
    assert.equal(secondResult.isIdempotentReplay, true);
    assert.equal(secondResult.obligation.obligationId, firstResult.obligation.obligationId);
    assert.equal(secondResult.contributionSchedule.scheduleId, firstResult.contributionSchedule.scheduleId);
    assert.equal(secondResult.payoutEntitlement.payoutEntitlementId, firstResult.payoutEntitlement.payoutEntitlementId);
  });
});

