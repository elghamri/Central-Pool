import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/models/auth_dto.dart';

/// Screen 2: Sign In & Authentication Screen according to Stitch Design Baseline.
class LoginScreen extends StatefulWidget {
  final ValueChanged<LoginRequest> onSubmit;
  final VoidCallback onNavigateToRegister;
  final bool isLoading;
  final String? errorMessage;
  final bool isRtl;

  const LoginScreen({
    super.key,
    required this.onSubmit,
    required this.onNavigateToRegister,
    this.isLoading = false,
    this.errorMessage,
    this.isRtl = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(
    text: kReleaseMode ? '' : 'member@collaborativefinance.org',
  );
  final _passwordController = TextEditingController(
    text: kReleaseMode ? '' : 'Password123!',
  );
  String _selectedTenant = 'TENANT-ALPHA';

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        LoginRequest(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
          tenantId: _selectedTenant,
        ),
      );
    }
  }

  void _selectPresetRole(String email, String tenant) {
    setState(() {
      _identifierController.text = email;
      _selectedTenant = tenant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.deepSlate,
        appBar: AppBar(
          title: Text(isRtl ? 'تسجيل الدخول' : 'Sign In'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingCard,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      Text(
                        isRtl ? 'مرحباً بعودتك' : 'Welcome Back',
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isRtl
                            ? 'سجل الدخول للوصول إلى لوحة التحكم وسجلاتك المالية التعاونية.'
                            : 'Access your cooperative dashboard and financial records.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Error Alert Banner
                      if (widget.errorMessage != null) ...[
                        AlertBanner(
                          title: isRtl ? 'خطأ في المصادقة' : 'Authentication Error',
                          message: widget.errorMessage!,
                          color: AppColors.crimsonRed,
                          icon: Icons.error_outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Tenant Dropdown (Debug/Development Only)
                      if (!kReleaseMode) ...[
                        Text(
                          isRtl ? 'المؤسسة التعاونية / المستأجر' : 'Tenant / Cooperative Organization',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: AppRadii.borderMd,
                            border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTenant,
                              isExpanded: true,
                              dropdownColor: AppColors.cardSurface,
                              style: AppTypography.bodyLarge,
                              items: const [
                                DropdownMenuItem(value: 'TENANT-ALPHA', child: Text('TENANT-ALPHA (Retail Cooperative)')),
                                DropdownMenuItem(value: 'TENANT-BETA', child: Text('TENANT-BETA (Commercial Pool)')),
                                DropdownMenuItem(value: 'TENANT-PROD-ALPHA', child: Text('TENANT-PROD-ALPHA (Production)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedTenant = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Identifier Field
                      StandardTextField(
                        label: isRtl ? 'البريد الإلكتروني أو اسم المستخدم' : 'Email or Username',
                        hint: 'user@organization.org',
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted, size: 20.0),
                        validator: (val) => val == null || val.isEmpty
                            ? (isRtl ? 'يرجى إدخال المعرف' : 'Please enter identifier')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Password Field
                      SecurePasswordField(
                        label: isRtl ? 'كلمة المرور' : 'Password',
                        controller: _passwordController,
                        validator: (val) => val == null || val.length < 6
                            ? (isRtl ? 'يجب ألا تقل كلمة المرور عن 6 أحرف' : 'Password must be at least 6 characters')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Sign In Button
                      PrimaryButton(
                        label: isRtl ? 'دخول آمن' : 'Sign In',
                        icon: Icons.lock_open,
                        isLoading: widget.isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Quick Demo Role Presets (Debug/Development Only)
                      if (!kReleaseMode) ...[
                        SurfaceCard(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRtl ? 'أدوار العرض السريع' : 'Quick Demo Roles',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.sovereignGold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  _buildRoleChip(isRtl ? 'عضو' : 'Member', 'member@collaborativefinance.org', 'TENANT-ALPHA'),
                                  _buildRoleChip(isRtl ? 'مشرف' : 'Admin', 'admin@collaborativefinance.org', 'TENANT-ALPHA'),
                                  _buildRoleChip(isRtl ? 'مُنشئ' : 'Maker', 'maker.officer@collaborativefinance.org', 'TENANT-ALPHA'),
                                  _buildRoleChip(isRtl ? 'مُدقّق' : 'Checker', 'checker.officer@collaborativefinance.org', 'TENANT-ALPHA'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Register Link
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              isRtl ? 'ليس لديك حساب بعد؟ ' : 'Don\'t have an account? ',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            GhostButton(
                              label: isRtl ? 'سجل هنا' : 'Register here',
                              onPressed: widget.onNavigateToRegister,
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

  Widget _buildRoleChip(String label, String email, String tenant) {
    return ActionChip(
      label: Text(label, style: AppTypography.labelSmall),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.borderSubtle),
      onPressed: () => _selectPresetRole(email, tenant),
    );
  }
}
