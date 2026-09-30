/**
 * Central Pool Domain Entity: PayoutEntitlement
 * Represents a member's mathematical disbursement rights derived from their confirmed position.
 * Note: PayoutEntitlement != AllocationPosition and PayoutEntitlement != PayoutSettlement.
 * Stored at: /payout_entitlements/{payoutEntitlementId}
 */

import { PayoutEntitlementStatus } from './financial_types';

export interface FinancialDisbursementSlot {
  /** Period number when this slot occurs in [1..N] */
  periodNumber: number;

  /** Entitlement amount for this slot in integer minor units */
  amountMinor: number;

  /** Proportion in basis points (5000 = 50%, 10000 = 100%) */
  basisPoints: number;

  /** True if this is an odd-cycle center single payout */
  isCenter: boolean;
}

export interface PayoutEntitlement {
  /** Deterministic entitlement ID: 'pe_' + SHA256(tenantId + ':' + allocationId) */
  payoutEntitlementId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID */
  memberUid: string;

  /** Allocation Unit ID */
  allocationUnitId: string;

  /** Confirmed Allocation Receipt ID */
  allocationId: string;

  /** Numerical position index in [1..N] */
  positionNumber: number;

  /** Total entitlement amount E = N * C in integer minor units */
  totalEntitlementMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Array of mathematical disbursement slots under SYMMETRICAL_V1 */
  splits: FinancialDisbursementSlot[];

  /** Entitlement status: SCHEDULED */
  status: PayoutEntitlementStatus;

  /** Timestamp when entitlement was calculated (RFC 3339 UTC) */
  calculatedAt: string;

  /** Optimistic concurrency version */
  version: number;
}
