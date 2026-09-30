/**
 * Central Pool Step 6: Deterministic Financial Identity Computation
 * Adheres to RFC 8785 Canonical JSON and SHA-256 digests.
 */

import { canonicalJson, sha256Hex } from '../../matching/compatibility_key';
import { MissingTenantIdError } from '../../domain/domain_errors';
import { InvalidObligationError } from '../domain/financial_errors';

function requireNonEmpty(val: string, fieldName: string): void {
  if (!val || typeof val !== 'string' || val.trim().length === 0) {
    throw new InvalidObligationError(`${fieldName} must be a non-empty string`);
  }
}

/**
 * Computes deterministic Financial Obligation ID.
 * Formula: 'ob_' + SHA256(JCS({ allocationId, tenantId }))
 */
export function computeObligationId(tenantId: string, allocationId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeObligationId');
  }
  requireNonEmpty(allocationId, 'allocationId');

  const payload = {
    allocationId: allocationId.trim(),
    tenantId: tenantId.trim(),
  };
  return `ob_${sha256Hex(canonicalJson(payload))}`;
}

/**
 * Computes deterministic Contribution Schedule ID.
 * Formula: 'cs_' + SHA256(JCS({ obligationId, tenantId }))
 */
export function computeContributionScheduleId(tenantId: string, obligationId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeContributionScheduleId');
  }
  requireNonEmpty(obligationId, 'obligationId');

  const payload = {
    obligationId: obligationId.trim(),
    tenantId: tenantId.trim(),
  };
  return `cs_${sha256Hex(canonicalJson(payload))}`;
}

/**
 * Computes deterministic Contribution Event ID.
 * Formula: 'ce_' + SHA256(JCS({ obligationId, periodNumber, tenantId }))
 */
export function computeContributionEventId(tenantId: string, obligationId: string, periodNumber: number): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeContributionEventId');
  }
  requireNonEmpty(obligationId, 'obligationId');
  if (!Number.isSafeInteger(periodNumber) || periodNumber < 1) {
    throw new InvalidObligationError(`periodNumber must be positive integer >= 1, got ${periodNumber}`);
  }

  const payload = {
    obligationId: obligationId.trim(),
    periodNumber,
    tenantId: tenantId.trim(),
  };
  return `ce_${sha256Hex(canonicalJson(payload))}`;
}

/**
 * Computes deterministic Payout Entitlement ID.
 * Formula: 'pe_' + SHA256(JCS({ allocationId, tenantId }))
 */
export function computePayoutEntitlementId(tenantId: string, allocationId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computePayoutEntitlementId');
  }
  requireNonEmpty(allocationId, 'allocationId');

  const payload = {
    allocationId: allocationId.trim(),
    tenantId: tenantId.trim(),
  };
  return `pe_${sha256Hex(canonicalJson(payload))}`;
}

/**
 * Computes deterministic Accounting Journal Entry ID.
 * Formula: 'je_' + SHA256(JCS({ entryType, referenceId, tenantId }))
 */
export function computeJournalEntryId(tenantId: string, entryType: string, referenceId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeJournalEntryId');
  }
  requireNonEmpty(entryType, 'entryType');
  requireNonEmpty(referenceId, 'referenceId');

  const payload = {
    entryType: entryType.trim(),
    referenceId: referenceId.trim(),
    tenantId: tenantId.trim(),
  };
  return `je_${sha256Hex(canonicalJson(payload))}`;
}
