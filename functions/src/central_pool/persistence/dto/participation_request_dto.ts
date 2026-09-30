/**
 * Firestore DTO: ParticipationRequestDoc
 * Represents the exact document structure in /participation_requests/{requestId}
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { PersistedParticipationRequestState } from '../../domain/domain_states';

export interface ParticipationRequestDoc {
  requestId: string;
  tenantId: string;
  memberUid: string;
  contributionMinor: number;
  currency: string;
  durationPeriods: number;
  preferredPayoutPeriod?: number;
  status: PersistedParticipationRequestState;
  clientSubmissionId: string;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  requestExpiresAt: Timestamp;
  version: number;
  allocationUnitId?: string;
  allocatedPosition?: number;
  payoutPeriod?: number;
  confirmedAt?: Timestamp;
  revalidationFailureReason?: string;
}
