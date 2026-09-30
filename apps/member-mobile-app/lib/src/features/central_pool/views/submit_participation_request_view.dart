// Central Pool Submit Participation Request View (Phase 1 / FM-04 / FM-FEE)
// Invariant: Headless preference submission; zero circle/gameya creation semantics.
// Ratified Tiers: Exactly 5 production tiers (500, 1000, 1500, 2500, 5000 EGP).
// Fee Governance: Fee is member-paid, outside C. Periodic Outflow = C + Fee.

import 'package:flutter/material.dart';
import '../models/contribution_tier_model.dart';
import '../models/fee_model.dart';
import '../state/central_pool_controller.dart';

class SubmitParticipationRequestView extends StatefulWidget {
  final CentralPoolController controller;

  const SubmitParticipationRequestView({Key? key, required this.controller}) : super(key: key);

  @override
  State<SubmitParticipationRequestView> createState() => _SubmitParticipationRequestViewState();
}

class _SubmitParticipationRequestViewState extends State<SubmitParticipationRequestView> {
  // Available Ratified Active Tiers (FM-04 Ratified Option A: G1)
  final List<ContributionTierModel> _activeTiers = ContributionTierModel.activeProductionTiers;
  late ContributionTierModel _selectedTier;

  int _durationPeriods = 10;
  int _preferredPayoutPeriod = 3;
  int _payoutFlexibilityWindow = 1;
  final String _currency = 'EGP';

  final List<int> _allowedDurations = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  @override
  void initState() {
    super.initState();
    _selectedTier = _activeTiers.firstWhere(
      (t) => t.contributionMinor == 50000,
      orElse: () => _activeTiers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeConfig = widget.controller.feeConfig;
    final contributionMinor = _selectedTier.contributionMinor;
    
    // Fee Calculation outside C
    final int? calculatedFeeMinor = feeConfig?.calculateFeeMinor(contributionMinor);
    final int? periodicOutflowMinor = feeConfig != null && calculatedFeeMinor != null
        ? feeConfig.calculatePeriodicOutflowMinor(contributionMinor)
        : null;

    final theme = Theme.of(context);
    const emeraldColor = Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Pool Participation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Participation Preferences',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select your preferred contribution tier and duration. The platform headlessly matches capacity with mathematical symmetry.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // 1. Contribution Tier Selection (Exactly 5 Ratified Tiers)
                    const Text(
                      'Select Contribution Tier',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _activeTiers.map((tier) {
                        final isSelected = _selectedTier.tierId == tier.tierId;
                        return ChoiceChip(
                          key: Key('tier_chip_${tier.tierId}'),
                          label: Text(
                            tier.displayName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: emeraldColor,
                          backgroundColor: const Color(0xFF1E293B),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTier = tier;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Financial Summary Breakdown Card (Contribution vs Fee vs Outflow)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                                const Flexible(
                                  child: Text(
                                    'Periodic Contribution (C)',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedTier.formattedAmount} / period',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Platform Fee',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  calculatedFeeMinor != null
                                      ? '${(calculatedFeeMinor / 100).toStringAsFixed(0)} $_currency / period'
                                      : FeeConfigModel.disclosureUnavailableEn,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: calculatedFeeMinor != null ? emeraldColor : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Colors.white12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Estimated Periodic Outflow',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  periodicOutflowMinor != null
                                      ? '${(periodicOutflowMinor / 100).toStringAsFixed(0)} $_currency'
                                      : '${_selectedTier.formattedAmount} + applicable fee',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: emeraldColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Mandatory Fee Disclosure
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(Icons.info_outline, size: 16, color: emeraldColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      FeeConfigModel.mandatoryDisclosureEn,
                                      style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Duration (Periods N)
                    const Text('Duration (Periods / Months)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _durationPeriods,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      isExpanded: true,
                      items: _allowedDurations.map((d) {
                        return DropdownMenuItem<int>(
                          value: d,
                          child: Text('$d Months ($d Allocation Units)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _durationPeriods = val;
                            if (_preferredPayoutPeriod > val) {
                              _preferredPayoutPeriod = val;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Preferred Payout Period
                    Text(
                      'Preferred Payout Period (1 to $_durationPeriods)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: _preferredPayoutPeriod.toDouble(),
                      min: 1,
                      max: _durationPeriods.toDouble(),
                      divisions: _durationPeriods > 1 ? _durationPeriods - 1 : 1,
                      activeColor: emeraldColor,
                      label: 'Month $_preferredPayoutPeriod',
                      onChanged: (val) {
                        setState(() => _preferredPayoutPeriod = val.toInt());
                      },
                    ),
                    Center(
                      child: Text(
                        'Target Preference: Month $_preferredPayoutPeriod',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Flexibility Window
                    const Text('Flexibility Window (+/- Months)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _payoutFlexibilityWindow,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      isExpanded: true,
                      items: [0, 1, 2].map((w) {
                        return DropdownMenuItem<int>(
                          value: w,
                          child: Text('+/- $w Months'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _payoutFlexibilityWindow = val);
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit CTA
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          final idempotencyKey = 'idem_submit_${DateTime.now().millisecondsSinceEpoch}';
                          widget.controller.selectedTier = _selectedTier;
                          widget.controller.submitParticipationRequest(
                            monthlyContributionMinor: _selectedTier.contributionMinor,
                            durationPeriods: _durationPeriods,
                            preferredPayoutPeriod: _preferredPayoutPeriod,
                            payoutFlexibilityWindow: _payoutFlexibilityWindow,
                            currency: _currency,
                            idempotencyKey: idempotencyKey,
                            tierId: _selectedTier.tierId,
                            tierDisplayName: _selectedTier.displayName,
                          );
                        },
                        child: const Text('Find Compatible Matches'),
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

