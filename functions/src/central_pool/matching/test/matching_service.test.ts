/**
 * Central Pool Step 4: Matching Service (Repository Adapter Boundary) Test Suite
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';

import {
  ParticipationRequest,
  AllocationUnit,
  AllocationPosition,
  AllocationCandidate,
  AllocationUnitState,
} from '../../domain';
import {
  AllocationUnitRepository,
  AllocationPositionRepository,
  AllocationCandidateRepository,
  TenantIsolationViolationError,
} from '../../persistence';
import { MatchingService } from '../matching_service';
import { computeCompatibilityKey } from '../compatibility_key';

// In-Memory Repository Test Adapters
class InMemoryUnitRepository implements AllocationUnitRepository {
  public units = new Map<string, AllocationUnit>();

  async createFormingUnit(tenantId: string, unit: AllocationUnit): Promise<void> {
    this.units.set(`${tenantId}:${unit.unitId}`, { ...unit });
  }

  async getAllocationUnit(tenantId: string, unitId: string): Promise<AllocationUnit | null> {
    return this.units.get(`${tenantId}:${unitId}`) || null;
  }

  async updateUnitState(
    tenantId: string,
    unitId: string,
    _expectedCurrentState: AllocationUnitState,
    targetState: AllocationUnitState,
    occupiedCount?: number
  ): Promise<void> {
    const existing = this.units.get(`${tenantId}:${unitId}`);
    if (existing) {
      existing.status = targetState;
      if (occupiedCount !== undefined) {
        existing.occupiedCount = occupiedCount;
      }
    }
  }

  async findFormingUnitsByCompatibilityKey(
    tenantId: string,
    compatibilityKey: string
  ): Promise<AllocationUnit[]> {
    const results: AllocationUnit[] = [];
    for (const [key, unit] of this.units.entries()) {
      if (
        key.startsWith(`${tenantId}:`) &&
        unit.compatibilityKey === compatibilityKey &&
        unit.status === 'FORMING'
      ) {
        results.push({ ...unit });
      }
    }
    return results;
  }
}

class InMemoryPositionRepository implements AllocationPositionRepository {
  public positions: AllocationPosition[] = [];

  async createPosition(tenantId: string, position: AllocationPosition, _unitMemberCount: number): Promise<void> {
    this.positions.push({ ...position });
  }

  async getPosition(
    tenantId: string,
    unitId: string,
    positionNumber: number,
    _unitMemberCount: number
  ): Promise<AllocationPosition | null> {
    const found = this.positions.find(
      (p) =>
        p.tenantId === tenantId &&
        p.unitId === unitId &&
        p.positionNumber === positionNumber
    );
    return found ? { ...found } : null;
  }

  async listPositionsForUnit(
    tenantId: string,
    unitId: string,
    _memberCount: number
  ): Promise<AllocationPosition[]> {
    return this.positions
      .filter((p) => p.tenantId === tenantId && p.unitId === unitId)
      .map((p) => ({ ...p }));
  }
}

class InMemoryCandidateRepository implements AllocationCandidateRepository {
  public savedCandidates: AllocationCandidate[] = [];

  async saveCandidate(tenantId: string, candidate: AllocationCandidate): Promise<void> {
    if (candidate.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, candidate.tenantId, 'AllocationCandidate');
    }
    this.savedCandidates.push({ ...candidate });
  }

  async getCandidate(
    tenantId: string,
    candidateId: string
  ): Promise<AllocationCandidate | null> {
    const found = this.savedCandidates.find(
      (c) => c.tenantId === tenantId && c.candidateId === candidateId
    );
    return found ? { ...found } : null;
  }

  async deleteCandidate(tenantId: string, candidateId: string): Promise<void> {
    this.savedCandidates = this.savedCandidates.filter(
      (c) => !(c.tenantId === tenantId && c.candidateId === candidateId)
    );
  }
}

describe('CENTRAL POOL — Step 4: Matching Service (Repository Adapter Boundary)', () => {
  const tenantA = 'tenant_prod_01';
  const tenantB = 'tenant_prod_02';

  const sampleRequest: ParticipationRequest = {
    requestId: 'req_001',
    tenantId: tenantA,
    memberUid: 'usr_alice',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    preferredPayoutPeriod: 3,
    status: 'SUBMITTED',
    clientSubmissionId: 'sub_123',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    requestExpiresAt: '2026-09-15T12:00:00.000Z',
    version: 1,
  };

  const compatibilityKey = computeCompatibilityKey({
    tenantId: tenantA,
    currency: 'USD',
    contributionMinor: 50000,
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
  });

  const formingUnit: AllocationUnit = {
    unitId: 'unit_001',
    tenantId: tenantA,
    compatibilityKey,
    memberCount: 6,
    occupiedCount: 2,
    status: 'FORMING',
    contributionMinor: 50000,
    currency: 'USD',
    durationPeriods: 6,
    allocationRule: 'SYMMETRICAL_V1',
    createdAt: '2026-09-08T12:00:00.000Z',
    updatedAt: '2026-09-08T12:00:00.000Z',
    version: 1,
  };

  const existingOccupiedPositions: AllocationPosition[] = [
    {
      unitId: 'unit_001',
      positionNumber: 1,
      tenantId: tenantA,
      memberUid: 'usr_other1',
      requestId: 'req_other1',
      payoutPeriod: 1,
      occupiedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    },
    {
      unitId: 'unit_001',
      positionNumber: 2,
      tenantId: tenantA,
      memberUid: 'usr_other2',
      requestId: 'req_other2',
      payoutPeriod: 2,
      occupiedAt: '2026-09-08T12:00:00.000Z',
      version: 1,
    },
  ];

  it('strictly enforces tenant isolation at the boundary', async () => {
    const unitRepo = new InMemoryUnitRepository();
    const positionRepo = new InMemoryPositionRepository();
    const service = new MatchingService(unitRepo, positionRepo);

    await assert.rejects(
      async () => {
        // Calling with tenantB when request is for tenantA
        await service.findCandidatesForRequest(tenantB, sampleRequest);
      },
      (err: any) => err instanceof TenantIsolationViolationError
    );
  });

  it('discovers forming units by compatibility key and generates provisional candidates', async () => {
    const unitRepo = new InMemoryUnitRepository();
    const positionRepo = new InMemoryPositionRepository();
    const candidateRepo = new InMemoryCandidateRepository();

    await unitRepo.createFormingUnit(tenantA, formingUnit);
    for (const pos of existingOccupiedPositions) {
      await positionRepo.createPosition(tenantA, pos, 6);
    }

    const service = new MatchingService(unitRepo, positionRepo, candidateRepo);

    const result = await service.findCandidatesForRequest(tenantA, sampleRequest, {
      evaluationTimestamp: '2026-09-08T12:00:00.000Z',
    });

    assert.equal(result.requestId, 'req_001');
    assert.equal(result.tenantId, tenantA);
    assert.equal(result.evaluatedUnitsCount, 1);
    assert.equal(result.eligibleUnitsCount, 1);
    // Unit capacity is 6, occupied is 2 -> 4 vacant candidate slots (positions 3, 4, 5, 6)
    assert.equal(result.candidates.length, 4);

    // Verify candidates were saved to candidate repo
    assert.equal(candidateRepo.savedCandidates.length, 4);

    // Verify that NO positions were created in position repository
    assert.equal(positionRepo.positions.length, 2);

    // Verify that unit state was NOT mutated
    const unitAfter = await unitRepo.getAllocationUnit(tenantA, 'unit_001');
    assert.equal(unitAfter?.occupiedCount, 2);
    assert.equal(unitAfter?.status, 'FORMING');
  });

  it('returns empty candidate list when no matching forming units exist', async () => {
    const unitRepo = new InMemoryUnitRepository();
    const positionRepo = new InMemoryPositionRepository();
    const service = new MatchingService(unitRepo, positionRepo);

    const result = await service.findCandidatesForRequest(tenantA, sampleRequest);

    assert.equal(result.evaluatedUnitsCount, 0);
    assert.equal(result.eligibleUnitsCount, 0);
    assert.equal(result.candidates.length, 0);
  });
});
