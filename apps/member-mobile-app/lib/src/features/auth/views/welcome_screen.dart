import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// Screen 1: Welcome & Onboarding Landing Screen according to Stitch Design Baseline.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final ValueChanged<String>? onLanguageChanged;
  final String initialLanguage;

  const WelcomeScreen({
    super.key,
    required this.onSignIn,
    required this.onRegister,
    this.onLanguageChanged,
    this.initialLanguage = 'en',
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.initialLanguage;
  }

  bool get _isRtl => _currentLang == 'ar';

  void _toggleLanguage(String lang) {
    setState(() => _currentLang = lang);
    widget.onLanguageChanged?.call(lang);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingCard,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Switcher Toggle
                    Align(
                      alignment: _isRtl ? Alignment.topLeft : Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: AppRadii.borderSm,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLangButton('en', 'English'),
                            _buildLangButton('ar', 'العربية'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Brand Icon & Pulsar Halo
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.emeraldGreen, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.25),
                            blurRadius: 24.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.diversity_3_outlined,
                        size: 48.0,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      _isRtl ? 'منصة التمويل التعاوني' : 'Collaborative Finance',
                      style: AppTypography.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      _isRtl
                          ? 'صناديق تمويل تعاونية دورية تتسم بالشفافية والعدالة الرياضية دون أي رسوم خفية.'
                          : 'Transparent, rotating cooperative capital pools with mathematical certainty and zero hidden fees.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Feature Badges
                    SurfaceCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            Icons.verified_user_outlined,
                            _isRtl ? 'أمان مؤسسي موثوق' : 'Institutional Trust',
                            _isRtl
                                ? 'دفتر أستاذ مزدوج القيد مع سجلات تدقيق غير قابلة للتعديل'
                                : 'Double-entry GL with immutable HSM audit trails',
                          ),
                          const Divider(color: AppColors.borderSubtle, height: 20.0),
                          _buildFeatureRow(
                            Icons.speed_outlined,
                            _isRtl ? 'مطابقة وتسوية دورية' : 'Automated Clearing',
                            _isRtl
                                ? 'مطابقة متوازنة وتسوية دورية مؤتمتة'
                                : 'Automated Periodic Matching & Clearing',
                          ),
                          const Divider(color: AppColors.borderSubtle, height: 20.0),
                          _buildFeatureRow(
                            Icons.balance_outlined,
                            _isRtl ? 'عدالة متكافئة' : 'Deterministic Fairness',
                            _isRtl
                                ? 'جدولة متوازنة للأدوار واحتياطي أمان بنسبة 15%'
                                : 'Round-robin cycle scheduling & 15% reserve guards',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Action Buttons
                    PrimaryButton(
                      label: _isRtl ? 'تسجيل الدخول إلى الحساب' : 'Sign In to Account',
                      icon: Icons.login,
                      onPressed: widget.onSignIn,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: _isRtl ? 'إنشاء حساب عضو جديد' : 'Create Member Account',
                      icon: Icons.person_add_outlined,
                      onPressed: widget.onRegister,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Trust Footer
                    Text(
                      _isRtl
                          ? 'محمي بتقنيات إثبات المعرفة الصفرية وعزل البيانات متعدد المستأجرين'
                          : 'Protected by Zero-Knowledge Identity & Multi-Tenant Isolation',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String langCode, String label) {
    final isSelected = _currentLang == langCode;
    return InkWell(
      onTap: () => _toggleLanguage(langCode),
      borderRadius: AppRadii.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldGreen.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: AppRadii.borderSm,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 22.0, color: AppColors.sovereignGold),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
