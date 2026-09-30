/**
 * Firestore DTO: ConfirmedAllocationDoc
 * Represents the derived presentation receipt projection at /users/{userId}/allocations/{allocationId}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';

export interface ConfirmedAllocationDoc {
  allocationId: string;
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
  confirmedAt: Timestamp | FieldValue;
  isProjection: true;
  classification: 'DERIVED_PROJECTION';
  version: number;
}
