import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';

/// Responsive login screen supporting email and phone authentication.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final String identifier = _identifierController.text.trim();
    final String password = _passwordController.text;

    setState(() {
      _identifierError = identifier.isEmpty
          ? 'Email or phone number is required'
          : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;
    });

    if (_identifierError != null || _passwordError != null) return;

    final bool success = await ref
        .read(authProvider.notifier)
        .login(identifier, password);

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppSpacing.xl),

                // Brand Icon Badge
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color: AppColors.secondaryContainer,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_person_rounded,
                        size: 38,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title & Subtitle
                const Text(
                  'Welcome Back to Connexa',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Access your verified business network and profile.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Error Banner
                if (authState.errorMessage != null) ...<Widget>[
                  _buildErrorBanner(authState.errorMessage!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Login Form Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Identifier Input (Email or Mobile)
                      AppTextField(
                        key: const Key('loginIdentifierField'),
                        controller: _identifierController,
                        label: 'Email or Mobile Number',
                        hintText: 'e.g. name@company.com or 9876543210',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                        errorText: _identifierError,
                        enabled: !authState.isLoading,
                        onChanged: (_) {
                          if (_identifierError != null) {
                            setState(() => _identifierError = null);
                          }
                          ref.read(authProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Password Input
                      AppTextField(
                        key: const Key('loginPasswordField'),
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        errorText: _passwordError,
                        enabled: !authState.isLoading,
                        onSubmitted: (_) => _validateAndSubmit(),
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                          ref.read(authProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      AppButton.primary(
                        key: const Key('loginSubmitButton'),
                        text: 'Sign In',
                        isFullWidth: true,
                        isLoading: authState.isLoading,
                        trailingIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        onPressed: authState.isLoading
                            ? null
                            : _validateAndSubmit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Register & Setup Password Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Don’t have an account?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      key: const Key('goToRegisterLink'),
                      onTap: () => context.go('/registration'),
                      child: Text(
                        'Register',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Center(
                  child: TextButton.icon(
                    key: const Key('goToSetupPasswordLink'),
                    icon: const Icon(Icons.key_outlined, size: 16),
                    label: const Text('Set up password for existing account'),
                    onPressed: () => context.go('/setup-password'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              key: const Key('loginErrorMessage'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
