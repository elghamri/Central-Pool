/**
 * Firestore DTO: AllocationPositionDoc
 * Represents the authoritative occupied position document in /allocation_units/{unitId}/positions/{positionNumber}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';

export interface AllocationPositionDoc {
  unitId: string;
  positionNumber: number;
  tenantId: string;
  memberUid: string;
  requestId: string;
  payoutPeriod: number;
  occupiedAt: Timestamp | FieldValue;
  version: number;
}
