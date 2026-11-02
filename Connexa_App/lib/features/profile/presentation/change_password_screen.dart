import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/security_providers.dart';

/// Screen allowing authenticated members to change their account password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _revokeOtherSessions = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final String current = _currentPasswordController.text;
    final String newPass = _newPasswordController.text;
    final String confirm = _confirmPasswordController.text;

    setState(() {
      _currentError = current.isEmpty ? 'Please enter your current password' : null;
      _newError =
          !_isPasswordValid ? 'Password must satisfy all security requirements' : null;
      _confirmError =
          newPass != confirm ? 'Passwords do not match' : null;
    });

    if (_currentError != null || _newError != null || _confirmError != null) {
      return;
    }

    final bool success = await ref
        .read(changePasswordProvider.notifier)
        .changePassword(
          currentPassword: current,
          newPassword: newPass,
          confirmPassword: confirm,
          revokeOtherSessions: _revokeOtherSessions,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account-settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChangePasswordState state = ref.watch(changePasswordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/account-settings');
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
                const SizedBox(height: AppSpacing.lg),

                // Error Banner
                if (state.errorMessage != null) ...<Widget>[
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
                            state.errorMessage!,
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
                      // Current Password
                      AppTextField(
                        key: const Key('changePasswordCurrentField'),
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        hintText: 'Enter existing password',
                        obscureText: _obscureCurrent,
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                        errorText: _currentError,
                        enabled: !state.isLoading,
                        onChanged: (_) {
                          if (_currentError != null) {
                            setState(() => _currentError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // New Password
                      AppTextField(
                        key: const Key('changePasswordNewField'),
                        controller: _newPasswordController,
                        label: 'New Password',
                        hintText: 'Enter new strong password',
                        obscureText: _obscureNew,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        errorText: _newError,
                        enabled: !state.isLoading,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Confirm Password
                      AppTextField(
                        key: const Key('changePasswordConfirmField'),
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hintText: 'Re-enter new password',
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
                        enabled: !state.isLoading,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Policy Checklist
                      _buildPolicyIndicators(),
                      const SizedBox(height: AppSpacing.lg),

                      // Sign out of other sessions switch
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Sign out of other devices',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Recommended for security when updating credentials.',
                            style: AppTextStyles.bodySmall,
                          ),
                          value: _revokeOtherSessions,
                          activeTrackColor: AppColors.primary,
                          onChanged: state.isLoading
                              ? null
                              : (bool val) =>
                                  setState(() => _revokeOtherSessions = val),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      AppButton.primary(
                        key: const Key('changePasswordSubmitButton'),
                        text: 'Update Password',
                        isFullWidth: true,
                        isLoading: state.isLoading,
                        trailingIcon: const Icon(
                          Icons.check_rounded,
                          size: 18,
                        ),
                        onPressed: state.isLoading ? null : _submit,
                      ),
                    ],
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
            'Password Policy Requirements',
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
