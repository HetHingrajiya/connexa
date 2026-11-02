import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/auth/providers/security_providers.dart';

/// Screen allowing members to manage password, sessions, and account lifecycle (deactivation/deletion).
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  void _showDeactivateDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    bool obscurePassword = true;
    String? localError;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setModalState) {
            final AccountSettingsState state = ref.watch(accountSettingsProvider);

            return AlertDialog(
              title: const Row(
                children: <Widget>[
                  Icon(Icons.pause_circle_outline_rounded,
                      color: AppColors.warning, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text('Deactivate Account'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Deactivating your account will temporarily disable your public directory listing, RFQs, and job work postings.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'You can easily reactivate your account anytime by logging in again.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (localError != null) ...<Widget>[
                      Text(
                        localError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppTextField(
                      controller: passwordController,
                      label: 'Account Password',
                      hintText: 'Enter your password to confirm',
                      obscureText: obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setModalState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: reasonController,
                      label: 'Reason for deactivating (Optional)',
                      hintText: 'Tell us why you are taking a break',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                AppButton.primary(
                  text: 'Confirm Deactivation',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final String password = passwordController.text;
                          if (password.isEmpty) {
                            setModalState(() {
                              localError = 'Please enter your password';
                            });
                            return;
                          }
                          setModalState(() => localError = null);

                          final bool success = await ref
                              .read(accountSettingsProvider.notifier)
                              .deactivateAccount(
                                password: password,
                                reason: reasonController.text.trim(),
                              );

                          if (success) {
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            await ref.read(authProvider.notifier).logout();
                            if (mounted) {
                              context.go('/onboarding');
                            }
                          } else if (mounted) {
                            setModalState(() {
                              localError = ref
                                      .read(accountSettingsProvider)
                                      .errorMessage ??
                                  'Deactivation failed';
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteRequestDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    bool obscurePassword = true;
    bool acknowledge = false;
    String? localError;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setModalState) {
            final AccountSettingsState state = ref.watch(accountSettingsProvider);

            return AlertDialog(
              title: const Row(
                children: <Widget>[
                  Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text('Delete Account Request'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Submitting an account deletion request will queue your account for permanent erasure. An administrator will review and process your request within 30 days.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (localError != null) ...<Widget>[
                      Text(
                        localError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppTextField(
                      controller: passwordController,
                      label: 'Account Password',
                      hintText: 'Enter your password',
                      obscureText: obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setModalState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: reasonController,
                      label: 'Reason for deletion (Required)',
                      hintText: 'Please state the reason for permanent deletion',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: acknowledge,
                      title: Text(
                        'I understand that data deletion is irreversible once approved.',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (bool? val) =>
                          setModalState(() => acknowledge = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                AppButton.primary(
                  text: 'Submit Request',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final String password = passwordController.text;
                          final String reason = reasonController.text.trim();

                          if (password.isEmpty) {
                            setModalState(() {
                              localError = 'Password is required';
                            });
                            return;
                          }

                          if (reason.isEmpty) {
                            setModalState(() {
                              localError = 'Please state a reason for deletion';
                            });
                            return;
                          }

                          if (!acknowledge) {
                            setModalState(() {
                              localError = 'Please acknowledge the disclaimer';
                            });
                            return;
                          }

                          setModalState(() => localError = null);

                          final bool success = await ref
                              .read(accountSettingsProvider.notifier)
                              .requestAccountDeletion(
                                password: password,
                                reason: reason,
                              );

                          if (success) {
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Deletion request submitted successfully for admin review.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } else if (mounted) {
                            setModalState(() {
                              localError = ref
                                      .read(accountSettingsProvider)
                                      .errorMessage ??
                                  'Failed to submit deletion request';
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AccountSettingsState state = ref.watch(accountSettingsProvider);
    final AccountStatus? status = state.status;
    final bool hasPendingDeletion = status?.hasPendingDeletionRequest ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Security & Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: 600,
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(accountSettingsProvider.notifier)
                .loadAccountStatus(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Pending Deletion Warning Banner
                  if (hasPendingDeletion) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.pending_actions_rounded,
                            color: AppColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Account Deletion Request Pending',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onWarningContainer,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'You submitted an account deletion request. An administrator is currently reviewing it. Your data is queued for permanent erasure.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onWarningContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Security & Credentials Card
                  AppCard(
                    title: 'Credentials & Access',
                    subtitle: 'Manage your password and authorized login sessions',
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: const Icon(Icons.key_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          title: const Text('Change Password'),
                          subtitle: const Text('Update your login password'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/change-password'),
                        ),
                        const Divider(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: const Icon(Icons.devices_rounded,
                                color: AppColors.secondaryDark, size: 20),
                          ),
                          title: const Text('Active Sessions & Devices'),
                          subtitle: const Text('View and revoke active sessions'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/active-sessions'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Danger Zone Card
                  AppCard(
                    title: 'Account Lifecycle & Danger Zone',
                    subtitle: 'Temporarily deactivate or permanently request deletion',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: const Icon(Icons.pause_circle_outline_rounded,
                                color: AppColors.warning, size: 20),
                          ),
                          title: const Text('Deactivate Account'),
                          subtitle: const Text(
                            'Temporarily hide your profile and business activities',
                          ),
                          trailing: OutlinedButton(
                            onPressed: _showDeactivateDialog,
                            child: const Text('Deactivate'),
                          ),
                        ),
                        const Divider(height: AppSpacing.lg),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: const Icon(Icons.delete_forever_rounded,
                                color: AppColors.error, size: 20),
                          ),
                          title: const Text('Request Account Deletion'),
                          subtitle: const Text(
                            'Submit request for permanent data erasure',
                          ),
                          trailing: hasPendingDeletion
                              ? const AppBadge(
                                  label: 'Pending',
                                  variant: AppBadgeVariant.warning,
                                  isPill: true,
                                )
                              : OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  onPressed: _showDeleteRequestDialog,
                                  child: const Text('Delete'),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
