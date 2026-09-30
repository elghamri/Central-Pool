import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../state/gameya_controller.dart';
import '../i18n/gameya_strings.dart';

/// Surface D (Tab 3): Member Profile, Verified Identity, Payout Destination, and Preferences.
class ConsumerProfileView extends StatelessWidget {
  final GameyaController controller;
  final VoidCallback? onLogout;

  const ConsumerProfileView({
    super.key,
    required this.controller,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameyaState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state is! GameyaLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.emeraldGreen));
        }

        final strings = GameyaStrings.of(state.languageCode);
        final profile = state.profile;
        final isArabic = state.languageCode == 'ar';

        return Directionality(
          textDirection: strings.textDirection,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  strings.profileTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Identity & Avatar Hero Card
                _buildIdentityHeroCard(profile, strings),

                const SizedBox(height: 16),

                // 2. Trust Score & Track Record Matrix
                _buildTrustMatrixCard(profile, strings),

                const SizedBox(height: 16),

                // 3. Payout Destination Account Card
                _buildPayoutDestinationCard(profile, strings),

                const SizedBox(height: 16),

                // 4. Language & RTL Selector
                _buildLanguageSelectorCard(context, state.languageCode, strings, isArabic),

                const SizedBox(height: 16),

                // 5. Notification & Alert Preferences
                _buildNotificationPreferencesCard(profile, strings),

                const SizedBox(height: 24),

                // 6. Logout Button
                DangerButton(
                  label: isArabic ? 'تسجيل الخروج' : 'Sign Out',
                  icon: Icons.logout,
                  onPressed: onLogout ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully.'),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                      },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityHeroCard(profile, GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
            child: Text(
              profile.fullName.isNotEmpty ? profile.fullName.substring(0, 1).toUpperCase() : 'A',
              style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    strings.identityVerified,
                    style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustMatrixCard(profile, GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustMetric('★ ${profile.trustScore.toStringAsFixed(1)}', strings.trustScoreLabel),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildTrustMetric('${profile.completedCirclesCount}', strings.completedCirclesLabel),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildTrustMetric('${profile.activeCirclesCount}', strings.activeCirclesCountLabel),
        ],
      ),
    );
  }

  Widget _buildTrustMetric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutDestinationCard(profile, GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.payoutDestination,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance, color: AppColors.emeraldGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.bankAccountName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Direct Deposit (${profile.bankAccountMasked}) • Verified',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: AppColors.emeraldGreen, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorCard(BuildContext context, String currentLang, GameyaStrings strings, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.languagePreference,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => controller.toggleLanguage('en'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isArabic ? AppColors.emeraldGreen : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: !isArabic ? AppColors.emeraldGreen : AppColors.borderSubtle),
                    ),
                    child: Center(
                      child: Text(
                        'English (LTR)',
                        style: TextStyle(
                          color: !isArabic ? Colors.black : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => controller.toggleLanguage('ar'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isArabic ? AppColors.emeraldGreen : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isArabic ? AppColors.emeraldGreen : AppColors.borderSubtle),
                    ),
                    child: Center(
                      child: Text(
                        'العربية (RTL)',
                        style: TextStyle(
                          color: isArabic ? Colors.black : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard(profile, GameyaStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.notificationsSettings,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Payment Due Reminders', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Switch(
                value: profile.pushNotificationsEnabled,
                onChanged: (_) {},
                activeThumbColor: AppColors.emeraldGreen,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Payout Turn Notifications', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Switch(
                value: profile.smsAlertsEnabled,
                onChanged: (_) {},
                activeThumbColor: AppColors.emeraldGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
