/**
 * Central Pool Firestore Collection Paths & Document Helpers
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT v1.8
 */

export const PARTICIPATION_REQUESTS_COLLECTION = 'participation_requests';
export const ALLOCATION_UNITS_COLLECTION = 'allocation_units';
export const ALLOCATION_POSITIONS_SUBCOLLECTION = 'positions';
export const ALLOCATION_UNIT_INDEXES_COLLECTION = 'allocation_unit_indexes';
export const IDEMPOTENCY_RECORDS_COLLECTION = 'idempotency_records';
export const USERS_COLLECTION = 'users';
export const ALLOCATIONS_SUBCOLLECTION = 'allocations';
export const AUDIT_LOGS_COLLECTION = 'audit_logs';

// Financial Foundation Collections (Step 6)
export const FINANCIAL_OBLIGATIONS_COLLECTION = 'financial_obligations';
export const CONTRIBUTION_SCHEDULES_COLLECTION = 'contribution_schedules';
export const CONTRIBUTION_EVENTS_COLLECTION = 'contribution_events';
export const PAYOUT_ENTITLEMENTS_COLLECTION = 'payout_entitlements';
export const ACCOUNTING_JOURNAL_ENTRIES_COLLECTION = 'accounting_journal_entries';

export const FINANCIAL_OBLIGATIONS_SUBCOLLECTION = 'financial_obligations';
export const PAYOUT_ENTITLEMENTS_SUBCOLLECTION = 'payout_entitlements';

/**
 * Builds the canonical document path for a Participation Request.
 */
export function getParticipationRequestPath(requestId: string): string {
  return `${PARTICIPATION_REQUESTS_COLLECTION}/${requestId}`;
}

/**
 * Builds the canonical document path for an Allocation Unit.
 */
export function getAllocationUnitPath(unitId: string): string {
  return `${ALLOCATION_UNITS_COLLECTION}/${unitId}`;
}

/**
 * Builds the canonical document path for an Allocation Position occupancy document.
 */
export function getPositionPath(unitId: string, positionNumber: number): string {
  return `${ALLOCATION_UNITS_COLLECTION}/${unitId}/${ALLOCATION_POSITIONS_SUBCOLLECTION}/${positionNumber}`;
}

/**
 * Builds the canonical document path for a Compatibility Index pointer.
 */
export function getAllocationUnitIndexPath(compatibilityKey: string): string {
  return `${ALLOCATION_UNIT_INDEXES_COLLECTION}/${compatibilityKey}`;
}

/**
 * Builds the canonical document path for an Idempotency Record.
 */
export function getIdempotencyRecordPath(recordId: string): string {
  return `${IDEMPOTENCY_RECORDS_COLLECTION}/${recordId}`;
}

/**
 * Builds the canonical document path for a Member Allocation Receipt read-model.
 */
export function getAllocationReceiptPath(userId: string, allocationId: string): string {
  return `${USERS_COLLECTION}/${userId}/${ALLOCATIONS_SUBCOLLECTION}/${allocationId}`;
}

/**
 * Builds the canonical document path for a Financial Obligation.
 */
export function getFinancialObligationPath(obligationId: string): string {
  return `${FINANCIAL_OBLIGATIONS_COLLECTION}/${obligationId}`;
}

/**
 * Builds the canonical document path for a Contribution Schedule.
 */
export function getContributionSchedulePath(scheduleId: string): string {
  return `${CONTRIBUTION_SCHEDULES_COLLECTION}/${scheduleId}`;
}

/**
 * Builds the canonical document path for a Contribution Event.
 */
export function getContributionEventPath(eventId: string): string {
  return `${CONTRIBUTION_EVENTS_COLLECTION}/${eventId}`;
}

/**
 * Builds the canonical document path for a Payout Entitlement.
 */
export function getPayoutEntitlementPath(entitlementId: string): string {
  return `${PAYOUT_ENTITLEMENTS_COLLECTION}/${entitlementId}`;
}

/**
 * Builds the canonical document path for an Accounting Journal Entry.
 */
export function getAccountingJournalEntryPath(journalEntryId: string): string {
  return `${ACCOUNTING_JOURNAL_ENTRIES_COLLECTION}/${journalEntryId}`;
}

/**
 * Builds the canonical document path for a Member Financial Obligation presentation receipt.
 */
export function getMemberObligationReceiptPath(userId: string, obligationId: string): string {
  return `${USERS_COLLECTION}/${userId}/${FINANCIAL_OBLIGATIONS_SUBCOLLECTION}/${obligationId}`;
}

/**
 * Builds the canonical document path for a Member Payout Entitlement presentation receipt.
 */
export function getMemberPayoutEntitlementReceiptPath(userId: string, entitlementId: string): string {
  return `${USERS_COLLECTION}/${userId}/${PAYOUT_ENTITLEMENTS_SUBCOLLECTION}/${entitlementId}`;
}
