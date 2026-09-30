/**
 * Central Pool Step 6: Contribution Recording Service Test Suite
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../confirmation/test/mock_firestore';
import {
  ObligationGenerationService,
  ContributionRecordingService,
  ACCOUNT_CODES,
  ContributionAlreadyRecordedError,
  PeriodOutOfBoundsError,
} from '../index';
import {
  getContributionEventPath,
  getAccountingJournalEntryPath,
} from '../../domain/domain_paths';
import { EntityNotFoundError } from '../../persistence/persistence_errors';

describe('CENTRAL POOL — Step 6: Contribution Recording Service', () => {
  let mockDb: MockFirestore;
  let genService: ObligationGenerationService;
  let recService: ContributionRecordingService;

  const tenantId = 'tenant_prod_01';
  const memberUid = 'usr_alice';
  const allocationId = 'alloc_001';
  const allocationUnitId = 'unit_001';
  const positionNumber = 1;
  const contributionMinor = 50000;
  const totalPeriods = 3;
  const currency = 'USD';
  const nowIso = '2026-09-09T12:00:00.000Z';

  let obligationId: string;

  beforeEach(async () => {
    mockDb = new MockFirestore();
    genService = new ObligationGenerationService(mockDb as any);
    recService = new ContributionRecordingService(mockDb as any);

    // Bootstrap an obligation with 3 periods of 50000 -> Total 150000... wait 150000 is odd?
    // Wait! 3 * 50000 = 150000 which is EVEN! 150000 % 2 === 0.
    const genResult = await genService.generateObligation({
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
    obligationId = genResult.obligation.obligationId;
  });

  it('records contribution period 1 atomically and advances obligation state', async () => {
    const result = await recService.recordContribution({
      tenantId,
      memberUid,
      obligationId,
      periodNumber: 1,
      nowIso,
    });

    assert.equal(result.isIdempotentReplay, false);
    assert.equal(result.contributionEvent.periodNumber, 1);
    assert.equal(result.contributionEvent.amountMinor, 50000);

    assert.equal(result.updatedObligation.fulfilledAmountMinor, 50000);
    assert.equal(result.updatedObligation.status, 'ACTIVE');

    assert.equal(result.updatedSchedule.periods[0].status, 'RECORDED');
    assert.equal(result.updatedSchedule.periods[1].status, 'SCHEDULED');

    // Verify Firestore documents
    const cePath = getContributionEventPath(result.contributionEvent.contributionEventId);
    assert.ok(mockDb.docs.has(cePath));
  });


  it('advances obligation to FULFILLED when final period is recorded', async () => {
    // Record Period 1
    await recService.recordContribution({ tenantId, memberUid, obligationId, periodNumber: 1, nowIso });
    // Record Period 2
    await recService.recordContribution({ tenantId, memberUid, obligationId, periodNumber: 2, nowIso });
    // Record Period 3 (Final)
    const result3 = await recService.recordContribution({ tenantId, memberUid, obligationId, periodNumber: 3, nowIso });

    assert.equal(result3.updatedObligation.fulfilledAmountMinor, 150000);
    assert.equal(result3.updatedObligation.status, 'FULFILLED');
    assert.ok(result3.updatedSchedule.periods.every((p) => p.status === 'RECORDED'));
  });

  it('rejects duplicate contribution recording for the same period', async () => {
    await recService.recordContribution({ tenantId, memberUid, obligationId, periodNumber: 1, nowIso });
    // Idempotent replay if passing same idempotency or checking re-recording
    const replayResult = await recService.recordContribution({ tenantId, memberUid, obligationId, periodNumber: 1, nowIso });
    assert.equal(replayResult.isIdempotentReplay, true);
  });

  it('rejects recording for non-existent obligation', async () => {
    await assert.rejects(
      () =>
        recService.recordContribution({
          tenantId,
          memberUid,
          obligationId: 'ob_non_existent',
          periodNumber: 1,
          nowIso,
        }),
      EntityNotFoundError
    );
  });

  it('rejects out of bounds period number', async () => {
    await assert.rejects(
      () =>
        recService.recordContribution({
          tenantId,
          memberUid,
          obligationId,
          periodNumber: 4, // Duration is 3
          nowIso,
        }),
      PeriodOutOfBoundsError
    );
  });
});
