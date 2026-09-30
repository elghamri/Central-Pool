/**
 * Central Pool Step 7: Period DTO & Deterministic Identities Test Suite
 * Comprehensive regression tests covering Requirements A through L, zero-undefined Firestore SDK validation,
 * deserialization parity, and deterministic identity stability.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import { Timestamp, Firestore } from 'firebase-admin/firestore';
import {
  computeCyclePeriodProjectionId,
  computeMemberPeriodProjectionId,
} from '../domain/period_identities';
import {
  deriveCyclePeriodStructure,
  deriveMemberPeriodProjection,
} from '../domain/period_engine';
import {
  cyclePeriodProjectionToDoc,
  docToCyclePeriodProjection,
  memberPeriodProjectionToDoc,
  docToMemberPeriodProjection,
} from '../dto/period_dto';
import { InvalidPersistenceStateError } from '../../persistence/persistence_errors';
import { MockFirestore } from '../../confirmation/test/mock_firestore';
import { getUnitPeriodProjectionPath, getMemberPeriodProjectionPath } from '../domain/period_paths';

/**
 * Recursively inspects an object to ensure NO property anywhere has value `undefined`.
 */
function assertNoUndefinedProperties(obj: any, path: string = '$'): void {
  if (obj === null || obj === undefined) return;
  if (typeof obj !== 'object') return;
  if (obj instanceof Timestamp || obj instanceof Date) return;

  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      assertNoUndefinedProperties(obj[i], `${path}[${i}]`);
    }
    return;
  }

  for (const [key, value] of Object.entries(obj)) {
    const currentPath = `${path}.${key}`;
    assert.notStrictEqual(
      value,
      undefined,
      `Property "${currentPath}" has undefined value — strictly prohibited by Firestore serialization boundary`
    );
    assertNoUndefinedProperties(value, currentPath);
  }
}

/**
 * Official Google Cloud Firestore SDK instance for encoder validation.
 */
const officialFirestore = new Firestore({ projectId: 'test-serialization-project' });

function validateWithOfficialFirestoreSdk(doc: Record<string, any>): void {
  const serializer = (officialFirestore as any)._serializer;
  assert.ok(serializer, 'Official Firestore SDK Serializer must be available');
  const encoded = serializer.encodeFields(doc);
  assert.ok(encoded && typeof encoded === 'object', 'Encoded Firestore protobuf document fields must be valid');
}

describe('CENTRAL POOL — Step 7: Period DTO & Deterministic Identities', () => {
  const tenantId = 'tenant_dto_01';
  const unitId = 'unit_dto_01';
  const memberUid = 'usr_bob';
  const allocationId = 'alloc_bob_01';
  const currency = 'USD';
  const fixedNowIso = '2026-09-09T12:00:00.000Z';

  describe('1. Deterministic Projection Identifiers & Digest RFC 8785', () => {
    it('generates deterministic IDs with proper prefix and SHA-256 digest', () => {
      const id1 = computeCyclePeriodProjectionId(tenantId, unitId);
      const id2 = computeCyclePeriodProjectionId(tenantId, unitId);
      assert.equal(id1, id2);
      assert.ok(id1.startsWith('cpp_'));

      const id3 = computeCyclePeriodProjectionId('other_tenant', unitId);
      assert.notEqual(id1, id3);

      const mId1 = computeMemberPeriodProjectionId(tenantId, allocationId);
      const mId2 = computeMemberPeriodProjectionId(tenantId, allocationId);
      assert.equal(mId1, mId2);
      assert.ok(mId1.startsWith('mpp_'));
    });
  });

  describe('2. Remediation Regression Tests (Requirements A through L)', () => {
    it('Requirement A — authorizedMemberUids present when positions are occupied', () => {
      const domainWithMembers = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4,
        periodicContributionMinor: 25000,
        currency,
        positionMembers: { 1: 'usr_1', 2: 'usr_2', 3: 'usr_3', 4: 'usr_4' },
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(domainWithMembers);
      assert.ok('authorizedMemberUids' in doc, 'authorizedMemberUids key must exist in DTO');
      assert.deepEqual(doc.authorizedMemberUids, ['usr_1', 'usr_2', 'usr_3', 'usr_4']);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement B — authorizedMemberUids absent for forming unit with zero occupied positions', () => {
      const formingDomain = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4,
        periodicContributionMinor: 25000,
        currency,
        positionMembers: {},
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(formingDomain);
      assert.equal('authorizedMemberUids' in doc, false, 'authorizedMemberUids key must be absent');
      assert.equal(doc.authorizedMemberUids, undefined);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement C — memberUid present for occupied payout slot', () => {
      const domain = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4,
        periodicContributionMinor: 25000,
        currency,
        positionMembers: { 1: 'usr_alice' },
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(domain);
      const slot1 = doc.periods[0].payoutSlots.find((s) => s.positionNumber === 1);
      assert.ok(slot1);
      assert.ok('memberUid' in slot1, 'memberUid key must exist in occupied slot');
      assert.equal(slot1.memberUid, 'usr_alice');
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement D — memberUid absent for vacant payout slot', () => {
      const domain = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4,
        periodicContributionMinor: 25000,
        currency,
        positionMembers: { 1: 'usr_alice' }, // pos 2, 3, 4 are vacant
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(domain);
      const slot2 = doc.periods[0].payoutSlots.find((s) => s.positionNumber === 2);
      assert.ok(slot2);
      assert.equal('memberUid' in slot2, false, 'memberUid key must be absent in vacant slot');
      assert.equal(slot2.memberUid, undefined);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement E — mirrorPosition present for paired non-center position', () => {
      const domain = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4, // Even cycle: pos 1 paired with pos 4
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(domain);
      const slot1 = doc.periods[0].payoutSlots.find((s) => s.positionNumber === 1);
      assert.ok(slot1);
      assert.ok('mirrorPosition' in slot1, 'mirrorPosition key must exist for paired position');
      assert.equal(slot1.mirrorPosition, 4);
      assert.equal(slot1.isCenter, false);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement F — mirrorPosition absent for center position', () => {
      const domainOdd = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 5, // Odd cycle: pos 3 is center
        periodicContributionMinor: 20000,
        currency,
        nowIso: fixedNowIso,
      });
      const doc = cyclePeriodProjectionToDoc(domainOdd);
      // Period 3 has center position 3
      const centerSlot = doc.periods[2].payoutSlots.find((s) => s.positionNumber === 3);
      assert.ok(centerSlot);
      assert.equal(centerSlot.isCenter, true);
      assert.equal('mirrorPosition' in centerSlot, false, 'mirrorPosition key must be absent for center slot');
      assert.equal(centerSlot.mirrorPosition, undefined);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement G — recordedAt present for recorded contribution', () => {
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      // Simulate recorded contribution in period 1
      domain.periods[0].contribution.status = 'RECORDED';
      domain.periods[0].contribution.recordedAt = '2026-09-09T12:05:00.000Z';
      domain.periods[0].contribution.contributionEventId = 'ce_test_01';

      const doc = memberPeriodProjectionToDoc(domain);
      const period1Contribution = doc.periods[0].contribution;
      assert.ok('recordedAt' in period1Contribution, 'recordedAt key must exist');
      assert.ok(period1Contribution.recordedAt instanceof Timestamp);
      assert.equal(period1Contribution.recordedAt.toDate().toISOString(), '2026-09-09T12:05:00.000Z');
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement H — recordedAt absent for scheduled future contribution', () => {
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      // Period 2 is scheduled
      const doc = memberPeriodProjectionToDoc(domain);
      const period2Contribution = doc.periods[1].contribution;
      assert.equal('recordedAt' in period2Contribution, false, 'recordedAt key must be absent for scheduled contribution');
      assert.equal(period2Contribution.recordedAt, undefined);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement I — contributionEventId present for recorded contribution event', () => {
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      domain.periods[0].contribution.status = 'RECORDED';
      domain.periods[0].contribution.contributionEventId = 'ce_event_999';

      const doc = memberPeriodProjectionToDoc(domain);
      const period1Contribution = doc.periods[0].contribution;
      assert.ok('contributionEventId' in period1Contribution, 'contributionEventId key must exist');
      assert.equal(period1Contribution.contributionEventId, 'ce_event_999');
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement J — contributionEventId absent for unfulfilled contribution', () => {
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      const doc = memberPeriodProjectionToDoc(domain);
      const period2Contribution = doc.periods[1].contribution;
      assert.equal('contributionEventId' in period2Contribution, false, 'contributionEventId key must be absent');
      assert.equal(period2Contribution.contributionEventId, undefined);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement K — mirrorPeriod present for paired payout period', () => {
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4, // Paired periods 1 and 4
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      const doc = memberPeriodProjectionToDoc(domain);
      const period1Payout = doc.periods[0].payout;
      assert.ok('mirrorPeriod' in period1Payout, 'mirrorPeriod key must exist for paired payout period');
      assert.equal(period1Payout.mirrorPeriod, 4);
      assert.equal(period1Payout.isCenter, false);
      assertNoUndefinedProperties(doc);
      validateWithOfficialFirestoreSdk(doc);
    });

    it('Requirement L — mirrorPeriod absent for non-payout or center period', () => {
      // Non-payout period in even cycle: position 1 does not receive payout in period 2
      const domain = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 1,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });
      const doc = memberPeriodProjectionToDoc(domain);
      const period2Payout = doc.periods[1].payout;
      assert.equal('mirrorPeriod' in period2Payout, false, 'mirrorPeriod key must be absent for non-payout period');
      assert.equal(period2Payout.mirrorPeriod, undefined);

      // Center period in odd cycle: position 3 in 5-member cycle receives 100% payout in period 3 with NO mirror period
      const domainOddCenter = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 3,
        totalPeriods: 5,
        periodicContributionMinor: 20000,
        currency,
        nowIso: fixedNowIso,
      });
      const docOddCenter = memberPeriodProjectionToDoc(domainOddCenter);
      const centerPayout = docOddCenter.periods[2].payout;
      assert.equal(centerPayout.isCenter, true);
      assert.equal('mirrorPeriod' in centerPayout, false, 'mirrorPeriod key must be absent for center payout');
      assert.equal(centerPayout.mirrorPeriod, undefined);
      assertNoUndefinedProperties(docOddCenter);
      validateWithOfficialFirestoreSdk(docOddCenter);
    });
  });

  describe('3. Zero-Undefined Firestore Serialization & SDK Boundary Validation', () => {
    it('strictly guarantees 0 undefined properties across all permutations and passes Firestore SDK encoding', () => {
      const memberCounts = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      for (const N of memberCounts) {
        // Cycle projection with no members
        const vacantCycle = deriveCyclePeriodStructure({
          tenantId,
          allocationUnitId: `unit_${N}_vacant`,
          memberCount: N,
          periodicContributionMinor: 10000,
          currency: 'USD',
          nowIso: fixedNowIso,
        });
        const vacantDoc = cyclePeriodProjectionToDoc(vacantCycle);
        assertNoUndefinedProperties(vacantDoc);
        validateWithOfficialFirestoreSdk(vacantDoc);

        // Cycle projection with partial members
        const partialMembers: Record<number, string> = { 1: 'usr_p1' };
        const partialCycle = deriveCyclePeriodStructure({
          tenantId,
          allocationUnitId: `unit_${N}_partial`,
          memberCount: N,
          periodicContributionMinor: 10000,
          currency: 'USD',
          positionMembers: partialMembers,
          nowIso: fixedNowIso,
        });
        const partialDoc = cyclePeriodProjectionToDoc(partialCycle);
        assertNoUndefinedProperties(partialDoc);
        validateWithOfficialFirestoreSdk(partialDoc);

        // Member projections across all position numbers in the unit
        for (let pos = 1; pos <= N; pos++) {
          const memberProj = deriveMemberPeriodProjection({
            tenantId,
            memberUid: `usr_${pos}`,
            allocationId: `alloc_${pos}`,
            allocationUnitId: `unit_${N}`,
            positionNumber: pos,
            totalPeriods: N,
            periodicContributionMinor: 10000,
            currency: 'USD',
            nowIso: fixedNowIso,
          });
          const memberDoc = memberPeriodProjectionToDoc(memberProj);
          assertNoUndefinedProperties(memberDoc);
          validateWithOfficialFirestoreSdk(memberDoc);
        }
      }
    });
  });

  describe('4. Deserialization Parity & Round-Trip Semantic Fidelity', () => {
    it('round-trips CyclePeriodProjection with omitted optional values back to domain undefined', () => {
      const domainProjection = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 5,
        periodicContributionMinor: 20000,
        currency,
        nowIso: fixedNowIso,
      });

      const doc = cyclePeriodProjectionToDoc(domainProjection);
      assert.equal('authorizedMemberUids' in doc, false);
      const restored = docToCyclePeriodProjection(doc);

      assert.deepEqual(restored, domainProjection);
      assert.equal(restored.authorizedMemberUids, undefined);
    });

    it('round-trips MemberPeriodProjection with omitted optional values back to domain undefined', () => {
      const domainProjection = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 3, // Center in N=5
        totalPeriods: 5,
        periodicContributionMinor: 20000,
        currency,
        nowIso: fixedNowIso,
      });

      const doc = memberPeriodProjectionToDoc(domainProjection);
      assert.equal('recordedAt' in doc.periods[0].contribution, false);
      assert.equal('contributionEventId' in doc.periods[0].contribution, false);
      assert.equal('mirrorPeriod' in doc.periods[2].payout, false);

      const restored = docToMemberPeriodProjection(doc);
      assert.deepEqual(restored, domainProjection);
      assert.equal(restored.periods[0].contribution.recordedAt, undefined);
      assert.equal(restored.periods[0].contribution.contributionEventId, undefined);
      assert.equal(restored.periods[2].payout.mirrorPeriod, undefined);
    });
  });

  describe('5. Idempotency & Repeated Persistence Stability', () => {
    it('persists identical projections repeatedly without mutation or duplicates', async () => {
      const mockDb = new MockFirestore();
      const domainCycle = deriveCyclePeriodStructure({
        tenantId,
        allocationUnitId: unitId,
        memberCount: 4,
        periodicContributionMinor: 25000,
        currency,
        positionMembers: { 1: 'usr_1', 2: 'usr_2', 3: 'usr_3', 4: 'usr_4' },
        nowIso: fixedNowIso,
      });

      const doc1 = cyclePeriodProjectionToDoc(domainCycle);
      const cyclePath = getUnitPeriodProjectionPath(unitId, doc1.projectionId);

      // First write
      await mockDb.doc(cyclePath).set(doc1);
      assert.equal(mockDb.docs.size, 1);
      const firstPersisted = mockDb.docs.get(cyclePath)?.data;

      // Second write (same authoritative payload)
      const doc2 = cyclePeriodProjectionToDoc(domainCycle);
      await mockDb.doc(cyclePath).set(doc2);
      assert.equal(mockDb.docs.size, 1, 'Repeated write must not create duplicate document');
      const secondPersisted = mockDb.docs.get(cyclePath)?.data;

      assert.deepEqual(firstPersisted, secondPersisted);
      assert.equal(doc1.projectionId, doc2.projectionId);
    });

    it('persists member projections repeatedly with identical deterministic keys and zero undefined fields', async () => {
      const mockDb = new MockFirestore();
      const domainMember = deriveMemberPeriodProjection({
        tenantId,
        memberUid,
        allocationId,
        allocationUnitId: unitId,
        positionNumber: 2,
        totalPeriods: 4,
        periodicContributionMinor: 25000,
        currency,
        nowIso: fixedNowIso,
      });

      const doc1 = memberPeriodProjectionToDoc(domainMember);
      const memberPath = getMemberPeriodProjectionPath(memberUid, doc1.projectionId);

      await mockDb.doc(memberPath).set(doc1);
      assert.equal(mockDb.docs.size, 1);

      const doc2 = memberPeriodProjectionToDoc(domainMember);
      await mockDb.doc(memberPath).set(doc2);
      assert.equal(mockDb.docs.size, 1);

      assert.deepEqual(mockDb.docs.get(memberPath)?.data, doc1);
    });
  });

  describe('6. Invalid Document Rejection & Error Boundaries', () => {
    it('rejects invalid document structure in doc converters', () => {
      assert.throws(() => {
        docToCyclePeriodProjection(null);
      }, InvalidPersistenceStateError);

      assert.throws(() => {
        docToCyclePeriodProjection({ projectionId: 'cpp_1' }); // missing required fields
      }, InvalidPersistenceStateError);

      assert.throws(() => {
        docToMemberPeriodProjection(null);
      }, InvalidPersistenceStateError);

      assert.throws(() => {
        docToMemberPeriodProjection({ projectionId: 'mpp_1' }); // missing required fields
      }, InvalidPersistenceStateError);
    });
  });
});

