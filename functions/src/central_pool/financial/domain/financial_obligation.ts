/**
 * Central Pool Domain Entity: FinancialObligation
 *
 * PROVENANCE & SEMANTIC DEFINITION:
 * - Meaning A (Internal accounting/simulation obligation):
 *   A backend-recorded expected financial contribution commitment inside the Central Pool accounting model.
 *   It records expected member contribution schedules, NOT legal liability, custody, external debt, or real-money settlement.
 *   FM-02 (Legal/Custody Structure) remains strictly UNRESOLVED.
 * - Stored at: /financial_obligations/{obligationId}
 */

import { FinancialObligationStatus } from './financial_types';

export interface FinancialObligation {
  /** Deterministic obligation ID: 'ob_' + SHA256(tenantId + ':' + allocationId) */
  obligationId: string;

  /** Mandatory tenant boundary */
  tenantId: string;

  /** Member user ID owning this obligation */
  memberUid: string;

  /** Allocation Unit ID generating this obligation */
  allocationUnitId: string;

  /** Confirmed Allocation Receipt ID */
  allocationId: string;

  /** Numerical position index in [1..N] */
  positionNumber: number;

  /** Total obligation amount E = N * C in integer minor units */
  totalObligationMinor: number;

  /** Periodic contribution amount C in integer minor units */
  contributionMinor: number;

  /** Total cycle periods N in [2..12] */
  totalPeriods: number;

  /** Cumulative fulfilled contribution amount in integer minor units */
  fulfilledAmountMinor: number;

  /** ISO 4217 Currency Code */
  currency: string;

  /** Obligation lifecycle status: ACTIVE | FULFILLED | DEFAULTED */
  status: FinancialObligationStatus;

  /** Creation timestamp (RFC 3339 UTC) */
  createdAt: string;

  /** Last update timestamp (RFC 3339 UTC) */
  updatedAt: string;

  /** Optimistic concurrency version */
  version: number;
}
