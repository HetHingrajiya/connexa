import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/providers/security_providers.dart';

/// Screen displaying all active sessions with ability to revoke individual or all other devices.
class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  IconData _getDeviceIcon(String deviceName) {
    final String lower = deviceName.toLowerCase();
    if (lower.contains('android') || lower.contains('iphone') || lower.contains('mobile')) {
      return Icons.phone_android_rounded;
    }
    if (lower.contains('mac') || lower.contains('windows') || lower.contains('linux') || lower.contains('pc')) {
      return Icons.laptop_mac_rounded;
    }
    return Icons.devices_other_rounded;
  }

  void _confirmRevokeSession(
    BuildContext context,
    WidgetRef ref,
    ActiveSession session,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Revoke Session'),
        content: Text(
          'Are you sure you want to sign out "${session.deviceName}"? This device will require signing in again.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'Sign Out Device',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(activeSessionsProvider.notifier)
                  .revokeSession(session.id);
            },
          ),
        ],
      ),
    );
  }

  void _confirmRevokeAllOthers(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Sign Out All Other Devices'),
        content: const Text(
          'This will revoke active sessions on all other devices except your current session. Do you wish to continue?',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'Sign Out Others',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(activeSessionsProvider.notifier)
                  .revokeAllOtherSessions();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActiveSessionsState state = ref.watch(activeSessionsProvider);
    final List<ActiveSession> sessions = state.sessions;
    final int otherSessionsCount =
        sessions.where((ActiveSession s) => !s.isCurrent).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Sessions & Devices'),
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
          maxDesktopWidth: 600,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(activeSessionsProvider.notifier).loadSessions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Header Explanation
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.security_update_good_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Authorized Devices',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Manage devices where your account is currently signed in. If you suspect unauthorized access, sign out other devices immediately.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Success / Error Banners
                  if (state.successMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              state.successMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSuccessContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (state.errorMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
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
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Revoke Others Button
                  if (otherSessionsCount > 0) ...<Widget>[
                    AppButton.primary(
                      key: const Key('revokeAllOtherSessionsButton'),
                      text: 'Sign Out All Other Devices ($otherSessionsCount)',
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      leadingIcon: const Icon(Icons.logout_rounded, size: 18),
                      isLoading: state.isRevoking,
                      onPressed: state.isRevoking
                          ? null
                          : () => _confirmRevokeAllOthers(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Sessions List
                  if (state.isLoading && sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: AppLoadingIndicator(
                          message: 'Loading active sessions...',
                        ),
                      ),
                    )
                  else if (sessions.isEmpty)
                    const AppEmptyState(
                      icon: Icons.devices_other_rounded,
                      title: 'No Active Sessions',
                      description: 'No active login sessions found for your account.',
                    )
                  else
                    ...sessions.map((ActiveSession session) {
                      final IconData icon = _getDeviceIcon(session.deviceName);
                      final String dateStr =
                          '${session.lastActiveAtUtc.day}/${session.lastActiveAtUtc.month}/${session.lastActiveAtUtc.year} ${session.lastActiveAtUtc.hour.toString().padLeft(2, '0')}:${session.lastActiveAtUtc.minute.toString().padLeft(2, '0')}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: session.isCurrent
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  size: 22,
                                  color: session.isCurrent
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            session.deviceName,
                                            style: AppTextStyles.labelLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (session.isCurrent)
                                          const AppBadge(
                                            label: 'This Device',
                                            variant: AppBadgeVariant.success,
                                            isPill: true,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    if (session.ipAddress != null &&
                                        session.ipAddress!.isNotEmpty)
                                      Text(
                                        'IP: ${session.ipAddress}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    Text(
                                      'Last active: $dateStr UTC',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!session.isCurrent)
                                IconButton(
                                  key: Key('revokeSessionButton_${session.id}'),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 22,
                                  ),
                                  tooltip: 'Revoke this session',
                                  onPressed: state.isRevoking
                                      ? null
                                      : () => _confirmRevokeSession(
                                          context, ref, session),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
