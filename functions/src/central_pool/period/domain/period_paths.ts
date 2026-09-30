/**
 * Central Pool Firestore Collection Paths & Document Helpers for Period Projections
 * Reference: FIREBASE AUTHORITATIVE BACKEND BLUEPRINT (Step 7)
 */

import { USERS_COLLECTION, ALLOCATION_UNITS_COLLECTION } from '../../domain/domain_paths';

export const PERIOD_PROJECTIONS_SUBCOLLECTION = 'period_projections';

/**
 * Builds the canonical document path for a Member Period Projection receipt read-model.
 */
export function getMemberPeriodProjectionPath(userId: string, projectionId: string): string {
  return `${USERS_COLLECTION}/${userId}/${PERIOD_PROJECTIONS_SUBCOLLECTION}/${projectionId}`;
}

/**
 * Builds the canonical document path for a Unit Period Projection read-model.
 */
export function getUnitPeriodProjectionPath(unitId: string, projectionId: string): string {
  return `${ALLOCATION_UNITS_COLLECTION}/${unitId}/${PERIOD_PROJECTIONS_SUBCOLLECTION}/${projectionId}`;
}
