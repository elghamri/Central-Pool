import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// Screen 1: Splash & Session Restoration Screen.
class SplashScreen extends StatelessWidget {
  final String statusMessage;

  const SplashScreen({
    super.key,
    this.statusMessage = 'Restoring Secure Session...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Institutional Brand Shield Icon
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4), width: 2.0),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 56.0,
                color: AppColors.emeraldGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Collaborative Finance Platform',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Unified Liquidity Pool & Cooperative Engine',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              height: 24.0,
              width: 24.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.sovereignGold),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              statusMessage,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
