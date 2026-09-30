// Central Pool Payout Entitlement View (Step 13)
// PROVENANCE & SEMANTIC BOUNDARY:
// - Read and present the existing PayoutEntitlement projection.
// - Zero client-side mathematical recalculation of entitlement.
// - Backend/frozen mathematical contracts remain authoritative (REAL_MONEY_ENABLED = false).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payout_entitlement_model.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class PayoutEntitlementView extends ConsumerWidget {
  final CentralPoolController? controller;
  final PayoutEntitlementModel? entitlementOverride;
  final EntitlementQueryParams? queryParams;

  const PayoutEntitlementView({
    Key? key,
    this.controller,
    this.entitlementOverride,
    this.queryParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    if (entitlementOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, entitlementOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.payoutEntitlement,
            controller!.errorMessage,
            controller!.isLoading,
            () => controller!.loadPayoutEntitlement(),
          );
        },
      );
    }

    final params = queryParams ?? const EntitlementQueryParams();
    final asyncEntitlement = ref.watch(payoutEntitlementFamily(params));

    return asyncEntitlement.when(
      data: (entitlement) => _buildScaffold(context, isLocked, lockdown, entitlement, null, false, () => ref.refresh(payoutEntitlementFamily(params))),
      loading: () => _buildScaffold(context, isLocked, lockdown, null, null, true, () {}),
      error: (err, _) => _buildScaffold(context, isLocked, lockdown, null, err.toString(), false, () => ref.refresh(payoutEntitlementFamily(params))),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    PayoutEntitlementModel? entitlement,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Entitlement Projection'),
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
                      : entitlement == null
                          ? const Center(
                              child: Text(
                                'No payout entitlement projection found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Entitlement Card
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
                                              Text(
                                                'Position #${entitlement.positionNumber}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade900,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  entitlement.status,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          _EntitlementRow(
                                            label: 'Entitlement ID',
                                            value: entitlement.payoutEntitlementId,
                                          ),
                                          _EntitlementRow(
                                            label: 'Allocation Unit ID',
                                            value: entitlement.allocationUnitId,
                                          ),
                                          _EntitlementRow(
                                            label: 'Allocation ID',
                                            value: entitlement.allocationId,
                                          ),
                                          _EntitlementRow(
                                            label: 'Total Entitlement (E = N * C)',
                                            value: '${(entitlement.totalEntitlementMinor / 100).toStringAsFixed(0)} ${entitlement.currency}',
                                            isEmphasized: true,
                                          ),
                                          _EntitlementRow(
                                            label: 'Disbursement Slots',
                                            value: '${entitlement.splits.length} Slot(s)',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Scheduled Disbursement Slots (SYMMETRICAL_V1)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  ...entitlement.splits.map((slot) {
                                    final percentage = (slot.basisPoints / 100).toStringAsFixed(0);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.purple.shade800,
                                          child: const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
                                        ),
                                        title: Text(
                                          'Period #${slot.periodNumber} Disbursement',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          slot.isCenter
                                              ? 'Center Aggregated (100% Payout)'
                                              : 'Paired Symmetrical Split ($percentage%)',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Text(
                                          '${(slot.amountMinor / 100).toStringAsFixed(0)} ${entitlement.currency}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.purpleAccent,
                                          ),
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

class _EntitlementRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;

  const _EntitlementRow({
    Key? key,
    required this.label,
    required this.value,
    this.isEmphasized = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w600,
              fontSize: isEmphasized ? 14 : 13,
              color: isEmphasized ? Colors.purpleAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
