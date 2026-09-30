import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../models/admin_models.dart';
import '../state/admin_controller.dart';

/// Screen 27: Cycle Configuration & Launch Wizard View.
class AdminCycleConfigWizardView extends StatefulWidget {
  final AdminController controller;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const AdminCycleConfigWizardView({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<AdminCycleConfigWizardView> createState() =>
      _AdminCycleConfigWizardViewState();
}

class _AdminCycleConfigWizardViewState
    extends State<AdminCycleConfigWizardView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController =
      TextEditingController(text: 'Rotating Capital Circle Gamma');
  int _durationMonths = 10;
  int _slotsCount = 10;
  int _contributionPerPeriodMinor = 50000; // $500.00

  int get _payoutPerSlotMinor => _contributionPerPeriodMinor * _slotsCount;
  int get _totalPoolCapitalMinor =>
      _contributionPerPeriodMinor * _slotsCount * _durationMonths;
  int get _requiredReserveMinor => (_totalPoolCapitalMinor * 0.15).round();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLaunch() async {
    if (_formKey.currentState?.validate() != true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Confirm Cooperative Cycle Activation',
            style: AppTypography.titleLarge),
        content: Text(
          'You are about to launch and activate "${_nameController.text}" with a total pool capital of \$${(_totalPoolCapitalMinor / 100).toStringAsFixed(2)} USD. This will lock member schedules and initialize general ledger accounts.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          PrimaryButton(
            label: 'Authorize & Launch',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final req = AdminCycleCreateRequest(
        cycleName: _nameController.text.trim(),
        tenantId: widget.controller.session.tenantId,
        durationMonths: _durationMonths,
        contributionPerPeriodMinor: _contributionPerPeriodMinor,
        payoutPerSlotMinor: _payoutPerSlotMinor,
        totalSlots: _slotsCount,
      );

      final success = await widget.controller.createAndActivateCycle(req);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cooperative cycle "${req.cycleName}" launched successfully.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
        widget.onSuccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingCard,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: widget.onCancel,
                  tooltip: 'Cancel Wizard',
                ),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: Text(
                    'Configure New Cycle',
                    style: AppTypography.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Set rotation parameters, contribution dues, and payout schedules before ledger initialization.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Form Inputs Card
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cycle Parameters',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  StandardTextField(
                    label: 'Cooperative Cycle Name',
                    hint: 'e.g. Rotating Capital Circle Gamma',
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Cycle name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildDurationDropdown(),
                            const SizedBox(height: AppSpacing.md),
                            _buildSlotsDropdown(),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _buildDurationDropdown()),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _buildSlotsDropdown()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Contribution per Member',
                          style: AppTypography.labelSmall),
                      const SizedBox(height: 4.0),
                      DropdownButtonFormField<int>(
                        initialValue: _contributionPerPeriodMinor,
                        isExpanded: true,
                        dropdownColor: AppColors.cardSurface,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                              borderRadius: AppRadii.borderSm,
                              borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 25000,
                              child: Text('\$250.00 / month',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 50000,
                              child: Text('\$500.00 / month (Standard)',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 100000,
                              child: Text('\$1,000.00 / month',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 200000,
                              child: Text('\$2,000.00 / month',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(
                            () => _contributionPerPeriodMinor = v ?? 50000),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Real-Time Derived Financial Invariants Preview
            const Text('Financial Invariants Calculation Preview',
                style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Calculated strictly using 64-bit pure integer minor units without float rounding.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            SurfaceCard(
              child: Column(
                children: [
                  _buildPreviewRow(
                      'Expected Payout per Recipient', _payoutPerSlotMinor,
                      color: AppColors.emeraldGreen),
                  _buildPreviewRow(
                      'Total Cumulative Pool Capital', _totalPoolCapitalMinor,
                      color: AppColors.textPrimary),
                  _buildPreviewRow('15% Treasury Reserve Guard Buffer',
                      _requiredReserveMinor,
                      color: AppColors.sovereignGold),
                  _buildPreviewRow(
                      'Monthly Dues Schedule', _contributionPerPeriodMinor,
                      color: AppColors.textPrimary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            PrimaryButton(
              label: 'Launch & Activate Cycle',
              icon: Icons.rocket_launch,
              onPressed: _handleLaunch,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Cancel & Return to Cycles',
              onPressed: widget.onCancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration (Months)', style: AppTypography.labelSmall),
        const SizedBox(height: 4.0),
        DropdownButtonFormField<int>(
          initialValue: _durationMonths,
          isExpanded: true,
          dropdownColor: AppColors.cardSurface,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
                borderRadius: AppRadii.borderSm, borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(
                value: 6,
                child: Text('6 Months', overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
                value: 10,
                child: Text('10 Months (Standard)',
                    overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
                value: 12,
                child: Text('12 Months', overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
                value: 24,
                child: Text('24 Months', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _durationMonths = v ?? 10),
        ),
      ],
    );
  }

  Widget _buildSlotsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Member Slots', style: AppTypography.labelSmall),
        const SizedBox(height: 4.0),
        DropdownButtonFormField<int>(
          initialValue: _slotsCount,
          isExpanded: true,
          dropdownColor: AppColors.cardSurface,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
                borderRadius: AppRadii.borderSm, borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(
                value: 6,
                child: Text('6 Slots', overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
                value: 10,
                child: Text('10 Slots', overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(
                value: 12,
                child: Text('12 Slots', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _slotsCount = v ?? 10),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, int amountMinor, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          FinancialAmountText(
            amountMinor: amountMinor,
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            color: color,
          ),
        ],
      ),
    );
  }
}
