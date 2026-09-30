// Phase 48: Central Pool Vertical Slice UI & Controller Automated Test
// Invariant: Verifies Central Pool models, state transitions, repository bindings, and zero legacy imports.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:member_mobile_app/src/features/central_pool/models/participation_request_model.dart';
import 'package:member_mobile_app/src/features/central_pool/models/candidate_allocation_model.dart';
import 'package:member_mobile_app/src/features/central_pool/data/central_pool_repository.dart';
import 'package:member_mobile_app/src/features/central_pool/state/central_pool_controller.dart';
import 'package:member_mobile_app/src/features/central_pool/views/submit_participation_request_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/candidate_selection_view.dart';
import 'package:member_mobile_app/src/features/central_pool/views/allocation_confirmation_view.dart';

void main() {
  group('Central Pool Phase 1 Vertical Slice Tests', () {
    test('1. Model Serialization & Deserialization', () {
      final reqJson = {
        'request_id': 'req_test_001',
        'tenant_id': 'tenant_cairo',
        'member_id': 'mem_alice',
        'monthly_contribution_minor': 50000,
        'duration_periods': 10,
        'preferred_payout_period': 3,
        'payout_flexibility_window': 1,
        'currency': 'EGP',
        'status': 'SUBMITTED',
        'submitted_at': '2026-09-07T12:00:00.000Z',
        'expires_at': '2026-09-08T12:00:00.000Z',
        'version': 1,
        'idempotency_key': 'idem_001',
      };

      final req = ParticipationRequestModel.fromJson(reqJson);
      expect(req.requestId, 'req_test_001');
      expect(req.monthlyContributionMinor, 50000);
      expect(req.durationPeriods, 10);
      expect(req.preferredPayoutPeriod, 3);
      expect(req.currency, 'EGP');
      expect(req.status, 'SUBMITTED');

      final candJson = {
        'candidate_id': 'cand_001',
        'request_id': 'req_test_001',
        'tenant_id': 'tenant_cairo',
        'allocation_unit_id': 'unit_001',
        'schedule_id': 'sched_001',
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
        'candidate_signature': 'sig_valid_001',
      };

      final cand = CandidateAllocationModel.fromJson(candJson);
      expect(cand.candidateId, 'cand_001');
      expect(cand.prospectivePosition, 3);
      expect(cand.primaryPeriod, 2);
      expect(cand.mirrorPeriod, 9);
      expect(cand.totalEntitlementMinor, 500000);
      expect(cand.primaryAmountMinor, 250000);
      expect(cand.mirrorAmountMinor, 250000);
    });

    test('2. CentralPoolController Flow & State Machine', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/participation-requests' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'request_id': 'req_mock_123',
              'tenant_id': 'tenant_cairo',
              'member_id': 'mem_alice',
              'monthly_contribution_minor': 50000,
              'duration_periods': 10,
              'preferred_payout_period': 3,
              'payout_flexibility_window': 1,
              'currency': 'EGP',
              'status': 'SUBMITTED',
              'submitted_at': '2026-09-07T12:00:00.000Z',
              'expires_at': '2026-09-08T12:00:00.000Z',
              'version': 1,
              'idempotency_key': 'idem_001',
            }),
            201,
          );
        }
        if (request.url.path == '/api/v1/participation-requests/req_mock_123/candidates') {
          return http.Response(
            jsonEncode([
              {
                'candidate_id': 'cand_123',
                'request_id': 'req_mock_123',
                'tenant_id': 'tenant_cairo',
                'allocation_unit_id': 'unit_123',
                'schedule_id': 'sched_123',
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
                'candidate_signature': 'sig_valid_123',
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/participation-requests/req_mock_123/select') {
          return http.Response(
            jsonEncode({
              'request_id': 'req_mock_123',
              'tenant_id': 'tenant_cairo',
              'member_id': 'mem_alice',
              'allocation_unit_id': 'unit_123',
              'schedule_id': 'sched_123',
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
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
      final controller = CentralPoolController(repository: repo, tenantId: 'tenant_cairo', memberId: 'mem_alice');

      expect(controller.step, CentralPoolFlowStep.form);

      // Submit Request
      await controller.submitParticipationRequest(
        monthlyContributionMinor: 50000,
        durationPeriods: 10,
        preferredPayoutPeriod: 3,
        payoutFlexibilityWindow: 1,
        currency: 'EGP',
        idempotencyKey: 'idem_001',
      );

      expect(controller.step, CentralPoolFlowStep.matching);
      expect(controller.currentRequest?.requestId, 'req_mock_123');

      // Load Candidates
      await controller.loadCandidates();
      expect(controller.step, CentralPoolFlowStep.candidateList);
      expect(controller.candidates.length, 1);

      // Select Candidate & Confirm
      await controller.confirmSelection(
        candidate: controller.candidates.first,
        idempotencyKey: 'idem_select_001',
      );

      expect(controller.step, CentralPoolFlowStep.confirmed);
      expect(controller.confirmationResult?.status, 'CONFIRMED');
      expect(controller.confirmationResult?.confirmedPositionNumber, 3);
    });

    testWidgets('3. UI Rendering & Interaction', (tester) async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final repo = CentralPoolRepository(baseUrl: 'http://localhost:8080', client: mockClient);
      final controller = CentralPoolController(repository: repo, tenantId: 'tenant_cairo', memberId: 'mem_alice');

      // Render Submit View
      await tester.pumpWidget(MaterialApp(
        home: SubmitParticipationRequestView(controller: controller),
      ));

      expect(find.text('Central Pool Participation'), findsOneWidget);
      expect(find.text('Submit Participation Preferences'), findsOneWidget);
      expect(find.text('Find Compatible Matches'), findsOneWidget);

      // Set Mock Candidate and Render Candidate Selection View
      controller.candidates = [
        CandidateAllocationModel(
          candidateId: 'cand_widget_test',
          requestId: 'req_001',
          tenantId: 'tenant_cairo',
          allocationUnitId: 'unit_001',
          scheduleId: 'sched_001',
          prospectivePosition: 1,
          primaryPeriod: 1,
          mirrorPeriod: 10,
          allocationMode: 'STANDARD_SPLIT',
          totalEntitlementMinor: 500000,
          primaryAmountMinor: 250000,
          mirrorAmountMinor: 250000,
          currency: 'EGP',
          isCenterAggregated: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          candidateSignature: 'sig_test',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: CandidateSelectionView(controller: controller),
      ));

      expect(find.text('Matched Allocation Options'), findsOneWidget);
      expect(find.text('Position #1'), findsOneWidget);
      expect(find.text('Confirm This Allocation'), findsOneWidget);

      // Set Confirmation Result and Render Confirmation View
      controller.confirmationResult = ConfirmationResultModel(
        requestId: 'req_001',
        tenantId: 'tenant_cairo',
        memberId: 'mem_alice',
        allocationUnitId: 'unit_001',
        scheduleId: 'sched_001',
        confirmedPositionNumber: 1,
        primaryPeriod: 1,
        mirrorPeriod: 10,
        monthlyContributionMinor: 50000,
        totalEntitlementMinor: 500000,
        primaryAmountMinor: 250000,
        mirrorAmountMinor: 250000,
        currency: 'EGP',
        confirmedAt: DateTime.now(),
        status: 'CONFIRMED',
      );

      await tester.pumpWidget(MaterialApp(
        home: AllocationConfirmationView(controller: controller),
      ));

      expect(find.text('Allocation Confirmed'), findsOneWidget);
      expect(find.text('Position Successfully Confirmed!'), findsOneWidget);
      expect(find.text('REAL_MONEY_ENABLED = false (SIMULATION)'), findsOneWidget);
    });
  });
}
