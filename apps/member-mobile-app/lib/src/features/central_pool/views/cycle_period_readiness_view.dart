// Central Pool Cycle Period Readiness & Projection View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Present existing Cycle/Period projection information available through canonical contract.
// - This is a read/presentation surface only.
// - Do NOT introduce new activation/quorum logic (FM-ACT-01 unresolved).
// - Do NOT create lifecycle transitions (REAL_MONEY_ENABLED = false).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/period_projection_models.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class CyclePeriodReadinessView extends ConsumerWidget {
  final CentralPoolController? controller;
  final CyclePeriodProjectionModel? projectionOverride;
  final String? unitId;

  const CyclePeriodReadinessView({
    Key? key,
    this.controller,
    this.projectionOverride,
    this.unitId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    if (projectionOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, projectionOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.cycleProjection,
            controller!.errorMessage,
            controller!.isLoading,
            () {
              if (controller!.confirmationResult != null) {
                controller!.loadCyclePeriodProjection(unitId: controller!.confirmationResult!.allocationUnitId);
              }
            },
          );
        },
      );
    }

    if (unitId != null && unitId!.isNotEmpty) {
      final asyncProjection = ref.watch(cyclePeriodProjectionFamily(unitId!));
      return asyncProjection.when(
        data: (proj) => _buildScaffold(context, isLocked, lockdown, proj, null, false, () => ref.refresh(cyclePeriodProjectionFamily(unitId!))),
        loading: () => _buildScaffold(context, isLocked, lockdown, null, null, true, () {}),
        error: (err, _) => _buildScaffold(context, isLocked, lockdown, null, err.toString(), false, () => ref.refresh(cyclePeriodProjectionFamily(unitId!))),
      );
    }

    return _buildScaffold(context, isLocked, lockdown, null, null, false, () {});
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    CyclePeriodProjectionModel? projection,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycle Period Projections'),
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
                      : projection == null
                          ? const Center(
                              child: Text(
                                'No cycle projection data available.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Summary Card
                                  Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Allocation Unit Summary',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade900,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${projection.memberCount} Members (N = ${projection.memberCount})',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          _ProjectionRow(
                                            label: 'Allocation Unit ID',
                                            value: projection.allocationUnitId,
                                          ),
                                          _ProjectionRow(
                                            label: 'Monthly Contribution (C)',
                                            value: '${(projection.periodicContributionMinor / 100).toStringAsFixed(0)} ${projection.currency}',
                                          ),
                                          _ProjectionRow(
                                            label: 'Member Entitlement (E = N * C)',
                                            value: '${(projection.totalEntitlementMinor / 100).toStringAsFixed(0)} ${projection.currency}',
                                          ),
                                          _ProjectionRow(
                                            label: 'Total Cycle Pot (N² * C)',
                                            value: '${(projection.totalPotMinor / 100).toStringAsFixed(0)} ${projection.currency}',
                                            isEmphasized: true,
                                          ),
                                          _ProjectionRow(
                                            label: 'Classification',
                                            value: projection.classification,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Period Balance & Readiness Projections',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  ...projection.periods.map((period) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: period.isBalanced ? Colors.green.shade900 : Colors.red.shade900,
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    period.isBalanced ? 'Balanced (50/50 Symmetrical)' : 'Unbalanced',
                                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Contribution Pool: ${(period.expectedContributionPoolMinor / 100).toStringAsFixed(0)} ${projection.currency}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                Text(
                                                  'Disbursement Pool: ${(period.expectedDisbursementPoolMinor / 100).toStringAsFixed(0)} ${projection.currency}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;

  const _ProjectionRow({
    Key? key,
    required this.label,
    required this.value,
    this.isEmphasized = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w600,
              fontSize: isEmphasized ? 13 : 12,
              color: isEmphasized ? Colors.cyanAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
