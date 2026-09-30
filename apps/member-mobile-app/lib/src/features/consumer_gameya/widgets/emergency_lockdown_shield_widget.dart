import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// 1-Click Platform Emergency Lockdown Shield Widget.
/// Implements high-visibility fail-closed kill switch with two-step confirmation.
class EmergencyLockdownShieldWidget extends StatefulWidget {
  final bool isLockdownActive;
  final ValueChanged<String>? onLockdownTriggered;

  const EmergencyLockdownShieldWidget({
    super.key,
    this.isLockdownActive = false,
    this.onLockdownTriggered,
  });

  @override
  State<EmergencyLockdownShieldWidget> createState() => _EmergencyLockdownShieldWidgetState();
}

class _EmergencyLockdownShieldWidgetState extends State<EmergencyLockdownShieldWidget> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isLockdownActive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: active ? AppColors.crimsonRed.withValues(alpha: 0.15) : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.crimsonRed : AppColors.borderSubtle,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (active ? AppColors.crimsonRed : AppColors.amberWarning).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield,
                  color: active ? AppColors.crimsonRed : AppColors.amberWarning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'EMERGENCY LOCKDOWN ACTIVE' : 'FAIL-CLOSED CIRCUIT BREAKER',
                      style: TextStyle(
                        color: active ? AppColors.crimsonRed : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active
                          ? 'All real-money movements and disbursement batches are locked.'
                          : 'Immediate 1-click cessation of all financial and payout operations.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isConfirming) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.crimsonRed),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIRM EMERGENCY LOCKDOWN?',
                    style: TextStyle(color: AppColors.crimsonRed, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This will immediately reject all Cloud Function financial mutations and trigger fail-closed state.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isConfirming = false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _isConfirming = false);
                            widget.onLockdownTriggered?.call('Operator Emergency Lockdown Activation');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.crimsonRed,
                          ),
                          child: const Text('CONFIRM LOCKDOWN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: active ? null : () => setState(() => _isConfirming = true),
                icon: const Icon(Icons.lock, size: 18),
                label: Text(active ? 'LOCKDOWN ENGAGED' : 'TRIGGER EMERGENCY LOCKDOWN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: active ? AppColors.surfaceElevated : AppColors.crimsonRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
