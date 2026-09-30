import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/auth_dto.dart';

/// Screen 4: OTP / Multi-Factor Step-Up Challenge Screen according to Stitch Design Baseline.
class VerifyOtpScreen extends StatefulWidget {
  final String identifier;
  final String tenantId;
  final ValueChanged<VerifyOtpRequest> onVerify;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? errorMessage;
  final bool isRtl;

  const VerifyOtpScreen({
    super.key,
    required this.identifier,
    required this.tenantId,
    required this.onVerify,
    required this.onCancel,
    this.isLoading = false,
    this.errorMessage,
    this.isRtl = false,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController(text: kReleaseMode ? '' : '123456');

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp() {
    final code = _otpController.text.trim();
    if (code.length == 6) {
      widget.onVerify(
        VerifyOtpRequest(
          identifier: widget.identifier,
          otpCode: code,
          tenantId: widget.tenantId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: AppBar(
          title: Text(isRtl ? 'التحقق الأمني' : 'Security Verification'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingCard,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.sovereignGold.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sovereignGold.withValues(alpha: 0.15),
                            blurRadius: 16.0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.security_outlined, size: 40.0, color: AppColors.sovereignGold),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      isRtl ? 'أدخل رمز التحقق' : 'Enter Verification Code',
                      style: AppTypography.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isRtl
                          ? 'أرسلنا رمز أمان مكون من 6 أرقام إلى:\n${widget.identifier}'
                          : 'We sent a 6-digit security code to:\n${widget.identifier}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (widget.errorMessage != null) ...[
                      AlertBanner(
                        title: isRtl ? 'فشل التحقق' : 'Verification Failed',
                        message: widget.errorMessage!,
                        color: AppColors.crimsonRed,
                        icon: Icons.error_outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 6-digit OTP Visual Boxes
                    _buildVisualOtpBoxes(),
                    const SizedBox(height: AppSpacing.md),

                    // Hidden/Overlay text field for keyboard capture
                    Opacity(
                      opacity: 0.0,
                      child: SizedBox(
                        height: 0,
                        child: TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitOtp(),
                        ),
                      ),
                    ),

                    // Primary Submit
                    PrimaryButton(
                      label: isRtl ? 'تأكيد الرمز والدخول' : 'Verify & Sign In',
                      icon: Icons.verified_outlined,
                      isLoading: widget.isLoading,
                      onPressed: _submitOtp,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cancel
                    SecondaryButton(
                      label: isRtl ? 'إلغاء والعودة' : 'Cancel & Return',
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualOtpBoxes() {
    final text = _otpController.text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final char = index < text.length ? text[index] : '';
        final isFocused = index == text.length || (index == 5 && text.length == 6);

        return Container(
          width: 44.0,
          height: 52.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadii.borderSm,
            border: Border.all(
              color: isFocused ? AppColors.emeraldGreen : AppColors.borderSubtle,
              width: isFocused ? 2.0 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                      blurRadius: 8.0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              char,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
