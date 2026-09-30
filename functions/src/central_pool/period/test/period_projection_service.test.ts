/**
 * Central Pool Step 7: Period Projection Service Test Suite
 * Tests repository adapter boundary, tenant isolation, member ownership isolation, and timeline querying.
 */

import { describe, it, beforeEach } from 'node:test';
import * as assert from 'node:assert/strict';
import { MockFirestore } from '../../confirmation/test/mock_firestore';
import { PeriodProjectionService } from '../services/period_projection_service';
import {
  PeriodProjectionAccessDeniedError,
} from '../domain/period_errors';
import {
  getAllocationUnitPath,
  getPositionPath,
  getAllocationReceiptPath,
  getContributionSchedulePath,
} from '../../domain/domain_paths';
import {
  getMemberPeriodProjectionPath,
  getUnitPeriodProjectionPath,
} from '../domain/period_paths';
import { computeObligationId, computeContributionScheduleId } from '../../financial/identities';
import { Timestamp } from 'firebase-admin/firestore';

describe('CENTRAL POOL — Step 7: Period Projection Service', () => {
  let mockDb: MockFirestore;
  let service: PeriodProjectionService;

  const tenantId = 'tenant_prod_01';
  const otherTenantId = 'tenant_intruder_99';
  const memberUid = 'usr_alice';
  const otherMemberUid = 'usr_mallory';
  const unitId = 'unit_alpha_01';
  const allocationId = 'alloc_alice_01';
  const requestId = 'req_alice_01';
  const nowTimestamp = Timestamp.fromDate(new Date('2026-09-09T12:00:00.000Z'));

  beforeEach(() => {
    mockDb = new MockFirestore();
    service = new PeriodProjectionService(mockDb as any);

    // Seed Allocation Unit in mock DB
    mockDb.docs.set(getAllocationUnitPath(unitId), {
      data: {
        unitId,
        tenantId,
        compatibilityKey: 'cp_test_key',
        memberCount: 6,
        contributionMinor: 50000,
        durationPeriods: 6,
        currency: 'USD',
        status: 'COMMITTED_FULL',
        occupiedCount: 6,
        allocationRule: 'SYMMETRICAL_V1',
        createdAt: nowTimestamp,
        updatedAt: nowTimestamp,
        version: 1,
      },
      version: 1,
    });

    // Seed Positions for Unit
    for (let pos = 1; pos <= 6; pos++) {
      mockDb.docs.set(getPositionPath(unitId, pos), {
        data: {
          unitId,
          positionNumber: pos,
          tenantId,
          memberUid: pos === 1 ? memberUid : `usr_member_${pos}`,
          requestId: `req_${pos}`,
          payoutPeriod: pos,
          occupiedAt: nowTimestamp,
          version: 1,
        },
        version: 1,
      });
    }

    // Seed Confirmed Allocation for member in mock DB
    mockDb.docs.set(getAllocationReceiptPath(memberUid, allocationId), {
      data: {
        allocationId,
        requestId,
        tenantId,
        memberUid,
        allocationUnitId: unitId,
        allocatedPosition: 1,
        payoutPeriod: 1,
        durationPeriods: 6,
        contributionMinor: 50000,
        totalEntitlementMinor: 300000,
        totalPotMinor: 1800000,
        currency: 'USD',
        allocationRule: 'SYMMETRICAL_V1',
        isProjection: true,
        classification: 'DERIVED_PROJECTION',
        confirmedAt: nowTimestamp,
        version: 1,
      },
      version: 1,
    });

    // Seed Contribution Schedule
    const obligationId = computeObligationId(tenantId, allocationId);
    const scheduleId = computeContributionScheduleId(tenantId, obligationId);
    mockDb.docs.set(getContributionSchedulePath(scheduleId), {
      data: {
        scheduleId,
        obligationId,
        tenantId,
        memberUid,
        allocationUnitId: unitId,
        totalPeriods: 6,
        periods: [
          { periodNumber: 1, scheduledAmountMinor: 50000, status: 'RECORDED', recordedAt: nowTimestamp, contributionEventId: 'ce_001' },
          { periodNumber: 2, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
          { periodNumber: 3, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
          { periodNumber: 4, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
          { periodNumber: 5, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
          { periodNumber: 6, scheduledAmountMinor: 50000, status: 'SCHEDULED' },
        ],
        createdAt: nowTimestamp,
        updatedAt: nowTimestamp,
        version: 1,
      },
      version: 1,
    });
  });

  it('generates and persists cycle period projection for an authorized unit', async () => {
    const projection = await service.getCyclePeriodProjection(tenantId, unitId, true);

    assert.equal(projection.tenantId, tenantId);
    assert.equal(projection.allocationUnitId, unitId);
    assert.equal(projection.memberCount, 6);
    assert.equal(projection.totalEntitlementMinor, 300000);
    assert.equal(projection.periods.length, 6);
    assert.ok(projection.authorizedMemberUids);
    assert.ok(projection.authorizedMemberUids?.includes(memberUid));
    assert.equal(projection.authorizedMemberUids?.length, 6);

    // Verify written to mock Firestore at unit path
    const unitProjPath = getUnitPeriodProjectionPath(unitId, projection.projectionId);
    assert.ok(mockDb.docs.has(unitProjPath));
    const persisted = mockDb.docs.get(unitProjPath)?.data;
    assert.ok(persisted);
    assert.equal(persisted?.isProjection, true);
    assert.equal(persisted?.classification, 'DERIVED_PROJECTION');
  });

  it('strictly rejects cross-tenant cycle projection access', async () => {
    await assert.rejects(
      async () => {
        await service.getCyclePeriodProjection(otherTenantId, unitId);
      },
      (err: any) => {
        return err instanceof PeriodProjectionAccessDeniedError && err.message.includes('tenant mismatch');
      }
    );
  });

  it('generates and persists member period projection for authorized member', async () => {
    const projection = await service.getMemberPeriodProjection(tenantId, memberUid, allocationId, true);

    assert.equal(projection.tenantId, tenantId);
    assert.equal(projection.memberUid, memberUid);
    assert.equal(projection.positionNumber, 1);
    assert.equal(projection.periods[0].contribution.status, 'RECORDED');
    assert.equal(projection.periods[1].contribution.status, 'SCHEDULED');

    // Verify written to mock Firestore at member path
    const memberProjPath = getMemberPeriodProjectionPath(memberUid, projection.projectionId);
    assert.ok(mockDb.docs.has(memberProjPath));
    const persisted = mockDb.docs.get(memberProjPath)?.data;
    assert.ok(persisted);
    assert.equal(persisted?.isProjection, true);
    assert.equal(persisted?.classification, 'DERIVED_PROJECTION');
  });

  it('strictly rejects cross-member ownership violation', async () => {
    await assert.rejects(
      async () => {
        await service.getMemberPeriodProjection(tenantId, otherMemberUid, allocationId);
      },
      (err: any) => {
        return err?.name === 'EntityNotFoundError'; // Allocation is stored under /users/usr_alice, not mallory
      }
    );
  });

  it('queries period timeline for a specific period', async () => {
    const period1 = await service.queryPeriodTimeline(tenantId, memberUid, allocationId, 1);
    assert.equal(period1.periodNumber, 1);
    assert.equal(period1.contribution.dueAmountMinor, 50000);
    assert.equal(period1.payout.entitledAmountMinor, 150000);
    assert.equal(period1.netEntitlementDeltaMinor, 100000);

    const period2 = await service.queryPeriodTimeline(tenantId, memberUid, allocationId, 2);
    assert.equal(period2.periodNumber, 2);
    assert.equal(period2.contribution.dueAmountMinor, 50000);
    assert.equal(period2.payout.entitledAmountMinor, 0);
    assert.equal(period2.netEntitlementDeltaMinor, -50000);
  });

  it('queries cycle period readiness summary', async () => {
    const readiness = await service.queryCyclePeriodReadiness(tenantId, unitId, 1, 300000);
    assert.equal(readiness.periodNumber, 1);
    assert.equal(readiness.totalScheduledContributionMinor, 300000);
    assert.equal(readiness.totalRecordedContributionMinor, 300000);
    assert.equal(readiness.allContributionsRecorded, true);
    assert.equal(readiness.isPoolBalanced, true);
  });
});
