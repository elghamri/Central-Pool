// Phase 49: Central Pool Step 13 Financial & Projection Models Unit Test
// Invariant: Verifies model serialization, deserialization, idempotency generator, and lockdown semantics.

import 'package:flutter_test/flutter_test.dart';
import 'package:member_mobile_app/src/features/central_pool/models/financial_obligation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/contribution_schedule_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/contribution_event_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/payout_entitlement_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/period_projection_models.dart';
import 'package:member_mobile_app/src/features/central_pool/models/system_lockdown_model.dart';
import 'package:member_mobile_app/src/features/central_pool/services/idempotency_service.dart';

void main() {
  group('Central Pool Step 13 Models & Services Unit Tests', () {
    test('1. FinancialObligationModel Serialization & Deserialization', () {
      final json = {
        'obligationId': 'ob_test_001',
        'tenantId': 'tenant_cairo',
        'memberUid': 'mem_alice',
        'allocationUnitId': 'unit_001',
        'allocationId': 'alloc_001',
        'positionNumber': 2,
        'totalObligationMinor': 500000,
        'contributionMinor': 50000,
        'totalPeriods': 10,
        'fulfilledAmountMinor': 100000,
        'currency': 'EGP',
        'status': 'ACTIVE',
        'createdAt': '2026-09-07T12:00:00.000Z',
        'updatedAt': '2026-09-07T12:00:00.000Z',
        'version': 1,
      };

      final model = FinancialObligationModel.fromJson(json);
      expect(model.obligationId, 'ob_test_001');
      expect(model.tenantId, 'tenant_cairo');
      expect(model.memberUid, 'mem_alice');
      expect(model.positionNumber, 2);
      expect(model.totalObligationMinor, 500000);
      expect(model.contributionMinor, 50000);
      expect(model.totalPeriods, 10);
      expect(model.fulfilledAmountMinor, 100000);
      expect(model.status, 'ACTIVE');

      final serialized = model.toJson();
      expect(serialized['obligationId'], 'ob_test_001');
      expect(serialized['totalObligationMinor'], 500000);
    });

    test('2. ContributionScheduleModel Serialization & Deserialization', () {
      final json = {
        'scheduleId': 'cs_test_001',
        'obligationId': 'ob_test_001',
        'tenantId': 'tenant_cairo',
        'memberUid': 'mem_alice',
        'allocationUnitId': 'unit_001',
        'totalPeriods': 2,
        'periods': [
          {
            'periodNumber': 1,
            'scheduledAmountMinor': 50000,
            'status': 'RECORDED',
            'recordedAt': '2026-09-07T12:00:00.000Z',
            'contributionEventId': 'ce_001',
          },
          {
            'periodNumber': 2,
            'scheduledAmountMinor': 50000,
            'status': 'SCHEDULED',
          },
        ],
        'createdAt': '2026-09-07T12:00:00.000Z',
        'updatedAt': '2026-09-07T12:00:00.000Z',
        'version': 1,
      };

      final model = ContributionScheduleModel.fromJson(json);
      expect(model.scheduleId, 'cs_test_001');
      expect(model.periods.length, 2);
      expect(model.periods[0].status, 'RECORDED');
      expect(model.periods[0].contributionEventId, 'ce_001');
      expect(model.periods[1].status, 'SCHEDULED');
      expect(model.periods[1].recordedAt, isNull);

      final serialized = model.toJson();
      expect(serialized['periods'].length, 2);
    });

    test('3. ContributionEventModel Serialization & Deserialization', () {
      final json = {
        'contributionEventId': 'ce_test_001',
        'tenantId': 'tenant_cairo',
        'memberUid': 'mem_alice',
        'obligationId': 'ob_test_001',
        'allocationUnitId': 'unit_001',
        'periodNumber': 1,
        'amountMinor': 50000,
        'currency': 'EGP',
        'recordedAt': '2026-09-07T12:00:00.000Z',
        'journalEntryId': 'je_001',
        'idempotencyId': 'idem_event_001',
      };

      final model = ContributionEventModel.fromJson(json);
      expect(model.contributionEventId, 'ce_test_001');
      expect(model.amountMinor, 50000);
      expect(model.periodNumber, 1);
      expect(model.journalEntryId, 'je_001');
      expect(model.idempotencyId, 'idem_event_001');

      final serialized = model.toJson();
      expect(serialized['contributionEventId'], 'ce_test_001');
    });

    test('4. PayoutEntitlementModel Serialization & Deserialization', () {
      final json = {
        'payoutEntitlementId': 'pe_test_001',
        'tenantId': 'tenant_cairo',
        'memberUid': 'mem_alice',
        'allocationUnitId': 'unit_001',
        'allocationId': 'alloc_001',
        'positionNumber': 3,
        'totalEntitlementMinor': 500000,
        'currency': 'EGP',
        'splits': [
          {
            'periodNumber': 2,
            'amountMinor': 250000,
            'basisPoints': 5000,
            'isCenter': false,
          },
          {
            'periodNumber': 9,
            'amountMinor': 250000,
            'basisPoints': 5000,
            'isCenter': false,
          },
        ],
        'status': 'SCHEDULED',
        'calculatedAt': '2026-09-07T12:00:00.000Z',
        'version': 1,
      };

      final model = PayoutEntitlementModel.fromJson(json);
      expect(model.payoutEntitlementId, 'pe_test_001');
      expect(model.positionNumber, 3);
      expect(model.totalEntitlementMinor, 500000);
      expect(model.splits.length, 2);
      expect(model.splits[0].periodNumber, 2);
      expect(model.splits[0].amountMinor, 250000);
      expect(model.splits[0].basisPoints, 5000);
      expect(model.splits[1].periodNumber, 9);

      final serialized = model.toJson();
      expect(serialized['splits'].length, 2);
    });

    test('5. PeriodProjectionModels Serialization & Deserialization', () {
      final cycleJson = {
        'projectionId': 'cpp_test_001',
        'tenantId': 'tenant_cairo',
        'allocationUnitId': 'unit_001',
        'memberCount': 10,
        'periodicContributionMinor': 50000,
        'totalEntitlementMinor': 500000,
        'totalPotMinor': 5000000,
        'currency': 'EGP',
        'periods': [
          {
            'periodNumber': 1,
            'expectedContributionPoolMinor': 500000,
            'expectedDisbursementPoolMinor': 500000,
            'payoutSlots': [
              {
                'positionNumber': 1,
                'amountMinor': 250000,
                'basisPoints': 5000,
                'isCenter': false,
                'mirrorPosition': 10,
              },
            ],
            'isBalanced': true,
          }
        ],
        'isProjection': true,
        'classification': 'DERIVED_PROJECTION',
        'generatedAt': '2026-09-07T12:00:00.000Z',
      };

      final cycleModel = CyclePeriodProjectionModel.fromJson(cycleJson);
      expect(cycleModel.projectionId, 'cpp_test_001');
      expect(cycleModel.memberCount, 10);
      expect(cycleModel.totalPotMinor, 5000000);
      expect(cycleModel.periods.first.isBalanced, true);

      final memberTimelineJson = {
        'projectionId': 'mpp_test_001',
        'tenantId': 'tenant_cairo',
        'memberUid': 'mem_alice',
        'allocationId': 'alloc_001',
        'allocationUnitId': 'unit_001',
        'positionNumber': 3,
        'totalPeriods': 10,
        'periodicContributionMinor': 50000,
        'totalObligationMinor': 500000,
        'totalEntitlementMinor': 500000,
        'currency': 'EGP',
        'periods': [
          {
            'periodNumber': 2,
            'contribution': {
              'periodNumber': 2,
              'dueAmountMinor': 50000,
              'status': 'SCHEDULED',
            },
            'payout': {
              'entitledAmountMinor': 250000,
              'basisPoints': 5000,
              'isPayoutPeriod': true,
              'isCenter': false,
              'mirrorPeriod': 9,
            },
            'netEntitlementDeltaMinor': 200000,
          }
        ],
        'isProjection': true,
        'classification': 'DERIVED_PROJECTION',
        'generatedAt': '2026-09-07T12:00:00.000Z',
      };

      final memberModel = MemberPeriodProjectionModel.fromJson(memberTimelineJson);
      expect(memberModel.projectionId, 'mpp_test_001');
      expect(memberModel.positionNumber, 3);
      expect(memberModel.periods.first.netEntitlementDeltaMinor, 200000);
    });

    test('6. SystemLockdownModel Serialization & Deserialization', () {
      final json = {
        'lockdownId': 'lock_test_001',
        'tenantId': 'tenant_cairo',
        'isLocked': true,
        'reason': 'Scheduled maintenance window',
        'initiatedByUid': 'admin_001',
        'initiatedAt': '2026-09-07T12:00:00.000Z',
      };

      final model = SystemLockdownModel.fromJson(json);
      expect(model.lockdownId, 'lock_test_001');
      expect(model.isLocked, true);
      expect(model.reason, 'Scheduled maintenance window');
      expect(model.initiatedByUid, 'admin_001');
    });

    test('7. IdempotencyService Generates Valid UUID v4 & Unique Request IDs', () {
      final service = IdempotencyService();
      final key1 = service.generateKey(prefix: 'test');
      final key2 = service.generateKey(prefix: 'test');

      expect(key1, isNot(equals(key2)));
      expect(key1.startsWith('test-'), true);
      // Validate UUID v4 format
      final uuidPart = key1.substring(5);
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(uuidPart), true);

      final reqId = service.generateClientRequestId('mem_alice_01');
      expect(reqId.startsWith('req-memalice01-'), true);
    });
  });
}
