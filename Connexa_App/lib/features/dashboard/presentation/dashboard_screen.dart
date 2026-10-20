import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';

/// Responsive, authentic Member Dashboard screen for Connexa.
/// Displays real profile information and verified business data retrieved from SQL Server.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to end your active session? Your session tokens will be securely revoked.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton.primary(
              text: 'Log Out',
              height: 38,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authProvider);
    final MemberProfile? profile = authState.profile;
    final AuthenticatedMember? user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text('Connexa Dashboard', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('dashboardDirectoryNavButton'),
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Business Directory',
            onPressed: () => context.push('/directory'),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'My Network',
            onPressed: () => context.push('/network'),
          ),
          IconButton(
            key: const Key('dashboardProfileNavButton'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () => context.push('/profile'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: IconButton(
              key: const Key('dashboardLogoutButton'),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              tooltip: 'Sign Out',
              onPressed: () => _handleLogout(context, ref),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: authState.isLoading && profile == null
            ? const Center(
                child: AppLoadingIndicator(
                  message: 'Loading member profile...',
                ),
              )
            : authState.errorMessage != null && profile == null
            ? Center(
                child: AppErrorState(
                  title: 'Unable to Load Dashboard',
                  description: authState.errorMessage!,
                  onRetry: () =>
                      ref.read(authProvider.notifier).restoreSession(),
                ),
              )
            : ResponsiveCenterBox(
                padding: AppSpacing.screenPaddingMobile,
                maxTabletWidth: AppSpacing.maxContentWidthTablet,
                maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(authProvider.notifier).restoreSession();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ResponsiveBuilder(
                      builder:
                          (
                            BuildContext context,
                            DeviceType deviceType,
                            BoxConstraints constraints,
                          ) {
                            if (deviceType == DeviceType.desktop) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // Left Main Workspace Column
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          AppStaggeredEntrance(
                                            index: 0,
                                            child: _buildMemberHeroCard(
                                              context,
                                              profile,
                                              user,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          AppStaggeredEntrance(
                                            index: 1,
                                            child: _buildQuickActionsCard(
                                              context,
                                              ref,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          AppStaggeredEntrance(
                                            index: 2,
                                            child: _buildProfileDetailsCard(
                                              profile,
                                              user,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    // Right Auxiliary Cockpit Column
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          AppStaggeredEntrance(
                                            index: 1,
                                            child: _buildProfileCompletionCard(
                                              profile,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          if (_hasIndustryHierarchy(
                                            profile,
                                          )) ...<Widget>[
                                            AppStaggeredEntrance(
                                              index: 2,
                                              child: _buildHierarchySummaryCard(
                                                profile!,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                          ],
                                          AppStaggeredEntrance(
                                            index: 3,
                                            child: _buildSecurityCard(
                                              profile,
                                              user,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Mobile and Tablet single column
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const SizedBox(height: AppSpacing.sm),
                                AppStaggeredEntrance(
                                  index: 0,
                                  child: _buildMemberHeroCard(
                                    context,
                                    profile,
                                    user,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppStaggeredEntrance(
                                  index: 1,
                                  child: _buildProfileCompletionCard(profile),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppStaggeredEntrance(
                                  index: 2,
                                  child: _buildQuickActionsCard(context, ref),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (_hasIndustryHierarchy(profile)) ...<Widget>[
                                  AppStaggeredEntrance(
                                    index: 3,
                                    child: _buildHierarchySummaryCard(profile!),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                AppStaggeredEntrance(
                                  index: 4,
                                  child: _buildProfileDetailsCard(
                                    profile,
                                    user,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppStaggeredEntrance(
                                  index: 5,
                                  child: _buildSecurityCard(profile, user),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                              ],
                            );
                          },
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMemberHeroCard(
    BuildContext context,
    MemberProfile? profile,
    AuthenticatedMember? user,
  ) {
    final String fullName =
        profile?.fullName ?? user?.fullName ?? 'Connexa Member';
    final int memberId = profile?.memberId ?? user?.memberId ?? 0;
    final String profileType =
        profile?.primaryProfileType ?? user?.primaryProfileType ?? 'Member';
    final String verifiedMethod = profile?.verifiedMethod ?? 'Verified';
    final String verifiedDestination = profile?.verifiedDestination ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Prominent Member Avatar with Subtle Double Border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    fullName.isNotEmpty
                        ? fullName.substring(0, 1).toUpperCase()
                        : 'M',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Member Identity & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            fullName,
                            key: const Key('dashboardMemberName'),
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        AppBadge.primary(
                          label: 'Member #$memberId',
                          key: const Key('dashboardMemberId'),
                        ),
                        AppBadge.secondary(
                          label: _formatProfileType(profileType),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (verifiedMethod.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    verifiedDestination.isNotEmpty
                        ? 'Authenticated via $verifiedMethod ($verifiedDestination)'
                        : 'Authenticated via $verifiedMethod',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard(MemberProfile? profile) {
    if (profile == null) return const SizedBox.shrink();

    final double fraction = _calculateCompletion(profile);
    final int percent = (fraction * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Icon(
                      percent == 100
                          ? Icons.task_alt_rounded
                          : Icons.pending_actions_rounded,
                      color: percent == 100
                          ? AppColors.success
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Flexible(
                      child: Text(
                        'Profile Completion',
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                label: '$percent%',
                key: const Key('dashboardCompletionPercent'),
                variant: percent == 100
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.primary,
                isPill: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusFull,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent == 100 ? AppColors.success : AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            percent == 100
                ? 'Your profile is fully completed based on real registered fields.'
                : 'Tip: Complete missing details to maximize discovery across the Connexa B2B directory.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return AppCard(
      title: 'Quick Actions',
      subtitle: 'Manage your verified business network and account profile',
      child: ResponsiveBuilder(
        builder:
            (
              BuildContext ctx,
              DeviceType deviceType,
              BoxConstraints constraints,
            ) {
              final int crossAxisCount = switch (deviceType) {
                DeviceType.mobile => 2,
                DeviceType.tablet => 3,
                DeviceType.desktop => 2,
              };

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.4,
                children: <Widget>[
                  _buildActionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    key: 'dashboardQuickActionMyProfile',
                    onTap: () => context.push('/profile'),
                  ),
                  _buildActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit Profile',
                    key: 'dashboardQuickActionEditProfile',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _buildActionTile(
                    icon: Icons.storefront_rounded,
                    label: 'Directory',
                    key: 'dashboardQuickActionDirectory',
                    onTap: () => context.push('/directory'),
                  ),
                  _buildActionTile(
                    icon: Icons.hub_rounded,
                    label: 'My Network',
                    key: 'dashboardQuickActionNetwork',
                    onTap: () => context.push('/network'),
                  ),
                  _buildActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.error,
                    key: 'dashboardQuickActionLogout',
                    onTap: () => _handleLogout(context, ref),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? key,
    Color? color,
  }) {
    final Color effectiveColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key != null ? Key(key) : null,
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: effectiveColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveColor == AppColors.error
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasIndustryHierarchy(MemberProfile? profile) {
    if (profile == null) return false;
    final Map<String, dynamic>? details = profile.profileDetails;
    if (details == null) return false;
    return details.containsKey('industry') || details.containsKey('category');
  }

  Widget _buildHierarchySummaryCard(MemberProfile profile) {
    final Map<String, dynamic>? details = profile.profileDetails;
    final String industry = details?['industry']?.toString() ?? '—';
    final String group = details?['businessGroup']?.toString() ?? '—';
    final String subGroup = details?['subGroup']?.toString() ?? '—';
    final String category = details?['category']?.toString() ?? '—';

    return AppCard(
      title: 'Industry Classification',
      subtitle: '4-Tier Master Data categorization on record',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHierarchyStep(1, 'Industry', industry),
          _buildConnectingLine(),
          _buildHierarchyStep(2, 'Business Group', group),
          _buildConnectingLine(),
          _buildHierarchyStep(3, 'SubGroup', subGroup),
          _buildConnectingLine(),
          _buildHierarchyStep(4, 'Category', category, isLast: true),
        ],
      ),
    );
  }

  Widget _buildConnectingLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Container(width: 2, height: 14, color: AppColors.border),
    );
  }

  Widget _buildHierarchyStep(
    int level,
    String label,
    String name, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLast ? AppColors.secondary : AppColors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: isLast
                  ? AppColors.secondaryDark
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            '$level',
            style: AppTextStyles.labelSmall.copyWith(
              color: isLast ? AppColors.onSecondary : AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isLast
                      ? AppColors.secondaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailsCard(
    MemberProfile? profile,
    AuthenticatedMember? user,
  ) {
    final String email = profile?.email ?? user?.email ?? '—';
    final String phone = profile != null
        ? '${profile.countryCode} ${profile.phoneNumber}'
        : (user?.phoneNumber ?? '—');
    final String verifiedMethod = profile?.verifiedMethod ?? 'Verified';
    final String verifiedDestination = profile?.verifiedDestination ?? '';

    return AppCard(
      title: 'Profile Information',
      subtitle: 'Authenticated member credentials and profile attributes',
      child: Column(
        children: <Widget>[
          _buildInfoRow(
            Icons.email_outlined,
            'Email Address',
            email,
            key: 'dashboardEmailRow',
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            phone,
            key: 'dashboardPhoneRow',
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            Icons.check_circle_outline_rounded,
            'Verification Channel',
            verifiedDestination.isNotEmpty
                ? '$verifiedMethod ($verifiedDestination)'
                : verifiedMethod,
          ),
          if (profile?.profileDetails != null &&
              profile!.profileDetails!.isNotEmpty) ...<Widget>[
            ...profile.profileDetails!.entries.map((
              MapEntry<String, dynamic> e,
            ) {
              if (e.key.toLowerCase().endsWith('id')) {
                return const SizedBox.shrink();
              }
              return Column(
                children: <Widget>[
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow(
                    Icons.business_outlined,
                    _formatKey(e.key),
                    e.value?.toString() ?? '—',
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityCard(MemberProfile? profile, AuthenticatedMember? user) {
    final String role = profile?.role ?? user?.role ?? 'Member';
    final String formattedDate = profile != null
        ? '${profile.createdAtUtc.day}/${profile.createdAtUtc.month}/${profile.createdAtUtc.year}'
        : 'Active';

    return AppCard(
      title: 'Session & Security',
      subtitle: 'JWT token rotation and account authorization level',
      child: Column(
        children: <Widget>[
          _buildInfoRow(
            Icons.admin_panel_settings_outlined,
            'Account Role',
            role,
            highlightColor: AppColors.secondaryDark,
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            Icons.lock_clock_outlined,
            'Session Type',
            'Short-lived JWT (15 min) with Refresh Token Rotation',
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Member Since',
            formattedDate,
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            Icons.security_rounded,
            'Authorization Status',
            'Active (Strict Member Role)',
            highlightColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? highlightColor,
    String? key,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                key: key != null ? Key(key) : null,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlightColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateCompletion(MemberProfile profile) {
    int total = 5;
    int filled = 0;

    if (profile.fullName.trim().isNotEmpty) filled++;
    if (profile.email.trim().isNotEmpty) filled++;
    if (profile.phoneNumber.trim().isNotEmpty) filled++;
    if (profile.verifiedMethod.trim().isNotEmpty) filled++;
    if (profile.primaryProfileType.trim().isNotEmpty) filled++;

    final Map<String, dynamic>? details = profile.profileDetails;
    if (details != null && details.isNotEmpty) {
      total += 4;
      if ((details['companyName'] ??
              details['tradingName'] ??
              details['workName'] ??
              details['jobTitle']) !=
          null) {
        filled++;
      }
      if (details['industry'] != null ||
          details['skills'] != null ||
          details['specialization'] != null) {
        filled++;
      }
      if (details['businessGroup'] != null || details['experience'] != null) {
        filled++;
      }
      if (details['category'] != null ||
          details['serviceCoverage'] != null ||
          details['preferredJobType'] != null) {
        filled++;
      }
    }

    return filled / total;
  }

  String _formatKey(String key) {
    final RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return key
        .replaceAllMapped(exp, (Match m) => ' ${m.group(0)}')
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (Match m) => m.group(0)!.toUpperCase(),
        );
  }

  String _formatProfileType(String raw) {
    return switch (raw) {
      'BusinessCompany' => 'Company',
      'ContractorJobWorker' => 'Contractor',
      'EmployeeJobSeeker' => 'Professional',
      'ServiceEngineer' => 'Engineer',
      'TraderSupplier' => 'Supplier',
      _ => raw,
    };
  }
}
