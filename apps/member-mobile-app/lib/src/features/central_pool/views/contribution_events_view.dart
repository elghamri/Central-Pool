// Central Pool Contribution Events View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Read and present existing ContributionEvent history records.
// - Pure presentation of existing backend ledger/event records.
// - No client-side creation of financial truth (REAL_MONEY_ENABLED = false).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contribution_event_model.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class ContributionEventsView extends ConsumerWidget {
  final CentralPoolController? controller;
  final List<ContributionEventModel>? eventsOverride;
  final String? obligationId;

  const ContributionEventsView({
    Key? key,
    this.controller,
    this.eventsOverride,
    this.obligationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    if (eventsOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, eventsOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.contributionEvents,
            controller!.errorMessage,
            controller!.isLoading,
            () {
              if (controller!.financialObligation != null) {
                controller!.loadContributionEvents(obligationId: controller!.financialObligation!.obligationId);
              }
            },
          );
        },
      );
    }

    if (obligationId != null && obligationId!.isNotEmpty) {
      final asyncEvents = ref.watch(contributionEventsFamily(obligationId!));
      return asyncEvents.when(
        data: (events) => _buildScaffold(context, isLocked, lockdown, events, null, false, () => ref.refresh(contributionEventsFamily(obligationId!))),
        loading: () => _buildScaffold(context, isLocked, lockdown, [], null, true, () {}),
        error: (err, _) => _buildScaffold(context, isLocked, lockdown, [], err.toString(), false, () => ref.refresh(contributionEventsFamily(obligationId!))),
      );
    }

    return _buildScaffold(context, isLocked, lockdown, const [], null, false, () {});
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    List<ContributionEventModel> events,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Event History'),
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
                      : events.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_outlined, size: 48, color: Colors.grey.shade600),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No recorded contribution events yet.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Events will appear here once period contributions are recognized.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Period #${event.periodNumber} Contribution',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              '+${(event.amountMinor / 100).toStringAsFixed(0)} ${event.currency}',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Recorded: ${event.recordedAt.toLocal().toString().substring(0, 19)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Event ID: ${event.contributionEventId}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        if (event.journalEntryId != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Journal Entry: ${event.journalEntryId}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
