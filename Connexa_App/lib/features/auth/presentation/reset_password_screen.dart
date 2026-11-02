import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/providers/security_providers.dart';

/// Screen allowing users to enter OTP and set a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.initialResponse,
  });

  final String identifier;
  final ForgotPasswordResponse initialResponse;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late ForgotPasswordResponse _response;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _otpError;
  String? _passwordError;
  String? _confirmError;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _response = widget.initialResponse;
    _startCooldown(60);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_newPasswordController.text);
  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  bool get _isPasswordValid =>
      _hasMinLength && _hasUpper && _hasLower && _hasNumber && _hasSpecial;

  Future<void> _resendOtp() async {
    if (_cooldownSeconds > 0) return;

    final ForgotPasswordResponse? response = await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetOtp(
          identifier: widget.identifier,
          preferredChannel: _response.channel,
        );

    if (response != null && mounted) {
      setState(() {
        _response = response;
      });
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh code has been sent to ${_response.maskedDestination}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _validateAndSubmit() async {
    final String otp = _otpController.text.trim();
    final String newPassword = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    setState(() {
      _otpError = otp.length < 6 ? 'Please enter the 6-digit verification code' : null;
      _passwordError =
          !_isPasswordValid ? 'Password must satisfy all security requirements' : null;
      _confirmError =
          newPassword != confirmPassword ? 'Passwords do not match' : null;
    });

    if (_otpError != null || _passwordError != null || _confirmError != null) {
      return;
    }

    final bool success = await ref
        .read(resetPasswordProvider.notifier)
        .resetPassword(
          identifier: widget.identifier,
          otpCode: otp,
          flowId: _response.flowId,
          challengeId: _response.challengeId,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );

    if (success && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: AppSpacing.sm),
              Text('Password Reset'),
            ],
          ),
          content: const Text(
            'Your password has been successfully updated. Please sign in with your new password.',
          ),
          actions: <Widget>[
            AppButton.primary(
              text: 'Sign In Now',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResetPasswordState resetState = ref.watch(resetPasswordProvider);
    final ForgotPasswordState resendState = ref.watch(forgotPasswordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set New Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: 500,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppSpacing.xl),

                // Icon Badge
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
                        Icons.vpn_key_rounded,
                        size: 38,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Destination Info
                Text(
                  'Code Sent to ${_response.maskedDestination}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the 6-digit code received via ${_response.channel} and choose your new password.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Error Banner
                if (resetState.errorMessage != null) ...<Widget>[
                  Container(
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
                            resetState.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Form Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // OTP Field
                      AppTextField(
                        key: const Key('resetPasswordOtpField'),
                        controller: _otpController,
                        label: '6-Digit Verification Code',
                        hintText: 'Enter code (e.g. 123456)',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          size: 20,
                        ),
                        errorText: _otpError,
                        enabled: !resetState.isLoading,
                        onChanged: (_) {
                          if (_otpError != null) {
                            setState(() => _otpError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Resend Code Action
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('resetPasswordResendButton'),
                          onPressed: (_cooldownSeconds == 0 &&
                                  !resendState.isLoading &&
                                  !resetState.isLoading)
                              ? _resendOtp
                              : null,
                          child: Text(
                            _cooldownSeconds > 0
                                ? 'Resend code in ${_cooldownSeconds}s'
                                : 'Resend Verification Code',
                            style: TextStyle(
                              color: _cooldownSeconds > 0
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // New Password Field
                      AppTextField(
                        key: const Key('resetPasswordNewField'),
                        controller: _newPasswordController,
                        label: 'New Password',
                        hintText: 'Enter strong password',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        errorText: _passwordError,
                        enabled: !resetState.isLoading,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Confirm Password Field
                      AppTextField(
                        key: const Key('resetPasswordConfirmField'),
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hintText: 'Re-enter your new password',
                        obscureText: _obscureConfirm,
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        errorText: _confirmError,
                        enabled: !resetState.isLoading,
                        onSubmitted: (_) => _validateAndSubmit(),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Policy Checklist
                      _buildPolicyIndicators(),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      AppButton.primary(
                        key: const Key('resetPasswordSubmitButton'),
                        text: 'Update Password & Sign In',
                        isFullWidth: true,
                        isLoading: resetState.isLoading,
                        trailingIcon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        onPressed:
                            resetState.isLoading ? null : _validateAndSubmit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: TextButton.icon(
                    key: const Key('resetPasswordCancelButton'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Cancel and Return to Sign In'),
                    onPressed: () => context.go('/login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyIndicators() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Password Requirements',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPolicyItem('At least 8 characters', _hasMinLength),
          _buildPolicyItem('At least 1 uppercase letter (A–Z)', _hasUpper),
          _buildPolicyItem('At least 1 lowercase letter (a–z)', _hasLower),
          _buildPolicyItem('At least 1 number (0–9)', _hasNumber),
          _buildPolicyItem(
            'At least 1 special character (!@#\$%^&*)',
            _hasSpecial,
          ),
          _buildPolicyItem('Passwords match', _passwordsMatch),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            isSatisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isSatisfied ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSatisfied
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
