/**
 * Central Pool Domain States & Transition Taxonomy
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT v1.8
 */

export type ParticipationRequestState =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'ANALYZING'
  | 'MATCHED'
  | 'AWAITING_SELECTION'
  | 'REVALIDATING'
  | 'CONFIRMED'
  | 'EXPIRED'
  | 'CANCELLED'
  | 'NO_MATCH'
  | 'REVALIDATION_FAILED';

export type PersistedParticipationRequestState =
  | 'SUBMITTED'
  | 'AWAITING_SELECTION'
  | 'REVALIDATING'
  | 'CONFIRMED'
  | 'EXPIRED'
  | 'CANCELLED'
  | 'NO_MATCH'
  | 'REVALIDATION_FAILED';

/**
 * States that are permitted to be stored in Firestore documents under /participation_requests.
 * DRAFT is client-local. ANALYZING is in-memory transient. MATCHED is a domain alias for AWAITING_SELECTION.
 */
export const PERSISTED_PARTICIPATION_REQUEST_STATES: ReadonlySet<PersistedParticipationRequestState> = new Set([
  'SUBMITTED',
  'AWAITING_SELECTION',
  'REVALIDATING',
  'CONFIRMED',
  'EXPIRED',
  'CANCELLED',
  'NO_MATCH',
  'REVALIDATION_FAILED',
]);

export const TERMINAL_PARTICIPATION_REQUEST_STATES: ReadonlySet<ParticipationRequestState> = new Set([
  'CONFIRMED',
  'EXPIRED',
  'CANCELLED',
  'NO_MATCH',
]);

export type AllocationUnitState =
  | 'FORMING'
  | 'COMMITTED_FULL'
  | 'DEFECT_QUARANTINE';

export const TERMINAL_FORMATION_STATES: ReadonlySet<AllocationUnitState> = new Set([
  'COMMITTED_FULL',
]);

/**
 * Authoritative State Transition Graph for Participation Requests.
 * Maps current state to all permissible next states.
 */
export const LEGAL_PARTICIPATION_REQUEST_TRANSITIONS: Readonly<Record<ParticipationRequestState, ReadonlySet<ParticipationRequestState>>> = {
  DRAFT: new Set(['SUBMITTED', 'CANCELLED']),
  SUBMITTED: new Set(['AWAITING_SELECTION', 'NO_MATCH', 'CANCELLED', 'EXPIRED', 'ANALYZING', 'MATCHED']),
  ANALYZING: new Set(['AWAITING_SELECTION', 'NO_MATCH', 'CANCELLED', 'EXPIRED', 'MATCHED']),
  MATCHED: new Set(['AWAITING_SELECTION', 'CANCELLED', 'EXPIRED']),
  AWAITING_SELECTION: new Set(['REVALIDATING', 'AWAITING_SELECTION', 'CANCELLED', 'EXPIRED']),
  REVALIDATING: new Set(['CONFIRMED', 'REVALIDATION_FAILED']),
  REVALIDATION_FAILED: new Set(['AWAITING_SELECTION', 'CANCELLED', 'EXPIRED', 'ANALYZING', 'MATCHED']),
  CONFIRMED: new Set(), // Terminal: No further transitions allowed
  EXPIRED: new Set(),   // Terminal: No further transitions allowed
  CANCELLED: new Set(), // Terminal: No further transitions allowed
  NO_MATCH: new Set(),  // Terminal: No further transitions allowed
};

/**
 * Authoritative State Transition Graph for Allocation Units (Formation Phase).
 */
export const LEGAL_ALLOCATION_UNIT_TRANSITIONS: Readonly<Record<AllocationUnitState, ReadonlySet<AllocationUnitState>>> = {
  FORMING: new Set(['FORMING', 'COMMITTED_FULL', 'DEFECT_QUARANTINE']),
  COMMITTED_FULL: new Set(['DEFECT_QUARANTINE']), // Terminal for formation; can only enter defect quarantine on reconciliation anomaly
  DEFECT_QUARANTINE: new Set(), // Frozen quarantine: Requires manual engineering review
};
