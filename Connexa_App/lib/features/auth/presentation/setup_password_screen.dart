import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/auth/services/auth_service.dart';

/// Screen allowing newly registered or verified members to set up their password securely.
///
/// If a valid single-use setup token is already authorized (from immediate registration or
/// previous step), the user is presented with the password creation form directly.
/// If no valid setup token is available, the screen provides a secure verification flow
/// via registered Email or WhatsApp OTP rather than asking the user to enter an unknown token.
class SetupPasswordScreen extends ConsumerStatefulWidget {
  const SetupPasswordScreen({
    super.key,
    this.initialCredentialSetupToken,
    this.initialDestination,
  });

  final String? initialCredentialSetupToken;
  final String? initialDestination;

  @override
  ConsumerState<SetupPasswordScreen> createState() =>
      _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends ConsumerState<SetupPasswordScreen> {
  // Password creation controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Recovery / verification controllers
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpCodeController = TextEditingController();

  String? _activeSetupToken;
  String? _activeDestination;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _confirmError;

  // Recovery OTP state
  String _selectedChannel = 'Email'; // 'Email' or 'WhatsApp'
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  String? _recoveryMessage;
  String? _recoveryError;
  int? _activeChallengeId;
  String? _activeFlowId;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _activeSetupToken = widget.initialCredentialSetupToken;
    _activeDestination = widget.initialDestination;

    if (_activeDestination != null) {
      _identifierController.text = _activeDestination!;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identifierController.dispose();
    _otpCodeController.dispose();
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

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpper => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _isPasswordValid =>
      _hasMinLength && _hasUpper && _hasLower && _hasNumber && _hasSpecial;

  Future<void> _handleRequestOtp() async {
    final String identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _recoveryError = 'Please enter your registered email or phone number.';
      });
      return;
    }

    setState(() {
      _isRequestingOtp = true;
      _recoveryError = null;
      _recoveryMessage = null;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      final RequestSetupOtpResult result = await authService.requestSetupOtp(
        identifier: identifier,
        channel: _selectedChannel,
      );

      setState(() {
        _isRequestingOtp = false;
        _activeChallengeId = result.challengeId;
        _activeFlowId = result.flowId;
        _activeDestination = result.destination;
        _recoveryMessage =
            'Verification code dispatched to ${result.maskedDestination}. Valid for 10 minutes.';
      });

      _startCooldown(60);
    } on AuthException catch (e) {
      setState(() {
        _isRequestingOtp = false;
        _recoveryError = e.message;
      });
    } catch (_) {
      setState(() {
        _isRequestingOtp = false;
        _recoveryError =
            'Unable to dispatch verification code. Please check your network and try again.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final String code = _otpCodeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _recoveryError = 'Please enter the complete 6-digit verification code.';
      });
      return;
    }

    if (_activeChallengeId == null || _activeFlowId == null) {
      setState(() {
        _recoveryError =
            'Verification session expired. Please request a new code.';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _recoveryError = null;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      final VerifySetupOtpResult result = await authService.verifySetupOtp(
        challengeId: _activeChallengeId!,
        flowId: _activeFlowId!,
        otpCode: code,
        channel: _selectedChannel,
      );

      // Save token in memory provider and update local state to transition to password creation form
      ref.read(pendingSetupTokenProvider.notifier).state = SetupTokenData(
        token: result.credentialSetupToken,
        destination: result.destination,
        expiresAt: result.expiresAtUtc,
      );

      setState(() {
        _isVerifyingOtp = false;
        _activeSetupToken = result.credentialSetupToken;
        _activeDestination = result.destination;
        _recoveryMessage = null;
        _recoveryError = null;
      });
    } on AuthException catch (e) {
      setState(() {
        _isVerifyingOtp = false;
        _recoveryError = e.message;
      });
    } catch (_) {
      setState(() {
        _isVerifyingOtp = false;
        _recoveryError =
            'Code verification failed. Please check your code and try again.';
      });
    }
  }

  void _validateAndSubmit() async {
    final String password = _passwordController.text;
    final String confirm = _confirmPasswordController.text;
    final String? token = _activeSetupToken?.trim();

    setState(() {
      _passwordError = !_isPasswordValid
          ? 'Password does not satisfy security policy'
          : null;
      _confirmError = password != confirm ? 'Passwords do not match' : null;
    });

    if (!_isPasswordValid || password != confirm) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _recoveryError =
            'Setup authorization has expired. Please verify your contact to request a new token.';
        _activeSetupToken = null;
      });
      return;
    }

    final bool success = await ref
        .read(authProvider.notifier)
        .setupPassword(
          credentialSetupToken: token,
          password: password,
          confirmPassword: confirm,
        );

    if (success && mounted) {
      // Clear pending token since it was consumed
      ref.read(pendingSetupTokenProvider.notifier).state = null;
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final SetupTokenData? pendingTokenData = ref.watch(
      pendingSetupTokenProvider,
    );

    // Resolve active token from parameter, local state, or pending provider
    final String? currentToken =
        _activeSetupToken ??
        widget.initialCredentialSetupToken ??
        pendingTokenData?.token;

    final bool hasValidToken = currentToken != null && currentToken.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          hasValidToken ? 'Set Up Password' : 'Verify Account Authorization',
        ),
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
                      color: hasValidToken
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color: hasValidToken
                            ? AppColors.secondaryContainer
                            : AppColors.primaryContainer,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        hasValidToken
                            ? Icons.vpn_key_rounded
                            : Icons.verified_user_rounded,
                        size: 38,
                        color: hasValidToken
                            ? AppColors.secondaryDark
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title & Subtitle
                Text(
                  hasValidToken
                      ? 'Create Your Password'
                      : 'Verify Your Registered Account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasValidToken
                      ? (_activeDestination != null &&
                                _activeDestination!.isNotEmpty
                            ? 'Authorized account: $_activeDestination. Create a strong password to complete setup.'
                            : 'Secure your Connexa member account with a strong password.')
                      : 'To set up your password, verify your registered email address or mobile number. We\'ll send you a single-use verification code.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Error Banners
                if (authState.errorMessage != null &&
                    hasValidToken) ...<Widget>[
                  _buildErrorBanner(
                    authState.errorMessage!,
                    onRetryOtp: () {
                      ref.read(authProvider.notifier).clearError();
                      setState(() => _activeSetupToken = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (_recoveryError != null && !hasValidToken) ...<Widget>[
                  _buildErrorBanner(_recoveryError!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (_recoveryMessage != null && !hasValidToken) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.mark_email_read_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _recoveryMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Card: Form Choice
                AppStaggeredEntrance(
                  index: 0,
                  child: hasValidToken
                      ? _buildPasswordForm(authState)
                      : _buildAccountVerificationForm(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Back / Alternative Actions
                AppStaggeredEntrance(
                  index: 1,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextButton.icon(
                          key: const Key('returnToReviewButton'),
                          icon: const Icon(Icons.assignment_outlined, size: 16),
                          label: const Text('Review Registration'),
                          onPressed: () => context.go('/registration/review'),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        TextButton.icon(
                          key: const Key('backToSignInButton'),
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Back to Sign In'),
                          onPressed: () => context.go('/login'),
                        ),
                      ],
                    ),
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

  Widget _buildPasswordForm(AuthState authState) {
    return AppCard(
      key: const Key('setupPasswordCard'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // New Password Field
          AppTextField(
            key: const Key('setupPasswordField'),
            controller: _passwordController,
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            errorText: _passwordError,
            enabled: !authState.isLoading,
            onChanged: (_) {
              setState(() {});
              ref.read(authProvider.notifier).clearError();
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Confirm Password Field
          AppTextField(
            key: const Key('setupConfirmPasswordField'),
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
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
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            errorText: _confirmError,
            enabled: !authState.isLoading,
            onSubmitted: (_) => _validateAndSubmit(),
            onChanged: (_) {
              setState(() {});
              ref.read(authProvider.notifier).clearError();
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Password Policy Checklist
          _buildPolicyIndicators(),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          AppButton.primary(
            key: const Key('setupPasswordSubmitButton'),
            text: 'Save Password & Enter App',
            isFullWidth: true,
            isLoading: authState.isLoading,
            trailingIcon: const Icon(Icons.arrow_forward_rounded, size: 18),
            onPressed: authState.isLoading ? null : _validateAndSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountVerificationForm() {
    final bool hasDispatched = _activeChallengeId != null;

    return AppCard(
      key: const Key('setupRecoveryCard'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Account Credential Recovery',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If you already registered but do not have an active setup authorization or your session expired, verify your contact to receive a fresh setup token.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Identifier Field
          AppTextField(
            key: const Key('setupIdentifierField'),
            controller: _identifierController,
            label: 'Registered Email or Phone',
            hintText: 'e.g. name@company.com or +919876543210',
            prefixIcon: const Icon(Icons.contact_mail_outlined, size: 20),
            enabled: !_isRequestingOtp && !_isVerifyingOtp,
          ),
          const SizedBox(height: AppSpacing.md),

          // Channel selection
          Row(
            children: <Widget>[
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.email_outlined, size: 16),
                      SizedBox(width: AppSpacing.xs),
                      Text('Email OTP'),
                    ],
                  ),
                  selected: _selectedChannel == 'Email',
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedChannel = 'Email');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.chat_outlined, size: 16),
                      SizedBox(width: AppSpacing.xs),
                      Text('WhatsApp OTP'),
                    ],
                  ),
                  selected: _selectedChannel == 'WhatsApp',
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedChannel = 'WhatsApp');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Request OTP Button
          if (!hasDispatched)
            AppButton.primary(
              key: const Key('requestSetupOtpButton'),
              text: 'Send Verification Code',
              isFullWidth: true,
              isLoading: _isRequestingOtp,
              trailingIcon: const Icon(Icons.send_rounded, size: 18),
              onPressed: _isRequestingOtp ? null : _handleRequestOtp,
            ),

          if (hasDispatched) ...<Widget>[
            const Divider(height: AppSpacing.xl),

            // OTP Input
            AppTextField(
              key: const Key('setupOtpCodeField'),
              controller: _otpCodeController,
              label: '6-Digit Verification Code',
              hintText: '• • • • • •',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.shield_outlined, size: 20),
              enabled: !_isVerifyingOtp,
              onSubmitted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton.primary(
              key: const Key('verifySetupOtpButton'),
              text: 'Verify & Continue to Password Setup',
              isFullWidth: true,
              isLoading: _isVerifyingOtp,
              trailingIcon: const Icon(Icons.check_rounded, size: 18),
              onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
            ),
            const SizedBox(height: AppSpacing.md),

            Center(
              child: TextButton(
                key: const Key('resendSetupOtpButton'),
                onPressed: _cooldownSeconds > 0 || _isRequestingOtp
                    ? null
                    : _handleRequestOtp,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Resend code in ${_cooldownSeconds}s'
                      : 'Resend Verification Code',
                  style: TextStyle(
                    color: _cooldownSeconds > 0
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
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
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSatisfied ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, {VoidCallback? onRetryOtp}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                  key: const Key('setupPasswordErrorMessage'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onRetryOtp != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('requestNewTokenButton'),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Verify Account to Request New Token'),
                onPressed: onRetryOtp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
