// Phase 52: Central Pool Step 13 Riverpod State Providers Unit & Integration Test
// Invariant: Verifies Riverpod providers for financial read models, period projections, matching flow, and lockdown.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/providers/central_pool_providers.dart';

void main() {
  group('Central Pool Step 13 Riverpod Providers Suite', () {
    late http.Client mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        final path = request.url.path;

        // Financial Obligation
        if (path == '/api/v1/financial-obligations') {
          return http.Response(
            jsonEncode({
              'result': {
                'obligation': {
                  'obligationId': 'ob_riverpod_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationUnitId': 'unit_001',
                  'allocationId': 'alloc_001',
                  'positionNumber': 2,
                  'totalObligationMinor': 500000,
                  'contributionMinor': 50000,
                  'totalPeriods': 10,
                  'fulfilledAmountMinor': 50000,
                  'currency': 'EGP',
                  'status': 'ACTIVE',
                  'createdAt': '2026-09-07T12:00:00.000Z',
                  'updatedAt': '2026-09-07T12:00:00.000Z',
                  'version': 1,
                }
              }
            }),
            200,
          );
        }

        // Contribution Schedule
        if (path == '/api/v1/contribution-schedules') {
          return http.Response(
            jsonEncode({
              'result': {
                'schedule': {
                  'scheduleId': 'cs_riverpod_001',
                  'obligationId': 'ob_riverpod_001',
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
                }
              }
            }),
            200,
          );
        }

        // Contribution Events
        if (path == '/api/v1/contribution-events') {
          return http.Response(
            jsonEncode({
              'result': {
                'events': [
                  {
                    'contributionEventId': 'ce_riverpod_001',
                    'tenantId': 'tenant_cairo',
                    'memberUid': 'mem_alice',
                    'obligationId': 'ob_riverpod_001',
                    'allocationUnitId': 'unit_001',
                    'periodNumber': 1,
                    'amountMinor': 50000,
                    'currency': 'EGP',
                    'recordedAt': '2026-09-07T12:00:00.000Z',
                    'idempotencyId': 'idem_ce_001',
                  }
                ]
              }
            }),
            200,
          );
        }

        // Payout Entitlement
        if (path == '/api/v1/payout-entitlements') {
          return http.Response(
            jsonEncode({
              'result': {
                'entitlement': {
                  'payoutEntitlementId': 'pe_riverpod_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationUnitId': 'unit_001',
                  'allocationId': 'alloc_001',
                  'positionNumber': 2,
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
                }
              }
            }),
            200,
          );
        }

        // Cycle Projection
        if (path == '/api/v1/cycle-projections') {
          return http.Response(
            jsonEncode({
              'result': {
                'projection': {
                  'projectionId': 'cpp_riverpod_001',
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
                      'payoutSlots': [],
                      'isBalanced': true,
                    }
                  ],
                  'isProjection': true,
                  'classification': 'DERIVED_PROJECTION',
                  'generatedAt': '2026-09-07T12:00:00.000Z',
                }
              }
            }),
            200,
          );
        }

        // Member Timeline
        if (path == '/api/v1/member-timelines') {
          return http.Response(
            jsonEncode({
              'result': {
                'projection': {
                  'projectionId': 'mpp_riverpod_001',
                  'tenantId': 'tenant_cairo',
                  'memberUid': 'mem_alice',
                  'allocationId': 'alloc_001',
                  'allocationUnitId': 'unit_001',
                  'positionNumber': 2,
                  'totalPeriods': 2,
                  'periodicContributionMinor': 50000,
                  'totalObligationMinor': 100000,
                  'totalEntitlementMinor': 100000,
                  'currency': 'EGP',
                  'periods': [
                    {
                      'periodNumber': 1,
                      'contribution': {
                        'periodNumber': 1,
                        'dueAmountMinor': 50000,
                        'status': 'RECORDED',
                      },
                      'payout': {
                        'entitledAmountMinor': 50000,
                        'basisPoints': 5000,
                        'isPayoutPeriod': true,
                        'isCenter': false,
                        'mirrorPeriod': 2,
                      },
                      'netEntitlementDeltaMinor': 0,
                    }
                  ],
                  'isProjection': true,
                  'classification': 'DERIVED_PROJECTION',
                  'generatedAt': '2026-09-07T12:00:00.000Z',
                }
              }
            }),
            200,
          );
        }

        // Matching Requests
        if (path == '/api/v1/participation-requests' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'result': {
                'request': {
                  'requestId': 'req_riverpod_001',
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

        // Candidates
        if (path == '/api/v1/participation-requests/req_riverpod_001/candidates') {
          return http.Response(
            jsonEncode({
              'result': {
                'candidates': [
                  {
                    'candidate_id': 'cand_riverpod_001',
                    'request_id': 'req_riverpod_001',
                    'tenant_id': 'tenant_cairo',
                    'allocation_unit_id': 'unit_001',
                    'schedule_id': 'sched_001',
                    'prospective_position': 2,
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
                    'candidate_signature': 'sig_001',
                  }
                ]
              }
            }),
            200,
          );
        }

        // Selection
        if (path == '/api/v1/participation-requests/req_riverpod_001/select') {
          return http.Response(
            jsonEncode({
              'result': {
                'request_id': 'req_riverpod_001',
                'tenant_id': 'tenant_cairo',
                'member_id': 'mem_alice',
                'allocation_unit_id': 'unit_001',
                'schedule_id': 'sched_001',
                'confirmed_position_number': 2,
                'primary_period': 2,
                'mirror_period': 9,
                'monthly_contribution_minor': 50000,
                'total_entitlement_minor': 500000,
                'primary_amount_minor': 250000,
                'mirror_amount_minor': 250000,
                'currency': 'EGP',
                'confirmed_at': '2026-09-07T12:05:00.000Z',
                'status': 'CONFIRMED',
              }
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });
    });

    test('1. FinancialObligation provider resolves data', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final obligation = await container.read(financialObligationFamily(const ObligationQueryParams(obligationId: 'ob_001')).future);
      expect(obligation.obligationId, 'ob_riverpod_001');
      expect(obligation.totalObligationMinor, 500000);
      expect(obligation.status, 'ACTIVE');
    });

    test('2. ContributionSchedule provider resolves schedule with periods', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final schedule = await container.read(contributionScheduleFamily(const ScheduleQueryParams(scheduleId: 'cs_001')).future);
      expect(schedule.scheduleId, 'cs_riverpod_001');
      expect(schedule.periods.length, 2);
      expect(schedule.periods.first.status, 'RECORDED');
    });

    test('3. ContributionEvents provider resolves event history', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final events = await container.read(contributionEventsFamily('ob_001').future);
      expect(events.length, 1);
      expect(events.first.contributionEventId, 'ce_riverpod_001');
      expect(events.first.amountMinor, 50000);
    });

    test('4. PayoutEntitlement provider resolves slots', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final entitlement = await container.read(payoutEntitlementFamily(const EntitlementQueryParams(entitlementId: 'pe_001')).future);
      expect(entitlement.payoutEntitlementId, 'pe_riverpod_001');
      expect(entitlement.splits.length, 2);
    });

    test('5. CyclePeriodProjection and MemberPeriodTimeline providers resolve projections', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final cycle = await container.read(cyclePeriodProjectionFamily('unit_001').future);
      expect(cycle.projectionId, 'cpp_riverpod_001');
      expect(cycle.memberCount, 10);

      final timeline = await container.read(memberPeriodTimelineFamily(const MemberTimelineQueryParams(allocationId: 'alloc_001')).future);
      expect(timeline.projectionId, 'mpp_riverpod_001');
      expect(timeline.periods.first.payout.isPayoutPeriod, true);
    });

    test('6. SystemLockdown provider manages reactive lockdown state', () {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      expect(container.read(isSystemLockedProvider), false);

      container.read(systemLockdownProvider.notifier).setLockdown(true, reason: 'Emergency Test');
      expect(container.read(isSystemLockedProvider), true);
      expect(container.read(systemLockdownProvider)?.reason, 'Emergency Test');

      container.read(systemLockdownProvider.notifier).setLockdown(false);
      expect(container.read(isSystemLockedProvider), false);
    });

    test('7. CentralPoolFlowNotifier manages full matching & confirmation flow', () async {
      final container = ProviderContainer(
        overrides: [
          centralPoolRepositoryProvider.overrideWithValue(
            CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(centralPoolContextProvider.notifier).updateContext(
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
      );

      final flowNotifier = container.read(centralPoolFlowProvider.notifier);

      expect(container.read(centralPoolFlowProvider).step, MatchingFlowStep.form);

      await flowNotifier.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 3,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
      );
      expect(container.read(centralPoolFlowProvider).step, MatchingFlowStep.matching);
      expect(container.read(centralPoolFlowProvider).currentRequest?.requestId, 'req_riverpod_001');

      await flowNotifier.loadCandidates();
      expect(container.read(centralPoolFlowProvider).step, MatchingFlowStep.candidateList);
      expect(container.read(centralPoolFlowProvider).candidates.length, 1);

      await flowNotifier.confirmSelection(
        candidate: container.read(centralPoolFlowProvider).candidates.first,
      );
      expect(container.read(centralPoolFlowProvider).step, MatchingFlowStep.confirmed);
      expect(container.read(centralPoolFlowProvider).confirmationResult?.confirmedPositionNumber, 2);
    });
  });
}
