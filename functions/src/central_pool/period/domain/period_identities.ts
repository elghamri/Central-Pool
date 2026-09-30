/**
 * Central Pool Step 7: Deterministic Period Identity Computation
 * Adheres to RFC 8785 Canonical JSON and SHA-256 digests.
 */

import { canonicalJson, sha256Hex } from '../../matching/compatibility_key';
import { MissingTenantIdError } from '../../domain/domain_errors';
import { PeriodProjectionMismatchError } from './period_errors';

function requireNonEmpty(val: string, fieldName: string): void {
  if (!val || typeof val !== 'string' || val.trim().length === 0) {
    throw new PeriodProjectionMismatchError(`${fieldName} must be a non-empty string`);
  }
}

/**
 * Computes deterministic Cycle Period Projection ID.
 * Formula: 'cpp_' + SHA256(JCS({ allocationUnitId, tenantId }))
 */
export function computeCyclePeriodProjectionId(tenantId: string, allocationUnitId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeCyclePeriodProjectionId');
  }
  requireNonEmpty(allocationUnitId, 'allocationUnitId');

  const payload = {
    allocationUnitId: allocationUnitId.trim(),
    tenantId: tenantId.trim(),
  };
  return `cpp_${sha256Hex(canonicalJson(payload))}`;
}

/**
 * Computes deterministic Member Period Projection ID.
 * Formula: 'mpp_' + SHA256(JCS({ allocationId, tenantId }))
 */
export function computeMemberPeriodProjectionId(tenantId: string, allocationId: string): string {
  if (!tenantId || typeof tenantId !== 'string') {
    throw new MissingTenantIdError('computeMemberPeriodProjectionId');
  }
  requireNonEmpty(allocationId, 'allocationId');

  const payload = {
    allocationId: allocationId.trim(),
    tenantId: tenantId.trim(),
  };
  return `mpp_${sha256Hex(canonicalJson(payload))}`;
}
