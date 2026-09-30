// Central Pool Member Period Timeline View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Read and present the existing member period projection/timeline.
// - Respects the existing authorization model (member sees only authorized data).
// - Net entitlement delta is a pure mathematical simulation value (REAL_MONEY_ENABLED = false).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/period_projection_models.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class MemberPeriodTimelineView extends ConsumerWidget {
  final CentralPoolController? controller;
  final MemberPeriodProjectionModel? timelineOverride;
  final MemberTimelineQueryParams? queryParams;

  const MemberPeriodTimelineView({
    Key? key,
    this.controller,
    this.timelineOverride,
    this.queryParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    if (timelineOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, timelineOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.memberTimeline,
            controller!.errorMessage,
            controller!.isLoading,
            () {
              if (controller!.confirmationResult != null) {
                controller!.loadMemberPeriodTimeline(allocationId: controller!.confirmationResult!.allocationUnitId);
              }
            },
          );
        },
      );
    }

    if (queryParams != null) {
      final asyncTimeline = ref.watch(memberPeriodTimelineFamily(queryParams!));
      return asyncTimeline.when(
        data: (timeline) => _buildScaffold(context, isLocked, lockdown, timeline, null, false, () => ref.refresh(memberPeriodTimelineFamily(queryParams!))),
        loading: () => _buildScaffold(context, isLocked, lockdown, null, null, true, () {}),
        error: (err, _) => _buildScaffold(context, isLocked, lockdown, null, err.toString(), false, () => ref.refresh(memberPeriodTimelineFamily(queryParams!))),
      );
    }

    return _buildScaffold(context, isLocked, lockdown, null, null, false, () {});
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    MemberPeriodProjectionModel? timeline,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Period Timeline'),
      ),
      body: Column(
        children: [
          if (isLocked)
            LockedBanner(lockdown: lockdown, isLocked: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: onRetry,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : timeline == null
                          ? const Center(
                              child: Text(
                                'No member timeline projection available.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Summary
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  color: const Color(0xFF0F172A),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Position #${timeline.positionNumber}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF10B981)),
                                              ),
                                              child: Text(
                                                '${timeline.totalPeriods} Periods Total',
                                                style: const TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Total Obligation: ${(timeline.totalObligationMinor / 100).toStringAsFixed(0)} ${timeline.currency}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Total Entitlement: ${(timeline.totalEntitlementMinor / 100).toStringAsFixed(0)} ${timeline.currency}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Period-by-Period Timeline',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: timeline.periods.length,
                                    itemBuilder: (context, index) {
                                      final period = timeline.periods[index];
                                      final hasPayout = period.payout.isPayoutPeriod;
                                      final netDelta = period.netEntitlementDeltaMinor;

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                        ),
                                        color: const Color(0xFF1E293B),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Period #${period.periodNumber}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: netDelta > 0
                                                          ? const Color(0xFF10B981).withOpacity(0.2)
                                                          : (netDelta < 0 ? Colors.orange.shade900.withOpacity(0.4) : Colors.grey.shade800),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: netDelta > 0
                                                            ? const Color(0xFF10B981)
                                                            : (netDelta < 0 ? Colors.orange.shade600 : Colors.grey.shade600),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      netDelta > 0
                                                          ? 'Net +${(netDelta / 100).toStringAsFixed(0)} ${timeline.currency}'
                                                          : (netDelta < 0
                                                              ? 'Net ${(netDelta / 100).toStringAsFixed(0)} ${timeline.currency}'
                                                              : 'Net 0 ${timeline.currency}'),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: netDelta > 0 ? const Color(0xFF10B981) : Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Contribution: ${(period.contribution.dueAmountMinor / 100).toStringAsFixed(0)} ${timeline.currency}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                  Text(
                                                    hasPayout
                                                        ? 'Payout: ${(period.payout.entitledAmountMinor / 100).toStringAsFixed(0)} ${timeline.currency}'
                                                        : 'Payout: 0 ${timeline.currency}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: hasPayout ? const Color(0xFF38BDF8) : Colors.grey,
                                                      fontWeight: hasPayout ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
