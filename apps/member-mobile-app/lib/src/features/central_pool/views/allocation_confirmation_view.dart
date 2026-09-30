// Central Pool Allocation Confirmation View (Phase 1 / FM-04 / FM-FEE)
// Invariant: Displays authoritative receipt confirmation; non-money simulation indicator.
// Fee is locked at confirmation and outside C. Zero payment actions/rails.

import 'package:flutter/material.dart';
import '../models/contribution_tier_model.dart';
import '../models/fee_model.dart';
import '../state/central_pool_controller.dart';

class AllocationConfirmationView extends StatelessWidget {
  final CentralPoolController controller;

  const AllocationConfirmationView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conf = controller.confirmationResult;
    final feeConfig = controller.feeConfig;
    final selectedTier = controller.selectedTier ??
        (conf != null ? ContributionTierModel.findByContributionMinor(conf.monthlyContributionMinor) : null);
    
    final int contributionMinor = conf?.monthlyContributionMinor ?? 50000;
    final int? feeMinor = feeConfig?.calculateFeeMinor(contributionMinor);
    final int? outflowMinor = feeConfig?.calculatePeriodicOutflowMinor(contributionMinor);

    final emeraldColor = const Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocation Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: conf == null
            ? const Center(child: Text('No confirmation data.'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Icon(Icons.check_circle, color: emeraldColor, size: 60),
                    const SizedBox(height: 12),
                    const Text(
                      'Position Successfully Confirmed!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your allocation position is authoritatively confirmed in the central pool.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700.withOpacity(0.6)),
                      ),
                      child: const Text(
                        'REAL_MONEY_ENABLED = false (SIMULATION)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Receipt & Financial Breakdown Card
                    Card(
                      elevation: 0,
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
                            Text(
                              'Confirmed Allocation Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: emeraldColor,
                              ),
                            ),
                            const Divider(height: 20, color: Colors.white12),
                            if (selectedTier != null)
                              _ReceiptRow(label: 'Contribution Tier', value: selectedTier.displayName),
                            _ReceiptRow(
                              label: 'Periodic Contribution (C)',
                              value: '${(conf.monthlyContributionMinor / 100).toStringAsFixed(0)} ${conf.currency}',
                            ),
                            _ReceiptRow(
                              label: 'Platform Fee (Locked)',
                              value: feeMinor != null
                                  ? '${(feeMinor / 100).toStringAsFixed(0)} ${conf.currency}'
                                  : 'Standard Configured Fee',
                            ),
                            _ReceiptRow(
                              label: 'Total Periodic Outflow',
                              value: outflowMinor != null
                                  ? '${(outflowMinor / 100).toStringAsFixed(0)} ${conf.currency}'
                                  : '${(conf.monthlyContributionMinor / 100).toStringAsFixed(0)} ${conf.currency} + Fee',
                              isHighlight: true,
                            ),
                            const Divider(height: 20, color: Colors.white12),
                            _ReceiptRow(label: 'Confirmed Position', value: '#${conf.confirmedPositionNumber}'),
                            _ReceiptRow(
                              label: 'Primary Payout',
                              value: 'Month ${conf.primaryPeriod} (${(conf.primaryAmountMinor / 100).toStringAsFixed(0)} ${conf.currency})',
                            ),
                            if (conf.primaryPeriod != conf.mirrorPeriod)
                              _ReceiptRow(
                                label: 'Mirror Payout',
                                value: 'Month ${conf.mirrorPeriod} (${(conf.mirrorAmountMinor / 100).toStringAsFixed(0)} ${conf.currency})',
                              ),
                            _ReceiptRow(
                              label: 'Total Entitlement',
                              value: '${(conf.totalEntitlementMinor / 100).toStringAsFixed(0)} ${conf.currency}',
                            ),
                            _ReceiptRow(label: 'Status', value: conf.status),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Locked Fee Policy Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: emeraldColor),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'The applicable platform fee rate is locked with authoritative confirmation and remains historically immutable for this allocation.',
                              style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          controller.reset();
                        },
                        child: const Text('Return to Overview'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ReceiptRow({
    Key? key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 14 : 13,
              color: isHighlight ? const Color(0xFF10B981) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

