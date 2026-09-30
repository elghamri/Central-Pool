// Central Pool Client Repository (Step 8/13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Direct client adapter over the 9 canonical Central Pool callable/REST endpoints.
// - Invariant: Zero business/financial calculations on client.
// - All financial and matching mathematics remain strictly server-authoritative.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/participation_request_model.dart';
import '../models/candidate_allocation_model.dart';
import '../models/financial_obligation_model.dart';
import '../models/contribution_schedule_model.dart';
import '../models/contribution_event_model.dart';
import '../models/payout_entitlement_model.dart';
import '../models/period_projection_models.dart';
import '../models/system_lockdown_model.dart';

class CentralPoolRepository {
  final String baseUrl;
  final http.Client client;

  CentralPoolRepository({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Map<String, String> _headers(String tenantId, String memberId, {String? idempotencyKey, String? authToken}) {
    final headers = {
      'Content-Type': 'application/json',
      'X-Tenant-ID': tenantId,
      'X-Member-ID': memberId,
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  // ===========================================================================
  // 1. SUBMIT PARTICIPATION REQUEST (Canonical Callable #1)
  // ===========================================================================
  Future<ParticipationRequestModel> submitRequest({
    required String tenantId,
    required String memberId,
    required int monthlyContributionMinor,
    required int durationPeriods,
    required int preferredPayoutPeriod,
    required int payoutFlexibilityWindow,
    required String currency,
    required String idempotencyKey,
    String? clientRequestId,
    String? tierId,
    String? tierDisplayName,
  }) async {
    if (durationPeriods < 2 || durationPeriods > 12) {
      throw ArgumentError('Invalid durationPeriods: $durationPeriods. Must be within [2, 12].');
    }
    if (preferredPayoutPeriod < 1 || preferredPayoutPeriod > durationPeriods) {
      throw ArgumentError('Invalid preferredPayoutPeriod: $preferredPayoutPeriod. Must be within [1, $durationPeriods].');
    }
    if (monthlyContributionMinor <= 0) {
      throw ArgumentError('Invalid monthlyContributionMinor: $monthlyContributionMinor. Must be > 0.');
    }

    final uri = Uri.parse('$baseUrl/api/v1/participation-requests');
    final body = jsonEncode({
      'data': {
        'contributionMinor': monthlyContributionMinor,
        'durationPeriods': durationPeriods,
        'payoutPreference': preferredPayoutPeriod,
        'currency': currency,
        'clientRequestId': clientRequestId ?? idempotencyKey,
        if (tierId != null) 'tierId': tierId,
        if (tierDisplayName != null) 'tierDisplayName': tierDisplayName,
      },
      // Flat fields for backward compatibility with REST mock fixtures
      'monthly_contribution_minor': monthlyContributionMinor,
      'duration_periods': durationPeriods,
      'preferred_payout_period': preferredPayoutPeriod,
      'payout_flexibility_window': payoutFlexibilityWindow,
      'currency': currency,
      'idempotency_key': idempotencyKey,
      if (tierId != null) 'tier_id': tierId,
      if (tierDisplayName != null) 'tier_display_name': tierDisplayName,
    });

    final response = await client.post(
      uri,
      headers: _headers(tenantId, memberId, idempotencyKey: idempotencyKey),
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final reqObj = data.containsKey('request') ? data['request'] as Map<String, dynamic> : data;
      return ParticipationRequestModel.fromJson(reqObj);
    } else {
      throw Exception('Failed to submit request: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 2. GET PARTICIPATION REQUEST STATUS
  // ===========================================================================
  Future<ParticipationRequestModel> getRequest({
    required String tenantId,
    required String memberId,
    required String requestId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/participation-requests/$requestId');
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final reqObj = data.containsKey('request') ? data['request'] as Map<String, dynamic> : data;
      return ParticipationRequestModel.fromJson(reqObj);
    } else {
      throw Exception('Failed to get request: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 3. GET MATCHING CANDIDATES (Canonical Callable #2)
  // ===========================================================================
  Future<List<CandidateAllocationModel>> getCandidates({
    required String tenantId,
    required String memberId,
    required String requestId,
    int? maxCandidates,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/participation-requests/$requestId/candidates');
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((item) => CandidateAllocationModel.fromJson(item as Map<String, dynamic>)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
        final list = (data['candidates'] as List<dynamic>?) ?? [];
        return list.map((item) => CandidateAllocationModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to get candidates: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 4. SELECT CANDIDATE AND CONFIRM (Canonical Callable #3)
  // ===========================================================================
  Future<ConfirmationResultModel> selectCandidate({
    required String tenantId,
    required String memberId,
    required String requestId,
    required CandidateAllocationModel candidate,
    required String idempotencyKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/participation-requests/$requestId/select');
    final body = jsonEncode({
      'data': {
        'requestId': requestId,
        'candidateId': candidate.candidateId,
        'idempotencyKey': idempotencyKey,
      },
      'candidate': candidate.toJson(),
    });

    final response = await client.post(
      uri,
      headers: _headers(tenantId, memberId, idempotencyKey: idempotencyKey),
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      return ConfirmationResultModel.fromJson(data);
    } else if (response.statusCode == 409) {
      throw Exception('Position conflict: target position already confirmed by another member (HTTP 409)');
    } else if (response.statusCode == 410) {
      throw Exception('Candidate expired or stale (HTTP 410)');
    } else if (response.statusCode == 422) {
      throw Exception('Idempotency payload mismatch (HTTP 422)');
    } else {
      throw Exception('Failed to select candidate: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 5. GET FINANCIAL OBLIGATION (Canonical Callable #4)
  // ===========================================================================
  Future<FinancialObligationModel> getFinancialObligation({
    required String tenantId,
    required String memberId,
    String? obligationId,
    String? allocationId,
  }) async {
    final queryParams = <String, String>{};
    if (obligationId != null) queryParams['obligationId'] = obligationId;
    if (allocationId != null) queryParams['allocationId'] = allocationId;

    final uri = Uri.parse('$baseUrl/api/v1/financial-obligations').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final obligationData = data.containsKey('obligation') ? data['obligation'] as Map<String, dynamic> : data;
      return FinancialObligationModel.fromJson(obligationData);
    } else {
      throw Exception('Failed to get financial obligation: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 6. GET CONTRIBUTION SCHEDULE (Canonical Callable #5)
  // ===========================================================================
  Future<ContributionScheduleModel> getContributionSchedule({
    required String tenantId,
    required String memberId,
    String? scheduleId,
    String? obligationId,
  }) async {
    final queryParams = <String, String>{};
    if (scheduleId != null) queryParams['scheduleId'] = scheduleId;
    if (obligationId != null) queryParams['obligationId'] = obligationId;

    final uri = Uri.parse('$baseUrl/api/v1/contribution-schedules').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final scheduleData = data.containsKey('schedule') ? data['schedule'] as Map<String, dynamic> : data;
      return ContributionScheduleModel.fromJson(scheduleData);
    } else {
      throw Exception('Failed to get contribution schedule: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 7. GET CONTRIBUTION EVENTS (Canonical Callable #6)
  // ===========================================================================
  Future<List<ContributionEventModel>> getContributionEvents({
    required String tenantId,
    required String memberId,
    required String obligationId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/contribution-events').replace(queryParameters: {'obligationId': obligationId});
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => ContributionEventModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
        final events = (data['events'] as List<dynamic>?) ?? [];
        return events.map((e) => ContributionEventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to get contribution events: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 8. GET PAYOUT ENTITLEMENT (Canonical Callable #7)
  // ===========================================================================
  Future<PayoutEntitlementModel> getPayoutEntitlement({
    required String tenantId,
    required String memberId,
    String? entitlementId,
    String? allocationId,
  }) async {
    final queryParams = <String, String>{};
    if (entitlementId != null) queryParams['entitlementId'] = entitlementId;
    if (allocationId != null) queryParams['allocationId'] = allocationId;

    final uri = Uri.parse('$baseUrl/api/v1/payout-entitlements').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final entitlementData = data.containsKey('entitlement') ? data['entitlement'] as Map<String, dynamic> : data;
      return PayoutEntitlementModel.fromJson(entitlementData);
    } else {
      throw Exception('Failed to get payout entitlement: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 9. GET CYCLE PERIOD PROJECTION (Canonical Callable #8)
  // ===========================================================================
  Future<CyclePeriodProjectionModel> getCyclePeriodProjection({
    required String tenantId,
    required String memberId,
    required String unitId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/cycle-projections').replace(queryParameters: {'unitId': unitId});
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final projData = data.containsKey('projection') ? data['projection'] as Map<String, dynamic> : data;
      return CyclePeriodProjectionModel.fromJson(projData);
    } else {
      throw Exception('Failed to get cycle period projection: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 10. GET MEMBER PERIOD TIMELINE (Canonical Callable #9)
  // ===========================================================================
  Future<MemberPeriodProjectionModel> getMemberPeriodTimeline({
    required String tenantId,
    required String memberId,
    required String allocationId,
    int? periodNumber,
  }) async {
    final queryParams = <String, String>{'allocationId': allocationId};
    if (periodNumber != null) queryParams['periodNumber'] = periodNumber.toString();

    final uri = Uri.parse('$baseUrl/api/v1/member-timelines').replace(queryParameters: queryParams);
    final response = await client.get(
      uri,
      headers: _headers(tenantId, memberId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
      final projData = data.containsKey('projection') ? data['projection'] as Map<String, dynamic> : data;
      return MemberPeriodProjectionModel.fromJson(projData);
    } else {
      throw Exception('Failed to get member period timeline: ${response.statusCode} - ${response.body}');
    }
  }

  // ===========================================================================
  // 11. GET SYSTEM LOCKDOWN STATUS (/system_lockdowns signal)
  // ===========================================================================
  Future<SystemLockdownModel?> getSystemLockdown({
    required String tenantId,
    required String memberId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/system-lockdowns');
      final response = await client.get(
        uri,
        headers: _headers(tenantId, memberId),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded.containsKey('result') ? decoded['result'] as Map<String, dynamic> : decoded;
        return SystemLockdownModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
