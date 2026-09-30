// Phase 51: Central Pool Step 13 Complete Member Journey Integration Test
// Invariant: Verifies complete 9-operation client journey with mocked backend callable contract responses.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/state/central_pool_controller.dart';
import 'package:member_mobile_app/src/features/central_pool/services/idempotency_service.dart';

void main() {
  group('Central Pool Step 13 Full Journey Integration Test', () {
    test('Executes all 9 canonical operations and reacts to lockdown', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        // 1. Submit Participation Request
        if (path == '/api/v1/participation-requests' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'result': {
                'request': {
                  'requestId': 'req_journey_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'contributionMinor': 50000,
                  'durationPeriods': 10,
                  'payoutPreference': 3,
                  'currency': 'EGP',
                  'status': 'SUBMITTED',
                  'submittedAt': '2026-09-07T12:00:00.000Z',
                  'expiresAt': '2026-09-08T12:00:00.000Z',
                  'version': 1,
                  'clientRequestId': 'idem_sub_001',
                }
              }
            }),
            201,
          );
        }

        // 2. Get Candidates
        if (path == '/api/v1/participation-requests/req_journey_001/candidates') {
          return http.Response(
            jsonEncode({
              'result': {
                'candidates': [
                  {
                    'candidate_id': 'cand_journey_001',
                    'request_id': 'req_journey_001',
                    'tenant_id': 'tenant_cairo',
                    'allocation_unit_id': 'unit_journey_001',
                    'schedule_id': 'sched_journey_001',
                    'prospective_position': 3,
                    'primary_period': 2,
                    'mirror_period': 9,
                    'allocation_mode': 'STANDARD_SPLIT',
                    'total_entitlement_minor': 500000,
                    'primary_amount_minor': 250000,
                    'mirror_amount_minor': 250000,
                    'currency': 'EGP',
                    'is_center_aggregated': false,
                    'created_at': '2026-09-07T12:00:00.000Z',
                    'expires_at': '2026-09-07T12:15:00.000Z',
                    'candidate_signature': 'sig_valid_journey_001',
                  }
                ]
              }
            }),
            200,
          );
        }

        // 3. Select Candidate & Confirm
        if (path == '/api/v1/participation-requests/req_journey_001/select') {
          return http.Response(
            jsonEncode({
              'result': {
                'request_id': 'req_journey_001',
                'tenant_id': 'tenant_cairo',
                'member_id': 'mem_alice',
                'allocation_unit_id': 'unit_journey_001',
                'schedule_id': 'sched_journey_001',
                'confirmed_position_number': 3,
                'primary_period': 2,
                'mirror_period': 9,
                'monthly_contribution_minor': 50000,
                'total_entitlement_minor': 500000,
                'primary_amount_minor': 250000,
                'mirror_amount_minor': 250000,
                'currency': 'EGP',
                'confirmed_at': '2026-09-07T12:05:00.000Z',
                'status': 'CONFIRMED',
                'obligationId': 'ob_journey_001',
              }
            }),
            200,
          );
        }

        // 4. Get Financial Obligation
        if (path == '/api/v1/financial-obligations') {
          return http.Response(
            jsonEncode({
              'result': {
                'obligation': {
                  'obligationId': 'ob_journey_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationUnitId': 'unit_journey_001',
                  'allocationId': 'alloc_journey_001',
                  'positionNumber': 3,
                  'totalObligationMinor': 500000,
                  'contributionMinor': 50000,
                  'totalPeriods': 10,
                  'fulfilledAmountMinor': 50000,
                  'currency': 'EGP',
                  'status': 'ACTIVE',
                  'createdAt': '2026-09-07T12:05:00.000Z',
                  'updatedAt': '2026-09-07T12:05:00.000Z',
                  'version': 1,
                }
              }
            }),
            200,
          );
        }

        // 5. Get Contribution Schedule
        if (path == '/api/v1/contribution-schedules') {
          return http.Response(
            jsonEncode({
              'result': {
                'schedule': {
                  'scheduleId': 'cs_journey_001',
                  'obligationId': 'ob_journey_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationUnitId': 'unit_journey_001',
                  'totalPeriods': 10,
                  'periods': [
                    {
                      'periodNumber': 1,
                      'scheduledAmountMinor': 50000,
                      'status': 'RECORDED',
                      'recordedAt': '2026-09-07T12:10:00.000Z',
                      'contributionEventId': 'ce_journey_001',
                    },
                    for (int i = 2; i <= 10; i++)
                      {
                        'periodNumber': i,
                        'scheduledAmountMinor': 50000,
                        'status': 'SCHEDULED',
                      }
                  ],
                  'createdAt': '2026-09-07T12:05:00.000Z',
                  'updatedAt': '2026-09-07T12:05:00.000Z',
                  'version': 1,
                }
              }
            }),
            200,
          );
        }

        // 6. Get Contribution Events
        if (path == '/api/v1/contribution-events') {
          return http.Response(
            jsonEncode({
              'result': {
                'obligationId': 'ob_journey_001',
                'events': [
                  {
                    'contributionEventId': 'ce_journey_001',
                    'tenantId': 'tenant_cairo',
                    'memberUid': 'mem_alice',
                    'obligationId': 'ob_journey_001',
                    'allocationUnitId': 'unit_journey_001',
                    'periodNumber': 1,
                    'amountMinor': 50000,
                    'currency': 'EGP',
                    'recordedAt': '2026-09-07T12:10:00.000Z',
                    'idempotencyId': 'idem_ce_journey_001',
                  }
                ],
                'totalEvents': 1,
              }
            }),
            200,
          );
        }

        // 7. Get Payout Entitlement
        if (path == '/api/v1/payout-entitlements') {
          return http.Response(
            jsonEncode({
              'result': {
                'entitlement': {
                  'payoutEntitlementId': 'pe_journey_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationUnitId': 'unit_journey_001',
                  'allocationId': 'alloc_journey_001',
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
                    }
                  ],
                  'status': 'SCHEDULED',
                  'calculatedAt': '2026-09-07T12:05:00.000Z',
                  'version': 1,
                }
              }
            }),
            200,
          );
        }

        // 8. Get Cycle Period Projection
        if (path == '/api/v1/cycle-projections') {
          return http.Response(
            jsonEncode({
              'result': {
                'projection': {
                  'projectionId': 'cpp_journey_001',
                  'tenantId': 'tenant_cairo',
                  'allocationUnitId': 'unit_journey_001',
                  'memberCount': 10,
                  'periodicContributionMinor': 50000,
                  'totalEntitlementMinor': 500000,
                  'totalPotMinor': 5000000,
                  'currency': 'EGP',
                  'periods': [
                    for (int p = 1; p <= 10; p++)
                      {
                        'periodNumber': p,
                        'expectedContributionPoolMinor': 500000,
                        'expectedDisbursementPoolMinor': 500000,
                        'payoutSlots': [
                          {
                            'positionNumber': p,
                            'amountMinor': 250000,
                            'basisPoints': 5000,
                            'isCenter': false,
                            'mirrorPosition': 11 - p,
                          }
                        ],
                        'isBalanced': true,
                      }
                  ],
                  'isProjection': true,
                  'classification': 'DERIVED_PROJECTION',
                  'generatedAt': '2026-09-07T12:05:00.000Z',
                }
              }
            }),
            200,
          );
        }

        // 9. Get Member Period Timeline
        if (path == '/api/v1/member-timelines') {
          return http.Response(
            jsonEncode({
              'result': {
                'projection': {
                  'projectionId': 'mpp_journey_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationId': 'alloc_journey_001',
                  'allocationUnitId': 'unit_journey_001',
                  'positionNumber': 3,
                  'totalPeriods': 10,
                  'periodicContributionMinor': 50000,
                  'totalObligationMinor': 500000,
                  'totalEntitlementMinor': 500000,
                  'currency': 'EGP',
                  'periods': [
                    for (int p = 1; p <= 10; p++)
                      {
                        'periodNumber': p,
                        'contribution': {
                          'periodNumber': p,
                          'dueAmountMinor': 50000,
                          'status': p == 1 ? 'RECORDED' : 'SCHEDULED',
                        },
                        'payout': {
                          'entitledAmountMinor': (p == 2 || p == 9) ? 250000 : 0,
                          'basisPoints': (p == 2 || p == 9) ? 5000 : 0,
                          'isPayoutPeriod': (p == 2 || p == 9),
                          'isCenter': false,
                          'mirrorPeriod': p == 2 ? 9 : (p == 9 ? 2 : null),
                        },
                        'netEntitlementDeltaMinor': (p == 2 || p == 9) ? 200000 : -50000,
                      }
                  ],
                  'isProjection': true,
                  'classification': 'DERIVED_PROJECTION',
                  'generatedAt': '2026-09-07T12:05:00.000Z',
                }
              }
            }),
            200,
          );
        }

        // 10. Get System Lockdown
        if (path == '/api/v1/system-lockdowns') {
          return http.Response(
            jsonEncode({
              'result': {
                'lockdownId': 'lock_journey_001',
                'tenantId': 'tenant_cairo',
                'isLocked': false,
                'reason': 'Normal operational mode',
                'initiatedAt': '2026-09-07T12:00:00.000Z',
              }
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
      final idempotency = IdempotencyService();
      final controller = CentralPoolController(
        repository: repo,
        idempotencyService: idempotency,
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      // Step 1: Submit Participation Request
      await controller.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 3,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
      );
      expect(controller.step, CentralPoolFlowStep.matching);
      expect(controller.currentRequest?.requestId, 'req_journey_001');

      // Step 2: Load Candidates
      await controller.loadCandidates();
      expect(controller.step, CentralPoolFlowStep.candidateList);
      expect(controller.candidates.length, 1);
      final selectedCand = controller.candidates.first;
      expect(selectedCand.prospectivePosition, 3);

      // Step 3: Select Candidate and Confirm
      await controller.confirmSelection(candidate: selectedCand);
      expect(controller.step, CentralPoolFlowStep.confirmed);
      expect(controller.confirmationResult?.status, 'CONFIRMED');
      expect(controller.confirmationResult?.confirmedPositionNumber, 3);

      // Step 4: Load Financial Obligation
      await controller.loadFinancialObligation(obligationId: 'ob_journey_001');
      expect(controller.financialObligation?.obligationId, 'ob_journey_001');
      expect(controller.financialObligation?.totalObligationMinor, 500000);
      expect(controller.financialObligation?.status, 'ACTIVE');

      // Step 5: Load Contribution Schedule
      await controller.loadContributionSchedule(obligationId: 'ob_journey_001');
      expect(controller.contributionSchedule?.scheduleId, 'cs_journey_001');
      expect(controller.contributionSchedule?.periods.length, 10);
      expect(controller.contributionSchedule?.periods.first.status, 'RECORDED');

      // Step 6: Load Contribution Events
      await controller.loadContributionEvents(obligationId: 'ob_journey_001');
      expect(controller.contributionEvents.length, 1);
      expect(controller.contributionEvents.first.contributionEventId, 'ce_journey_001');

      // Step 7: Load Payout Entitlement
      await controller.loadPayoutEntitlement(allocationId: 'alloc_journey_001');
      expect(controller.payoutEntitlement?.payoutEntitlementId, 'pe_journey_001');
      expect(controller.payoutEntitlement?.splits.length, 2);

      // Step 8: Load Cycle Period Projection
      await controller.loadCyclePeriodProjection(unitId: 'unit_journey_001');
      expect(controller.cycleProjection?.projectionId, 'cpp_journey_001');
      expect(controller.cycleProjection?.memberCount, 10);
      expect(controller.cycleProjection?.totalPotMinor, 5000000);

      // Step 9: Load Member Period Timeline
      await controller.loadMemberPeriodTimeline(allocationId: 'alloc_journey_001');
      expect(controller.memberTimeline?.projectionId, 'mpp_journey_001');
      expect(controller.memberTimeline?.periods.length, 10);
      expect(controller.memberTimeline?.periods[1].payout.isPayoutPeriod, true);
      expect(controller.memberTimeline?.periods[1].netEntitlementDeltaMinor, 200000);

      // Step 10: Lockdown safety activation blocks new mutations
      controller.setSystemLockdown(true, reason: 'Emergency Test Lockdown');
      expect(controller.isSystemLocked, true);

      // Attempting a mutation while locked should set error state and not call backend
      await controller.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 1,
        payoutFlexibilityWindow: 0,
        currency: 'EGP',
      );
      expect(controller.step, CentralPoolFlowStep.error);
      expect(controller.errorMessage, contains('lockdown'));
    });
  });
}
