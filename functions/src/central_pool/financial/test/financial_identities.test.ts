/**
 * Central Pool Step 6: Financial Deterministic Identities Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import {
  computeObligationId,
  computeContributionScheduleId,
  computeContributionEventId,
  computePayoutEntitlementId,
  computeJournalEntryId,
} from '../identities';
import { MissingTenantIdError } from '../../domain/domain_errors';
import { InvalidObligationError } from '../domain/financial_errors';

describe('CENTRAL POOL — Step 6: Financial Deterministic Identities', () => {
  const tenantA = 'tenant_prod_01';
  const tenantB = 'tenant_prod_02';
  const allocationId = 'alloc_001';
  const obligationId = 'ob_001';

  it('generates deterministic obligation ID with ob_ prefix', () => {
    const id1 = computeObligationId(tenantA, allocationId);
    const id2 = computeObligationId(tenantA, allocationId);
    assert.match(id1, /^ob_[a-f0-9]{64}$/);
    assert.equal(id1, id2);
  });

  it('enforces tenant boundary isolation across all financial IDs', () => {
    const obA = computeObligationId(tenantA, allocationId);
    const obB = computeObligationId(tenantB, allocationId);
    assert.notEqual(obA, obB);

    const csA = computeContributionScheduleId(tenantA, obligationId);
    const csB = computeContributionScheduleId(tenantB, obligationId);
    assert.notEqual(csA, csB);

    const ceA = computeContributionEventId(tenantA, obligationId, 1);
    const ceB = computeContributionEventId(tenantB, obligationId, 1);
    assert.notEqual(ceA, ceB);

    const peA = computePayoutEntitlementId(tenantA, allocationId);
    const peB = computePayoutEntitlementId(tenantB, allocationId);
    assert.notEqual(peA, peB);

    const jeA = computeJournalEntryId(tenantA, 'OBLIGATION_RECOGNITION', allocationId);
    const jeB = computeJournalEntryId(tenantB, 'OBLIGATION_RECOGNITION', allocationId);
    assert.notEqual(jeA, jeB);
  });

  it('differentiates contribution event IDs across periods', () => {
    const ce1 = computeContributionEventId(tenantA, obligationId, 1);
    const ce2 = computeContributionEventId(tenantA, obligationId, 2);
    assert.notEqual(ce1, ce2);
  });

  it('rejects empty or missing parameters', () => {
    assert.throws(() => computeObligationId('', allocationId), MissingTenantIdError);
    assert.throws(() => computeObligationId(tenantA, ''), InvalidObligationError);
    assert.throws(() => computeContributionEventId(tenantA, obligationId, 0), InvalidObligationError);
    assert.throws(() => computeContributionEventId(tenantA, obligationId, -1), InvalidObligationError);
  });
});
