/**
 * Central Pool Step 8: Cloud Functions v2 Callable Functions
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 8)
 *
 * PROVENANCE & SEMANTIC BOUNDARY:
 * - Public API endpoints providing authenticated access to Central Pool use cases.
 * - Extracts trusted auth claims (uid, tenantId, role).
 * - Zero real-money movement, zero payment processing, zero settlement.
 */

import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { CentralPoolApplicationService } from './central_pool_application_service';
import { mapToHttpsError } from './api_errors';
import {
  TrustedAuthContext,
  UserRole,
  SubmitParticipationRequestInput,
  GetMatchingCandidatesInput,
  SelectCandidateAndConfirmInput,
  GetFinancialObligationInput,
  GetContributionScheduleInput,
  GetContributionEventsInput,
  GetPayoutEntitlementInput,
  GetCyclePeriodProjectionInput,
  GetMemberPeriodTimelineInput,
} from './application_types';

let appServiceInstance: CentralPoolApplicationService | null = null;

function getApplicationService(): CentralPoolApplicationService {
  if (!appServiceInstance) {
    const db = admin.firestore();
    appServiceInstance = new CentralPoolApplicationService(db);
  }
  return appServiceInstance;
}

export const VALID_USER_ROLES: ReadonlySet<UserRole> = new Set([
  'MEMBER',
  'ADMIN',
  'FINOPS',
  'COMPLIANCE',
  'SECURITY',
  'AUDITOR',
]);

/**
 * Extracts and verifies trusted auth identity from Firebase Auth token.
 */
export function extractTrustedAuthContext(request: CallableRequest<any>): TrustedAuthContext {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated to invoke Central Pool operations.');
  }

  const uid = request.auth.uid;
  if (!uid || typeof uid !== 'string' || !uid.trim()) {
    throw new HttpsError('unauthenticated', 'User auth token is missing a valid UID.');
  }

  const token = request.auth.token || {};
  const rawTenantId = token.tenantId ?? token.tenant_id;
  if (!rawTenantId || typeof rawTenantId !== 'string' || !rawTenantId.trim()) {
    throw new HttpsError('unauthenticated', 'User auth token is missing a valid tenantId claim.');
  }
  const tenantId = rawTenantId.trim();

  let role: UserRole = 'MEMBER';
  if (token.role !== undefined && token.role !== null) {
    if (typeof token.role !== 'string' || !VALID_USER_ROLES.has(token.role as UserRole)) {
      throw new HttpsError('unauthenticated', `Invalid user role claim: '${token.role}'.`);
    }
    role = token.role as UserRole;
  }

  const email = token.email as string | undefined;

  return {
    uid: uid.trim(),
    tenantId,
    role,
    email,
  };
}

// =============================================================================
// 1. SUBMIT PARTICIPATION REQUEST
// =============================================================================

export const submitParticipationRequestCallable = onCall(async (request: CallableRequest<SubmitParticipationRequestInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.submitParticipationRequest(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

// =============================================================================
// 2. GET MATCHING CANDIDATES
// =============================================================================

export const getMatchingCandidatesCallable = onCall(async (request: CallableRequest<GetMatchingCandidatesInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getMatchingCandidates(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

// =============================================================================
// 3. SELECT CANDIDATE AND CONFIRM
// =============================================================================

export const selectCandidateAndConfirmCallable = onCall(async (request: CallableRequest<SelectCandidateAndConfirmInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.selectCandidateAndConfirm(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

// =============================================================================
// 4. FINANCIAL FOUNDATION READS
// =============================================================================

export const getFinancialObligationCallable = onCall(async (request: CallableRequest<GetFinancialObligationInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getFinancialObligation(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

export const getContributionScheduleCallable = onCall(async (request: CallableRequest<GetContributionScheduleInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getContributionSchedule(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

export const getContributionEventsCallable = onCall(async (request: CallableRequest<GetContributionEventsInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getContributionEvents(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

export const getPayoutEntitlementCallable = onCall(async (request: CallableRequest<GetPayoutEntitlementInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getPayoutEntitlement(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

// =============================================================================
// 5. PERIOD PROJECTION READS
// =============================================================================

export const getCyclePeriodProjectionCallable = onCall(async (request: CallableRequest<GetCyclePeriodProjectionInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getCyclePeriodProjection(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});

export const getMemberPeriodTimelineCallable = onCall(async (request: CallableRequest<GetMemberPeriodTimelineInput>) => {
  try {
    const auth = extractTrustedAuthContext(request);
    const service = getApplicationService();
    return await service.getMemberPeriodTimeline(auth, request.data);
  } catch (error) {
    throw mapToHttpsError(error);
  }
});
