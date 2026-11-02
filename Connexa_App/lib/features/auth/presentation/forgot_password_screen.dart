import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/providers/security_providers.dart';

/// Screen allowing users to request a password reset OTP code.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  String _selectedChannel = 'Email';
  String? _identifierError;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _identifierError = 'Please enter your email or phone number';
      });
      return;
    }

    setState(() {
      _identifierError = null;
    });

    final ForgotPasswordResponse? response = await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetOtp(
          identifier: identifier,
          preferredChannel: _selectedChannel,
        );

    if (response != null && mounted) {
      context.push(
        '/reset-password',
        extra: <String, dynamic>{
          'identifier': identifier,
          'response': response,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordState state = ref.watch(forgotPasswordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
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

                // Lock Avatar Badge
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
                        Icons.lock_reset_rounded,
                        size: 38,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title & Description
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter your registered email address or mobile number. We will send a secure verification code to reset your password.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

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
                      AppTextField(
                        key: const Key('forgotPasswordIdentifierField'),
                        controller: _identifierController,
                        label: 'Email or Mobile Number',
                        hintText: 'e.g. name@company.com or 9876543210',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.contact_mail_outlined,
                          size: 20,
                        ),
                        errorText: _identifierError,
                        enabled: !state.isLoading,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_identifierError != null) {
                            setState(() => _identifierError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Channel Selection Chips
                      Text(
                        'Receive Verification Code Via',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ChoiceChip(
                              key: const Key('forgotPasswordEmailChip'),
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.email_outlined, size: 16),
                                  SizedBox(width: AppSpacing.xs),
                                  Text('Email'),
                                ],
                              ),
                              selected: _selectedChannel == 'Email',
                              onSelected: state.isLoading
                                  ? null
                                  : (bool selected) {
                                      if (selected) {
                                        setState(() => _selectedChannel = 'Email');
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ChoiceChip(
                              key: const Key('forgotPasswordWhatsAppChip'),
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 16),
                                  SizedBox(width: AppSpacing.xs),
                                  Text('WhatsApp'),
                                ],
                              ),
                              selected: _selectedChannel == 'WhatsApp',
                              onSelected: state.isLoading
                                  ? null
                                  : (bool selected) {
                                      if (selected) {
                                        setState(
                                            () => _selectedChannel = 'WhatsApp');
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit Button
                      AppButton.primary(
                        key: const Key('forgotPasswordSubmitButton'),
                        text: 'Send Verification Code',
                        isFullWidth: true,
                        isLoading: state.isLoading,
                        trailingIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        onPressed: state.isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Return to Sign In
                Center(
                  child: TextButton.icon(
                    key: const Key('forgotPasswordBackToLoginButton'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Sign In'),
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
}

