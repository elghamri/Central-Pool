/**
 * Repository Interface: ParticipationRequestRepository
 * Manages lifecycle persistence of member Participation Requests under /participation_requests.
 */

import { ParticipationRequest, ParticipationRequestState, PersistedParticipationRequestState } from '../../domain';

export interface ParticipationRequestRepository {
  /**
   * Persists a newly submitted Participation Request.
   * Enforces status === 'SUBMITTED', generates server timestamps, and rejects duplicates.
   */
  createSubmittedRequest(tenantId: string, request: ParticipationRequest): Promise<void>;

  /**
   * Retrieves an authoritative Participation Request by ID.
   * Enforces tenant isolation.
   */
  getRequest(tenantId: string, requestId: string): Promise<ParticipationRequest | null>;

  /**
   * Transitions the lifecycle state of a Participation Request.
   * Enforces legal state machine transitions and guards immutable fields.
   */
  updateRequestState(
    tenantId: string,
    requestId: string,
    expectedCurrentState: PersistedParticipationRequestState,
    targetState: PersistedParticipationRequestState,
    stampedData?: {
      allocationUnitId?: string;
      allocatedPosition?: number;
      payoutPeriod?: number;
      confirmedAt?: string;
      revalidationFailureReason?: string;
    }
  ): Promise<void>;

  /**
   * Retrieves active requests for a member within a tenant.
   */
  listMemberRequests(tenantId: string, memberUid: string): Promise<ParticipationRequest[]>;
}
