/**
 * Central Pool Step 4: Deterministic Compatibility & Candidate Identity Hashing
 *
 * CRYPTOGRAPHIC SPECIFICATION:
 * The design uses the full 256-bit SHA-256 digest without truncation and relies on the
 * cryptographic collision resistance of SHA-256. Collision probability is cryptographically
 * negligible but not mathematically impossible.
 */

import * as crypto from 'node:crypto';

/**
 * Deterministically canonicalizes a JavaScript object into a sorted JSON string
 * complying with RFC 8785 (JSON Canonicalization Scheme).
 */
export function canonicalJson(obj: unknown): string {
  if (obj === null || typeof obj !== 'object') {
    return JSON.stringify(obj);
  }

  if (Array.isArray(obj)) {
    return `[${obj.map((item) => canonicalJson(item)).join(',')}]`;
  }

  const sortedKeys = Object.keys(obj as Record<string, unknown>).sort();
  const pairs = sortedKeys.map((key) => {
    const value = (obj as Record<string, unknown>)[key];
    return `${JSON.stringify(key)}:${canonicalJson(value)}`;
  });

  return `{${pairs.join(',')}}`;
}

/**
 * Computes a deterministic SHA-256 hex digest for a string payload.
 */
export function sha256Hex(payload: string): string {
  return crypto.createHash('sha256').update(payload, 'utf8').digest('hex');
}

export interface CompatibilityTuple {
  tenantId: string;
  currency: string;
  contributionMinor: number;
  durationPeriods: number;
  allocationRule: 'SYMMETRICAL_V1';
}

/**
 * Computes the deterministic compatibility key for an Allocation Unit or Participation Request.
 * Formula: 'cp_' + SHA256(JCS(Tuple))
 */
export function computeCompatibilityKey(tuple: CompatibilityTuple): string {
  const normalizedTuple = {
    allocationRule: tuple.allocationRule,
    contributionMinor: tuple.contributionMinor,
    currency: tuple.currency.toUpperCase(),
    durationPeriods: tuple.durationPeriods,
    tenantId: tuple.tenantId,
  };

  const canonical = canonicalJson(normalizedTuple);
  return `cp_${sha256Hex(canonical)}`;
}

export interface CandidateIdentityParams {
  tenantId: string;
  requestId: string;
  allocationUnitId: string;
  allocatedPosition: number;
  payoutPeriod: number;
  contributionMinor: number;
  durationPeriods: number;
  allocationRule: 'SYMMETRICAL_V1';
}

/**
 * Computes the deterministic candidate token identity.
 * Formula: 'cand_' + SHA256(JCS(CandidateParams))
 *
 * CRYPTOGRAPHIC SPECIFICATION:
 * SHA-256 collision-resistant with cryptographically negligible collision probability.
 * Candidate identity cryptographically binds the candidate to its immutable relationship context:
 * (tenantId, requestId, allocationUnitId, allocatedPosition, payoutPeriod, contributionMinor, durationPeriods, allocationRule).
 * It does NOT contain mutable evaluation state (occupancy, ranking score, expiresAt, timestamps).
 */
export function computeCandidateId(params: CandidateIdentityParams): string {
  const normalizedParams = {
    allocatedPosition: params.allocatedPosition,
    allocationRule: params.allocationRule,
    allocationUnitId: params.allocationUnitId,
    contributionMinor: params.contributionMinor,
    durationPeriods: params.durationPeriods,
    payoutPeriod: params.payoutPeriod,
    requestId: params.requestId,
    tenantId: params.tenantId,
  };

  const canonical = canonicalJson(normalizedParams);
  return `cand_${sha256Hex(canonical)}`;
}
