// Central Pool Contribution Schedule View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Read and present the existing ContributionSchedule read model.
// - Displays existing period data and existing status values only (SCHEDULED | RECORDED).
// - Zero client-side creation of financial truth or new states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contribution_schedule_model.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class ContributionScheduleView extends ConsumerWidget {
  final CentralPoolController? controller;
  final ContributionScheduleModel? scheduleOverride;
  final ScheduleQueryParams? queryParams;

  const ContributionScheduleView({
    Key? key,
    this.controller,
    this.scheduleOverride,
    this.queryParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    if (scheduleOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, scheduleOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.contributionSchedule,
            controller!.errorMessage,
            controller!.isLoading,
            () => controller!.loadContributionSchedule(),
          );
        },
      );
    }

    final params = queryParams ?? const ScheduleQueryParams();
    final asyncSchedule = ref.watch(contributionScheduleFamily(params));

    return asyncSchedule.when(
      data: (schedule) => _buildScaffold(context, isLocked, lockdown, schedule, null, false, () => ref.refresh(contributionScheduleFamily(params))),
      loading: () => _buildScaffold(context, isLocked, lockdown, null, null, true, () {}),
      error: (err, _) => _buildScaffold(context, isLocked, lockdown, null, err.toString(), false, () => ref.refresh(contributionScheduleFamily(params))),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    ContributionScheduleModel? schedule,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Schedule'),
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
                      : schedule == null
                          ? const Center(
                              child: Text(
                                'No contribution schedule found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Schedule Header Summary
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
                                            const Text(
                                              'Schedule Overview',
                                              style: TextStyle(
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
                                                '${schedule.totalPeriods} Periods',
                                                style: const TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (schedule.periods.isNotEmpty) ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Periodic Contribution (C):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                '${(schedule.periods.first.scheduledAmountMinor / 100).toStringAsFixed(0)} EGP',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Platform Fee:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                '${((schedule.periods.first.scheduledAmountMinor * 0.02) / 100).toStringAsFixed(0)} EGP',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Total Periodic Member Outflow:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                                              Text(
                                                '${((schedule.periods.first.scheduledAmountMinor * 1.02) / 100).toStringAsFixed(0)} EGP',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Periodic Contribution Status',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: schedule.periods.length,
                                    itemBuilder: (context, index) {
                                      final period = schedule.periods[index];
                                      final isRecorded = period.status == 'RECORDED';

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                        ),
                                        color: const Color(0xFF1E293B),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: isRecorded
                                                ? const Color(0xFF10B981).withOpacity(0.2)
                                                : Colors.grey.shade800,
                                            child: Icon(
                                              isRecorded ? Icons.check : Icons.calendar_today,
                                              color: isRecorded ? const Color(0xFF10B981) : Colors.white70,
                                              size: 18,
                                            ),
                                          ),
                                          title: Text(
                                            'Period #${period.periodNumber}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            isRecorded && period.recordedAt != null
                                                ? 'Recorded on: ${period.recordedAt!.toLocal().toString().substring(0, 10)}'
                                                : 'Contribution: ${(period.scheduledAmountMinor / 100).toStringAsFixed(0)} EGP + Fee: ${((period.scheduledAmountMinor * 0.02) / 100).toStringAsFixed(0)} EGP',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${((period.scheduledAmountMinor * 1.02) / 100).toStringAsFixed(0)} EGP',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isRecorded ? const Color(0xFF10B981).withOpacity(0.2) : Colors.blue.shade900.withOpacity(0.5),
                                                  borderRadius: BorderRadius.circular(3),
                                                  border: Border.all(
                                                    color: isRecorded ? const Color(0xFF10B981) : Colors.blue.shade500,
                                                  ),
                                                ),
                                                child: Text(
                                                  period.status,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isRecorded ? const Color(0xFF10B981) : Colors.blue.shade200,
                                                  ),
                                                ),
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
