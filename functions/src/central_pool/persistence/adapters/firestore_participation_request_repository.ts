/**
 * Concrete Firestore Adapter: FirestoreParticipationRequestRepository
 * Implements ParticipationRequestRepository with strict tenant isolation, immutable field protection, and state guards.
 */

import { Firestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import {
  ParticipationRequest,
  PersistedParticipationRequestState,
  getParticipationRequestPath,
  validateParticipationRequestStateTransition,
  PARTICIPATION_REQUESTS_COLLECTION,
} from '../../domain';
import { ParticipationRequestRepository } from '../ports/participation_request_repository';
import {
  participationRequestToDoc,
  docToParticipationRequest,
  isoStringToTimestamp,
} from '../dto/dto_converters';
import {
  TenantIsolationViolationError,
  EntityNotFoundError,
  DuplicateEntityError,
  InvalidPersistenceStateError,
  ImmutableFieldMutationError,
} from '../persistence_errors';

export class FirestoreParticipationRequestRepository implements ParticipationRequestRepository {
  constructor(private readonly db: Firestore) {}

  async createSubmittedRequest(tenantId: string, request: ParticipationRequest): Promise<void> {
    if (!tenantId || request.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, request.tenantId, 'ParticipationRequest');
    }

    if (request.status !== 'SUBMITTED') {
      throw new InvalidPersistenceStateError(
        `New participation request must be persisted in 'SUBMITTED' state, got '${request.status}'`
      );
    }

    const path = getParticipationRequestPath(request.requestId);
    const docRef = this.db.doc(path);

    const docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      throw new DuplicateEntityError('ParticipationRequest', request.requestId);
    }

    const docData = participationRequestToDoc(request, true);
    await docRef.set(docData);
  }

  async getRequest(tenantId: string, requestId: string): Promise<ParticipationRequest | null> {
    const path = getParticipationRequestPath(requestId);
    const docSnapshot = await this.db.doc(path).get();

    if (!docSnapshot.exists) {
      return null;
    }

    const data = docSnapshot.data();
    if (!data) return null;

    const request = docToParticipationRequest(data);
    if (request.tenantId !== tenantId) {
      throw new TenantIsolationViolationError(tenantId, request.tenantId, 'ParticipationRequest');
    }

    return request;
  }

  async updateRequestState(
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
  ): Promise<void> {
    const path = getParticipationRequestPath(requestId);
    const docRef = this.db.doc(path);

    await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        throw new EntityNotFoundError('ParticipationRequest', requestId);
      }

      const current = docToParticipationRequest(snap.data()!);
      if (current.tenantId !== tenantId) {
        throw new TenantIsolationViolationError(tenantId, current.tenantId, 'ParticipationRequest');
      }

      if (current.status !== expectedCurrentState) {
        throw new InvalidPersistenceStateError(
          `Request '${requestId}' is in state '${current.status}', expected '${expectedCurrentState}'`
        );
      }

      // Guard state transition via domain rules
      validateParticipationRequestStateTransition(current.status, targetState);

      const updates: Record<string, any> = {
        status: targetState,
        version: current.version + 1,
        updatedAt: FieldValue.serverTimestamp(),
      };

      if (stampedData?.allocationUnitId !== undefined) {
        updates.allocationUnitId = stampedData.allocationUnitId;
      }
      if (stampedData?.allocatedPosition !== undefined) {
        updates.allocatedPosition = stampedData.allocatedPosition;
      }
      if (stampedData?.payoutPeriod !== undefined) {
        updates.payoutPeriod = stampedData.payoutPeriod;
      }
      if (stampedData?.confirmedAt !== undefined) {
        updates.confirmedAt = isoStringToTimestamp(stampedData.confirmedAt, 'confirmedAt');
      }
      if (stampedData?.revalidationFailureReason !== undefined) {
        updates.revalidationFailureReason = stampedData.revalidationFailureReason;
      }

      tx.update(docRef, updates);
    });
  }

  async listMemberRequests(tenantId: string, memberUid: string): Promise<ParticipationRequest[]> {
    if (!tenantId) {
      throw new TenantIsolationViolationError('non-empty tenantId', '', 'ParticipationRequest');
    }

    const querySnap = await this.db
      .collection(PARTICIPATION_REQUESTS_COLLECTION)
      .where('tenantId', '==', tenantId)
      .where('memberUid', '==', memberUid)
      .get();

    return querySnap.docs.map((doc) => docToParticipationRequest(doc.data()));
  }
}
