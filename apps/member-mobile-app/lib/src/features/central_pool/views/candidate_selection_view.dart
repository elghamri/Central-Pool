// Central Pool Candidate Selection View (Phase 1 / FM-04 / FM-FEE)
// Invariant: Displays provisional candidate payout options; zero client financial calculations.
// Preserves: Candidate is PROVISIONAL, not confirmed. Contribution != Fee.

import 'package:flutter/material.dart';
import '../models/candidate_allocation_model.dart';
import '../models/contribution_tier_model.dart';
import '../models/fee_model.dart';
import '../state/central_pool_controller.dart';

class CandidateSelectionView extends StatelessWidget {
  final CentralPoolController controller;

  const CandidateSelectionView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final candidates = controller.candidates;
    final feeConfig = controller.feeConfig;
    final req = controller.currentRequest;
    final selectedTier = controller.selectedTier ??
        (req != null ? ContributionTierModel.findByContributionMinor(req.monthlyContributionMinor) : null);
    
    final int contributionMinor = req?.monthlyContributionMinor ?? selectedTier?.contributionMinor ?? 50000;
    final int? feeMinor = feeConfig?.calculateFeeMinor(contributionMinor);
    final int? outflowMinor = feeConfig?.calculatePeriodicOutflowMinor(contributionMinor);

    final emeraldColor = const Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matched Allocation Options'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : candidates.isEmpty
                ? const Center(child: Text('No compatible candidates found. Please try adjusting your preferences.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provisional Allocation Notice Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade700.withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.hourglass_top, size: 18, color: Colors.amber.shade400),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Provisional Options: Viewing or selecting an option does not reserve capacity. Final allocation is confirmed on authoritative verification.',
                                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Request / Tier Summary Chip Row
                      Row(
                        children: [
                          if (selectedTier != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: emeraldColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: emeraldColor),
                              ),
                              child: Text(
                                selectedTier.displayName,
                                style: TextStyle(
                                  color: emeraldColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (outflowMinor != null)
                            Text(
                              'Outflow: ${(outflowMinor / 100).toStringAsFixed(0)} ${req?.currency ?? "EGP"} / period',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Select Prospective Position',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ?? const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Matched based on exact mathematical paired symmetry (Canonical 50/50).',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final cand = candidates[index];
                            return _CandidateCard(
                              candidate: cand,
                              contributionMinor: contributionMinor,
                              feeMinor: feeMinor,
                              outflowMinor: outflowMinor,
                              onSelect: () {
                                final idempotencyKey = 'idem_sel_${DateTime.now().millisecondsSinceEpoch}';
                                controller.confirmSelection(
                                  candidate: cand,
                                  idempotencyKey: idempotencyKey,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateAllocationModel candidate;
  final int contributionMinor;
  final int? feeMinor;
  final int? outflowMinor;
  final VoidCallback onSelect;

  const _CandidateCard({
    Key? key,
    required this.candidate,
    required this.contributionMinor,
    this.feeMinor,
    this.outflowMinor,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalEntitlement = (candidate.totalEntitlementMinor / 100).toStringAsFixed(0);
    final primaryAmount = (candidate.primaryAmountMinor / 100).toStringAsFixed(0);
    final mirrorAmount = (candidate.mirrorAmountMinor / 100).toStringAsFixed(0);
    final contributionStr = (contributionMinor / 100).toStringAsFixed(0);
    final feeStr = feeMinor != null ? (feeMinor! / 100).toStringAsFixed(0) : null;
    final outflowStr = outflowMinor != null ? (outflowMinor! / 100).toStringAsFixed(0) : null;

    final emeraldColor = const Color(0xFF10B981);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Position #${candidate.prospectivePosition}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade600),
                  ),
                  child: Text(
                    candidate.isCenterAggregated ? '100% Center Payout' : '50% / 50% Paired Split',
                    style: TextStyle(color: Colors.blue.shade200, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (candidate.isCenterAggregated) ...[
              Text(
                '• Month ${candidate.primaryPeriod}: $totalEntitlement ${candidate.currency} (100% payout)',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ] else ...[
              Text(
                '• Month ${candidate.primaryPeriod} (Primary): $primaryAmount ${candidate.currency} (50%)',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '• Month ${candidate.mirrorPeriod} (Mirror): $mirrorAmount ${candidate.currency} (50%)',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
            const Divider(height: 20, color: Colors.white12),

            // Financial Summary in Candidate Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Entitlement: $totalEntitlement ${candidate.currency}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                if (outflowStr != null)
                  Text(
                    'Outflow: $outflowStr ${candidate.currency} / mo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: emeraldColor),
                  ),
              ],
            ),
            if (feeStr != null) ...[
              const SizedBox(height: 4),
              Text(
                'Contribution: $contributionStr ${candidate.currency} + Fee: $feeStr ${candidate.currency}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: onSelect,
                child: const Text('Confirm This Allocation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

