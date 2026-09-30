/**
 * Firestore DTO: AllocationCandidateDoc
 * Represents provisional candidate authorization artifact stored ephemerally (e.g. in cache or transient collection).
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';

export interface AllocationCandidateDoc {
  candidateId: string;
  requestId: string;
  tenantId: string;
  memberUid: string;
  allocationUnitId: string;
  allocatedPosition: number;
  payoutPeriod: number;
  contributionMinor: number;
  durationPeriods: number;
  totalEntitlementMinor: number;
  totalPotMinor: number;
  currency: string;
  allocationRule: 'SYMMETRICAL_V1';
  issuedAt: Timestamp | FieldValue;
  expiresAt: Timestamp;
  signature?: string;
  isProvisional: true;
}
