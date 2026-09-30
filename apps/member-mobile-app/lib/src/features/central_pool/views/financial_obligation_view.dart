// Central Pool Financial Obligation View (Step 13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Read and present the existing FinancialObligation read model (Meaning A).
// - This is an internal simulation/accounting projection.
// - It is NOT a legal liability, payment claim, custody record, or real-money obligation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_obligation_model.dart';
import '../models/contribution_tier_model.dart';
import '../state/central_pool_controller.dart';
import '../providers/central_pool_providers.dart';
import '../widgets/locked_banner.dart';

class FinancialObligationView extends ConsumerWidget {
  final CentralPoolController? controller;
  final FinancialObligationModel? obligationOverride;
  final ObligationQueryParams? queryParams;

  const FinancialObligationView({
    Key? key,
    this.controller,
    this.obligationOverride,
    this.queryParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isSystemLockedProvider) || (controller?.isSystemLocked ?? false);
    final lockdown = ref.watch(systemLockdownProvider) ?? controller?.lockdown;

    // Resolve obligation data from override, controller, or Riverpod FutureProvider
    if (obligationOverride != null) {
      return _buildScaffold(context, isLocked, lockdown, obligationOverride!, null, false, () {});
    }

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return _buildScaffold(
            context,
            controller!.isSystemLocked,
            controller!.lockdown,
            controller!.financialObligation,
            controller!.errorMessage,
            controller!.isLoading,
            () => controller!.loadFinancialObligation(),
          );
        },
      );
    }

    // Riverpod Provider Resolution
    final params = queryParams ?? const ObligationQueryParams();
    final asyncObligation = ref.watch(financialObligationFamily(params));

    return asyncObligation.when(
      data: (obligation) => _buildScaffold(context, isLocked, lockdown, obligation, null, false, () => ref.refresh(financialObligationFamily(params))),
      loading: () => _buildScaffold(context, isLocked, lockdown, null, null, true, () {}),
      error: (err, _) => _buildScaffold(context, isLocked, lockdown, null, err.toString(), false, () => ref.refresh(financialObligationFamily(params))),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isLocked,
    dynamic lockdown,
    FinancialObligationModel? obligation,
    String? errorMessage,
    bool isLoading,
    VoidCallback onRetry,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Obligation Record'),
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
                      : obligation == null
                          ? const Center(
                              child: Text(
                                'No active financial obligation record found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Non-money simulation indicator
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade900.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade700),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.amber.shade400, size: 20),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'SIMULATION & ACCOUNTING PROJECTION',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'This view presents an internal accounting expected contribution obligation. It does NOT establish legal liability, custody, external debt, or real-money settlement (FM-02 unresolved, REAL_MONEY_ENABLED = false).',
                                          style: TextStyle(fontSize: 11, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Obligation Card
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
                                              Row(
                                                children: [
                                                  Text(
                                                    'Position #${obligation.positionNumber}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Contribution Tier Badge
                                                  if (ContributionTierModel.findByContributionMinor(obligation.contributionMinor) != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: const Color(0xFF10B981)),
                                                      ),
                                                      child: Text(
                                                        ContributionTierModel.findByContributionMinor(obligation.contributionMinor)!.displayName,
                                                        style: const TextStyle(
                                                          color: Color(0xFF10B981),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: obligation.status == 'FULFILLED'
                                                      ? Colors.green.shade800
                                                      : Colors.blue.shade800,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  obligation.status,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24, color: Colors.white12),
                                          _DetailRow(
                                            label: 'Periodic Contribution (C)',
                                            value: '${(obligation.contributionMinor / 100).toStringAsFixed(0)} ${obligation.currency}',
                                          ),
                                          _DetailRow(
                                            label: 'Locked Platform Fee',
                                            value: '${((obligation.contributionMinor * 0.02) / 100).toStringAsFixed(0)} ${obligation.currency}',
                                          ),
                                          _DetailRow(
                                            label: 'Periodic Member Outflow',
                                            value: '${((obligation.contributionMinor * 1.02) / 100).toStringAsFixed(0)} ${obligation.currency}',
                                            isEmphasized: true,
                                          ),
                                          const Divider(height: 16, color: Colors.white12),
                                          _DetailRow(
                                            label: 'Total Cycle Periods (N)',
                                            value: '${obligation.totalPeriods} Months',
                                          ),
                                          _DetailRow(
                                            label: 'Total Expected Contribution (N * C)',
                                            value: '${(obligation.totalObligationMinor / 100).toStringAsFixed(0)} ${obligation.currency}',
                                          ),
                                          _DetailRow(
                                            label: 'Fulfilled Amount',
                                            value: '${(obligation.fulfilledAmountMinor / 100).toStringAsFixed(0)} ${obligation.currency}',
                                          ),
                                          _DetailRow(
                                            label: 'Remaining Commitment',
                                            value: '${((obligation.totalObligationMinor - obligation.fulfilledAmountMinor) / 100).toStringAsFixed(0)} ${obligation.currency}',
                                          ),
                                          _DetailRow(
                                            label: 'Record Version',
                                            value: 'v${obligation.version}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;

  const _DetailRow({
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
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w600,
              fontSize: isEmphasized ? 14 : 13,
              color: isEmphasized ? Colors.cyanAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
