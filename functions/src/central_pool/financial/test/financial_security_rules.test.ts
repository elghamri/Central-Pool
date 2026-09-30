/**
 * Central Pool Step 6: Security Rules Boundary Verification Test Suite
 * Asserts structural and behavioral compliance of firestore.rules for Step 6 Financial collections.
 */

import { describe, it } from 'node:test';
import * as assert from 'node:assert/strict';
import * as fs from 'node:fs';
import * as path from 'node:path';

describe('CENTRAL POOL — Step 6: Firestore Security Rules Financial Boundary Verification', () => {
  const rulesPath = path.resolve(__dirname, '../../../../../firestore.rules');
  const rulesContent = fs.readFileSync(rulesPath, 'utf8');

  it('declares rules_version = 2', () => {
    assert.ok(rulesContent.includes("rules_version = '2';"));
  });

  it('guards /financial_obligations with server-only writes and member/staff read boundary', () => {
    assert.ok(rulesContent.includes('match /financial_obligations/{obligationId}'));
    const block = rulesContent.substring(rulesContent.indexOf('match /financial_obligations/{obligationId}'));
    assert.ok(block.includes('resource.data.memberUid == request.auth.uid || isStaff()'));
    assert.ok(block.includes('allow write: if isServerOnly();'));
  });

  it('guards /contribution_schedules with server-only writes and member/staff read boundary', () => {
    assert.ok(rulesContent.includes('match /contribution_schedules/{scheduleId}'));
    const block = rulesContent.substring(rulesContent.indexOf('match /contribution_schedules/{scheduleId}'));
    assert.ok(block.includes('resource.data.memberUid == request.auth.uid || isStaff()'));
    assert.ok(block.includes('allow write: if isServerOnly();'));
  });

  it('guards /contribution_events with server-only writes and member/staff read boundary', () => {
    assert.ok(rulesContent.includes('match /contribution_events/{eventId}'));
    const block = rulesContent.substring(rulesContent.indexOf('match /contribution_events/{eventId}'));
    assert.ok(block.includes('resource.data.memberUid == request.auth.uid || isStaff()'));
    assert.ok(block.includes('allow write: if isServerOnly();'));
  });

  it('guards /payout_entitlements with server-only writes and member/staff read boundary', () => {
    assert.ok(rulesContent.includes('match /payout_entitlements/{entitlementId}'));
    const block = rulesContent.substring(rulesContent.indexOf('match /payout_entitlements/{entitlementId}'));
    assert.ok(block.includes('resource.data.memberUid == request.auth.uid || isStaff()'));
    assert.ok(block.includes('allow write: if isServerOnly();'));
  });

  it('guards /accounting_journal_entries with server-only writes and staff-only read boundary', () => {
    assert.ok(rulesContent.includes('match /accounting_journal_entries/{journalEntryId}'));
    const block = rulesContent.substring(rulesContent.indexOf('match /accounting_journal_entries/{journalEntryId}'));
    assert.ok(block.includes('allow read: if isStaff();'));
    assert.ok(block.includes('allow write: if isServerOnly();'));
  });

  it('guards /users/{userId}/financial_obligations and /payout_entitlements user projection subcollections', () => {
    const userBlock = rulesContent.substring(
      rulesContent.indexOf('match /users/{userId}'),
      rulesContent.indexOf('match /gameya_circles/{circleId}')
    );
    assert.ok(userBlock.includes('match /financial_obligations/{obligationId}'));
    assert.ok(userBlock.includes('match /payout_entitlements/{entitlementId}'));
    assert.ok(userBlock.includes('allow read: if isUser(userId) || isStaff();'));
    assert.ok(userBlock.includes('allow write: if isServerOnly();'));
  });
});
