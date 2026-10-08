import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/auth_dto.dart';
import '../../../core/models/user_session.dart';

/// Screen 3: Member Registration & Onboarding Screen according to Stitch Design Baseline.
class RegisterScreen extends StatefulWidget {
  final ValueChanged<RegisterRequest> onSubmit;
  final VoidCallback onNavigateToLogin;
  final bool isLoading;
  final String? errorMessage;
  final bool isRtl;

  const RegisterScreen({
    super.key,
    required this.onSubmit,
    required this.onNavigateToLogin,
    this.isLoading = false,
    this.errorMessage,
    this.isRtl = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final String _selectedTenant = 'TENANT-ALPHA';
  final UserRole _selectedRole = UserRole.member; // Invariant: Member registration only
  bool _consentAgreed = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final isRtl = widget.isRtl;
    if (!_consentAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl
              ? 'يرجى الموافقة على شروط خدمة منصة الحوض المركزي وضوابط المحاسبة.'
              : 'Please accept the Central Pool platform terms and accounting invariants.'),
          backgroundColor: AppColors.crimsonRed,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        RegisterRequest(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          tenantId: _selectedTenant,
          role: _selectedRole,
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
          title: Text(isRtl ? 'إنشاء حساب في الحوض المركزي' : 'Create Central Pool Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingCard,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl
                            ? 'إنشاء حساب في الحوض المركزي'
                            : 'Create Central Pool Account',
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isRtl
                            ? 'انضم إلى منصة إدارة السيولة التشاركية للحوض المركزي.'
                            : 'Join the Central Pool rotating liquidity platform.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      if (widget.errorMessage != null) ...[
                        AlertBanner(
                          title:
                              isRtl ? 'خطأ في التسجيل' : 'Registration Error',
                          message: widget.errorMessage!,
                          color: AppColors.crimsonRed,
                          icon: Icons.error_outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Full Name
                      StandardTextField(
                        label:
                            isRtl ? 'الاسم القانوني الكامل' : 'Full Legal Name',
                        hint: isRtl ? 'أحمد محمود' : 'Sarah Jenkins',
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.badge_outlined,
                            color: AppColors.textMuted, size: 20.0),
                        validator: (val) => val == null || val.isEmpty
                            ? (isRtl
                                ? 'يرجى إدخال الاسم الكامل'
                                : 'Please enter full name')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Email Address
                      StandardTextField(
                        label: isRtl ? 'البريد الإلكتروني' : 'Email Address',
                        hint: 'user@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.textMuted, size: 20.0),
                        validator: (val) => val == null || !val.contains('@')
                            ? (isRtl
                                ? 'أدخل بريداً إلكترونياً صالحاً'
                                : 'Enter a valid email')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Phone Number
                      StandardTextField(
                        label: isRtl
                            ? 'رقم الهاتف المحمول'
                            : 'Mobile Phone Number',
                        hint: '+20 100 123 4567',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: AppColors.textMuted, size: 20.0),
                        validator: (val) => val == null || val.isEmpty
                            ? (isRtl
                                ? 'يرجى إدخال رقم الهاتف'
                                : 'Please enter mobile number')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Password
                      SecurePasswordField(
                        label: isRtl
                            ? 'إنشاء كلمة مرور قوية'
                            : 'Create Secure Password',
                        controller: _passwordController,
                        validator: (val) => val == null || val.length < 8
                            ? (isRtl
                                ? 'يجب ألا تقل كلمة المرور عن 8 أحرف'
                                : 'Password must be at least 8 characters')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Consent Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _consentAgreed,
                            activeColor: AppColors.emeraldGreen,
                            checkColor: AppColors.deepSlate,
                            onChanged: (val) =>
                                setState(() => _consentAgreed = val ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                isRtl
                                    ? 'أوافق على شروط خدمة منصة الحوض المركزي، وقواعد الحوكمة، وضوابط المحاسبة مزدوجة القيد.'
                                    : 'I agree to the Central Pool Platform Terms of Service, Governance Rules, and Double-Entry Accounting Invariants.',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      PrimaryButton(
                        label: isRtl
                            ? 'إنشاء حساب العضو'
                            : 'Create Member Account',
                        icon: Icons.person_add,
                        isLoading: widget.isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Back to Login
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isRtl
                                  ? 'لديك حساب بالفعل؟ '
                                  : 'Already have an account? ',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            GhostButton(
                              label: isRtl ? 'تسجيل الدخول' : 'Sign In',
                              onPressed: widget.onNavigateToLogin,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
