/**
 * Firestore DTO: AllocationUnitDoc
 * Represents the exact document structure in /allocation_units/{unitId}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { AllocationUnitState } from '../../domain/domain_states';

export interface AllocationUnitDoc {
  unitId: string;
  tenantId: string;
  compatibilityKey: string;
  memberCount: number;
  occupiedCount: number;
  status: AllocationUnitState;
  contributionMinor: number;
  currency: string;
  durationPeriods: number;
  allocationRule: 'SYMMETRICAL_V1';
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  version: number;
}
