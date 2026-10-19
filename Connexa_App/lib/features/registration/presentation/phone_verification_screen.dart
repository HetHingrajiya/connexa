import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/providers/verification_providers.dart';

/// Screen 4 of Registration: Secure WhatsApp OTP phone verification.
///
/// Dispatches a 6-digit verification code via WhatsApp Cloud API / Dev Provider,
/// provides 60-second cooldown timer, handles retry / resend limits, and
/// retains the server-issued cryptographic verification grant in the registration draft.
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _hasInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateVerificationIfNeeded();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _initiateVerificationIfNeeded() {
    if (_hasInitiated) return;
    _hasInitiated = true;

    final RegistrationDraft draft = ref.read(registrationDraftProvider);
    final String fullPhone =
        '${draft.countryCode.trim()}${draft.mobileNumber.trim()}';

    // If flowId is empty, generate a unique correlation session ID
    String flowId = draft.registrationFlowId;
    if (flowId.isEmpty) {
      flowId =
          'flow_${DateTime.now().millisecondsSinceEpoch}_${draft.mobileNumber.hashCode.abs()}';
      ref.read(registrationDraftProvider.notifier).state = draft.copyWith(
        registrationFlowId: flowId,
      );
    }

    if (fullPhone.isNotEmpty) {
      ref
          .read(phoneVerificationProvider.notifier)
          .sendOtp(phoneNumber: fullPhone, registrationFlowId: flowId);
    }
  }

  Future<void> _handleVerify() async {
    final String code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final bool success = await ref
        .read(phoneVerificationProvider.notifier)
        .verifyOtp(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    _otpController.clear();
    await ref.read(phoneVerificationProvider.notifier).resendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);
    final PhoneVerificationState state = ref.watch(phoneVerificationProvider);

    final String displayPhone =
        state.maskedPhoneNumber ??
        _formatMaskedPhone(draft.countryCode, draft.mobileNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        leading: IconButton(
          key: const Key('backButton'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/registration/review');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: AppSpacing.xl),

                // Main Verification Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Header Icon
                      _buildHeaderIcon(state),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      Text(
                        state.isVerified
                            ? 'Phone Number Verified'
                            : 'Verify Your Phone Number',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Subtitle / Destination Phone
                      Text(
                        state.isVerified
                            ? 'Your identity has been verified via WhatsApp.'
                            : (state.isLiveDelivery
                                  ? 'We sent a 6-digit verification code via WhatsApp to:'
                                  : 'Development Mode (Meta Cloud API not configured): Code saved to SQL Server for:'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        displayPhone,
                        textAlign: TextAlign.center,
                        key: const Key('maskedPhoneNumberDisplay'),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!state.isLiveDelivery &&
                          !state.isVerified) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Meta Cloud API credentials are not yet configured on the server. No message was sent to WhatsApp. Enter the 6-digit OTP code directly from SQL Server, or switch to live Email OTP.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.onWarningContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppButton.secondary(
                                key: const Key(
                                  'switchToEmailFromWarningButton',
                                ),
                                text: 'Switch to Email OTP (Live Gmail SMTP)',
                                leadingIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 16,
                                ),
                                onPressed: () => context.go(
                                  '/registration/email-verification',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),

                      // Body based on state
                      if (state.status ==
                          VerificationStatus.sendingOtp) ...<Widget>[
                        const AppLoadingIndicator(
                          message: 'Contacting WhatsApp dispatch service...',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ] else if (state.isVerified) ...<Widget>[
                        _buildVerifiedSuccessContent(draft, state),
                      ] else ...<Widget>[
                        // Error banner if any
                        if (state.errorMessage != null) ...<Widget>[
                          _buildErrorBanner(state.errorMessage!),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // OTP Input Field
                        _buildOtpInputField(state),
                        const SizedBox(height: AppSpacing.xl),

                        // Action Buttons: Verify & Resend
                        _buildActionButtons(state),
                        const SizedBox(height: AppSpacing.xl),

                        // Cooldown / Resend Information
                        _buildCooldownInfo(state),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      // Safety Notice Banner
                      _buildSecurityNotice(state.isVerified),
                    ],
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Step 4 of Registration — Secure WhatsApp Phone Verification',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(PhoneVerificationState state) {
    if (state.isVerified) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          size: 36,
          color: AppColors.success,
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble_rounded,
        size: 32,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildOtpInputField(PhoneVerificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'ENTER 6-DIGIT CODE',
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 280,
          child: TextField(
            key: const Key('otpInputField'),
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            enabled: !state.isSubmitting,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTextStyles.headlineMedium.copyWith(
              letterSpacing: 12.0,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: AppTextStyles.headlineMedium.copyWith(
                letterSpacing: 12.0,
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
            ),
            onChanged: (String value) {
              if (value.length == 6) {
                _handleVerify();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(PhoneVerificationState state) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: <Widget>[
        AppButton.primary(
          key: const Key('verifyOtpButton'),
          text: 'Verify Code',
          leadingIcon: const Icon(Icons.check_rounded, size: 18),
          isLoading:
              state.isSubmitting &&
              state.status == VerificationStatus.verifying,
          onPressed: state.isSubmitting ? null : _handleVerify,
        ),
        AppButton.secondary(
          key: const Key('resendOtpButton'),
          text: state.cooldownRemaining > 0
              ? 'Resend in ${state.cooldownRemaining}s'
              : 'Resend via WhatsApp',
          leadingIcon: const Icon(Icons.refresh_rounded, size: 18),
          isLoading:
              state.isSubmitting &&
              state.status != VerificationStatus.verifying,
          onPressed: state.canResend ? _handleResend : null,
        ),
        AppButton.text(
          key: const Key('switchToEmailActionButton'),
          text: 'Use Email Verification Instead',
          leadingIcon: const Icon(Icons.mail_outline_rounded, size: 16),
          onPressed: () => context.go('/registration/email-verification'),
        ),
      ],
    );
  }

  Widget _buildCooldownInfo(PhoneVerificationState state) {
    if (state.cooldownRemaining > 0) {
      return Text(
        'Didn’t receive the code? You can resend in ${state.cooldownRemaining} seconds.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    return Text(
      'Didn’t receive the code? Tap "Resend via WhatsApp" above to request a new code.',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildErrorBanner(String errorMessage) {
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
              errorMessage,
              key: const Key('verificationErrorMessage'),
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

  Widget _buildVerifiedSuccessContent(
    RegistrationDraft draft,
    PhoneVerificationState state,
  ) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.successContainer.withValues(alpha: 0.5),
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.success),
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'VERIFIED VIA WHATSAPP',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.onSuccessContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Destination ${state.maskedPhoneNumber ?? draft.mobileNumber} was successfully verified by Microsoft SQL Server challenge.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSuccessContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A single-use verification grant has been issued and stored securely for registration finalization.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: <Widget>[
            AppButton.primary(
              key: const Key('proceedToReviewFromPhoneVerifiedButton'),
              text: 'Proceed to Final Review',
              leadingIcon: const Icon(Icons.arrow_forward_rounded, size: 18),
              onPressed: () => context.go('/registration/review'),
            ),
            AppButton.secondary(
              key: const Key('returnToReviewFromVerifiedButton'),
              text: 'Return to Review',
              leadingIcon: const Icon(Icons.arrow_back_rounded, size: 18),
              onPressed: () => context.go('/registration/review'),
            ),
            AppButton.text(
              key: const Key('onboardingReturnButton'),
              text: 'Onboarding Overview',
              onPressed: () => context.go('/onboarding'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityNotice(bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isVerified
                  ? 'Verification Complete: Your phone number is verified. Account creation and profile persistence will take place in the upcoming registration finalization step.'
                  : 'Security Notice: Plaintext verification codes are never stored on disk or in logs. All challenges are protected by cryptographic salting, HMAC-SHA256, and strict attempt limits.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMaskedPhone(String countryCode, String mobileNumber) {
    if (mobileNumber.isEmpty) return 'No number provided';
    final String clean = mobileNumber.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 4) return '$countryCode $clean';
    final String suffix = clean.substring(clean.length - 3);
    return '$countryCode ••••• ••$suffix';
  }
}
