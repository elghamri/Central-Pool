/**
 * Central Pool Step 7: Period Projection DTO Schemas & Converters
 * Type-safe bidirectional conversions between Domain Projections and Firestore Document Schemas.
 */

import { Timestamp } from 'firebase-admin/firestore';
import {
  CyclePeriodProjection,
  MemberPeriodProjection,
  PeriodClassification,
} from '../domain/period_types';
import { timestampToIsoString } from '../../persistence/dto/dto_converters';
import { InvalidPersistenceStateError } from '../../persistence/persistence_errors';

export interface PeriodPayoutSlotDoc {
  positionNumber: number;
  memberUid?: string;
  amountMinor: number;
  basisPoints: number;
  isCenter: boolean;
  mirrorPosition?: number;
}

export interface CyclePeriodSummaryDoc {
  periodNumber: number;
  expectedContributionPoolMinor: number;
  expectedDisbursementPoolMinor: number;
  payoutSlots: PeriodPayoutSlotDoc[];
  isBalanced: boolean;
}

export interface CyclePeriodProjectionDoc {
  projectionId: string;
  tenantId: string;
  allocationUnitId: string;
  memberCount: number;
  periodicContributionMinor: number;
  totalEntitlementMinor: number;
  totalPotMinor: number;
  currency: string;
  periods: CyclePeriodSummaryDoc[];
  authorizedMemberUids?: string[];
  isProjection: true;
  classification: PeriodClassification;
  generatedAt: Timestamp;
}

export interface MemberPeriodDetailDoc {
  periodNumber: number;
  contribution: {
    periodNumber: number;
    dueAmountMinor: number;
    status: string;
    recordedAt?: Timestamp;
    contributionEventId?: string;
  };
  payout: {
    entitledAmountMinor: number;
    basisPoints: number;
    isPayoutPeriod: boolean;
    isCenter: boolean;
    mirrorPeriod?: number;
  };
  netEntitlementDeltaMinor: number;
}

export interface MemberPeriodProjectionDoc {
  projectionId: string;
  tenantId: string;
  memberUid: string;
  allocationId: string;
  allocationUnitId: string;
  positionNumber: number;
  totalPeriods: number;
  periodicContributionMinor: number;
  totalObligationMinor: number;
  totalEntitlementMinor: number;
  currency: string;
  periods: MemberPeriodDetailDoc[];
  isProjection: true;
  classification: PeriodClassification;
  generatedAt: Timestamp;
}

export function cyclePeriodProjectionToDoc(projection: CyclePeriodProjection): CyclePeriodProjectionDoc {
  const doc: CyclePeriodProjectionDoc = {
    projectionId: projection.projectionId,
    tenantId: projection.tenantId,
    allocationUnitId: projection.allocationUnitId,
    memberCount: projection.memberCount,
    periodicContributionMinor: projection.periodicContributionMinor,
    totalEntitlementMinor: projection.totalEntitlementMinor,
    totalPotMinor: projection.totalPotMinor,
    currency: projection.currency,
    periods: projection.periods.map((p) => ({
      periodNumber: p.periodNumber,
      expectedContributionPoolMinor: p.expectedContributionPoolMinor,
      expectedDisbursementPoolMinor: p.expectedDisbursementPoolMinor,
      payoutSlots: p.payoutSlots.map((s) => {
        const slot: PeriodPayoutSlotDoc = {
          positionNumber: s.positionNumber,
          amountMinor: s.amountMinor,
          basisPoints: s.basisPoints,
          isCenter: s.isCenter,
        };
        if (s.memberUid !== undefined) {
          slot.memberUid = s.memberUid;
        }
        if (s.mirrorPosition !== undefined) {
          slot.mirrorPosition = s.mirrorPosition;
        }
        return slot;
      }),
      isBalanced: p.isBalanced,
    })),
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: Timestamp.fromDate(new Date(projection.generatedAt)),
  };

  if (projection.authorizedMemberUids !== undefined && projection.authorizedMemberUids.length > 0) {
    doc.authorizedMemberUids = projection.authorizedMemberUids;
  }

  return doc;
}

export function docToCyclePeriodProjection(data: unknown): CyclePeriodProjection {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for CyclePeriodProjectionDoc');
  }
  const d = data as Record<string, any>;

  if (!d.projectionId || !d.tenantId || !d.allocationUnitId || !Array.isArray(d.periods)) {
    throw new InvalidPersistenceStateError('Missing required fields on CyclePeriodProjectionDoc');
  }

  return {
    projectionId: String(d.projectionId),
    tenantId: String(d.tenantId),
    allocationUnitId: String(d.allocationUnitId),
    memberCount: Number(d.memberCount),
    periodicContributionMinor: Number(d.periodicContributionMinor),
    totalEntitlementMinor: Number(d.totalEntitlementMinor),
    totalPotMinor: Number(d.totalPotMinor),
    currency: String(d.currency),
    periods: d.periods.map((p: any) => ({
      periodNumber: Number(p.periodNumber),
      expectedContributionPoolMinor: Number(p.expectedContributionPoolMinor),
      expectedDisbursementPoolMinor: Number(p.expectedDisbursementPoolMinor),
      payoutSlots: (p.payoutSlots || []).map((s: any) => ({
        positionNumber: Number(s.positionNumber),
        memberUid: s.memberUid ? String(s.memberUid) : undefined,
        amountMinor: Number(s.amountMinor),
        basisPoints: Number(s.basisPoints),
        isCenter: Boolean(s.isCenter),
        mirrorPosition: s.mirrorPosition !== undefined ? Number(s.mirrorPosition) : undefined,
      })),
      isBalanced: Boolean(p.isBalanced),
    })),
    authorizedMemberUids: Array.isArray(d.authorizedMemberUids) && d.authorizedMemberUids.length > 0 ? d.authorizedMemberUids.map(String) : undefined,
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: timestampToIsoString(d.generatedAt, 'generatedAt'),
  };
}

export function memberPeriodProjectionToDoc(projection: MemberPeriodProjection): MemberPeriodProjectionDoc {
  return {
    projectionId: projection.projectionId,
    tenantId: projection.tenantId,
    memberUid: projection.memberUid,
    allocationId: projection.allocationId,
    allocationUnitId: projection.allocationUnitId,
    positionNumber: projection.positionNumber,
    totalPeriods: projection.totalPeriods,
    periodicContributionMinor: projection.periodicContributionMinor,
    totalObligationMinor: projection.totalObligationMinor,
    totalEntitlementMinor: projection.totalEntitlementMinor,
    currency: projection.currency,
    periods: projection.periods.map((p) => {
      const contributionDoc: MemberPeriodDetailDoc['contribution'] = {
        periodNumber: p.contribution.periodNumber,
        dueAmountMinor: p.contribution.dueAmountMinor,
        status: p.contribution.status,
      };
      if (p.contribution.recordedAt) {
        contributionDoc.recordedAt = Timestamp.fromDate(new Date(p.contribution.recordedAt));
      }
      if (p.contribution.contributionEventId !== undefined) {
        contributionDoc.contributionEventId = p.contribution.contributionEventId;
      }

      const payoutDoc: MemberPeriodDetailDoc['payout'] = {
        entitledAmountMinor: p.payout.entitledAmountMinor,
        basisPoints: p.payout.basisPoints,
        isPayoutPeriod: p.payout.isPayoutPeriod,
        isCenter: p.payout.isCenter,
      };
      if (p.payout.mirrorPeriod !== undefined) {
        payoutDoc.mirrorPeriod = p.payout.mirrorPeriod;
      }

      return {
        periodNumber: p.periodNumber,
        contribution: contributionDoc,
        payout: payoutDoc,
        netEntitlementDeltaMinor: p.netEntitlementDeltaMinor,
      };
    }),
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: Timestamp.fromDate(new Date(projection.generatedAt)),
  };
}

export function docToMemberPeriodProjection(data: unknown): MemberPeriodProjection {
  if (!data || typeof data !== 'object') {
    throw new InvalidPersistenceStateError('Expected object data for MemberPeriodProjectionDoc');
  }
  const d = data as Record<string, any>;

  if (!d.projectionId || !d.tenantId || !d.memberUid || !d.allocationId || !Array.isArray(d.periods)) {
    throw new InvalidPersistenceStateError('Missing required fields on MemberPeriodProjectionDoc');
  }

  return {
    projectionId: String(d.projectionId),
    tenantId: String(d.tenantId),
    memberUid: String(d.memberUid),
    allocationId: String(d.allocationId),
    allocationUnitId: String(d.allocationUnitId),
    positionNumber: Number(d.positionNumber),
    totalPeriods: Number(d.totalPeriods),
    periodicContributionMinor: Number(d.periodicContributionMinor),
    totalObligationMinor: Number(d.totalObligationMinor),
    totalEntitlementMinor: Number(d.totalEntitlementMinor),
    currency: String(d.currency),
    periods: d.periods.map((p: any) => ({
      periodNumber: Number(p.periodNumber),
      contribution: {
        periodNumber: Number(p.contribution.periodNumber),
        dueAmountMinor: Number(p.contribution.dueAmountMinor),
        status: p.contribution.status as any,
        recordedAt: p.contribution.recordedAt ? timestampToIsoString(p.contribution.recordedAt, 'recordedAt') : undefined,
        contributionEventId: p.contribution.contributionEventId ? String(p.contribution.contributionEventId) : undefined,
      },
      payout: {
        entitledAmountMinor: Number(p.payout.entitledAmountMinor),
        basisPoints: Number(p.payout.basisPoints),
        isPayoutPeriod: Boolean(p.payout.isPayoutPeriod),
        isCenter: Boolean(p.payout.isCenter),
        mirrorPeriod: p.payout.mirrorPeriod !== undefined ? Number(p.payout.mirrorPeriod) : undefined,
      },
      netEntitlementDeltaMinor: Number(p.netEntitlementDeltaMinor ?? p.netCashFlowMinor),
    })),
    isProjection: true,
    classification: 'DERIVED_PROJECTION',
    generatedAt: timestampToIsoString(d.generatedAt, 'generatedAt'),
  };
}
