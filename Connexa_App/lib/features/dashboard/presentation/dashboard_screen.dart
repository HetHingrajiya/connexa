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
        title: const Row(
          children: <Widget>[
            Icon(Icons.hub_rounded, color: AppColors.secondary, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text('Connexa Dashboard'),
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
            key: const Key('dashboardProfileNavButton'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () => context.push('/profile'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.md),

                        // Member Hero Card
                        _buildMemberHeroCard(context, profile, user),
                        const SizedBox(height: AppSpacing.lg),

                        // Real Field Profile Completion Card
                        _buildProfileCompletionCard(profile),
                        const SizedBox(height: AppSpacing.lg),

                        // Quick Actions Grid (My Profile, Business Directory, Edit Profile, Logout)
                        _buildQuickActionsCard(context, ref),
                        const SizedBox(height: AppSpacing.lg),

                        // Industry Hierarchy Summary
                        if (_hasIndustryHierarchy(profile)) ...<Widget>[
                          _buildHierarchySummaryCard(profile!),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Profile Details Section
                        _buildProfileDetailsCard(profile, user),
                        const SizedBox(height: AppSpacing.lg),

                        // Security & Session Info Card
                        _buildSecurityCard(profile, user),
                        const SizedBox(height: AppSpacing.xl),

                        // Action Logout Button in page footer
                        AppButton.secondary(
                          key: const Key('dashboardFooterLogoutButton'),
                          text: 'Sign Out of Active Session',
                          leadingIcon: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                          ),
                          isFullWidth: true,
                          onPressed: () => _handleLogout(context, ref),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              fullName.isNotEmpty
                  ? fullName.substring(0, 1).toUpperCase()
                  : 'M',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
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
                          fontWeight: FontWeight.bold,
                        ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        'Member #$memberId',
                        key: const Key('dashboardMemberId'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        profileType.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (verifiedMethod.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          verifiedDestination.isNotEmpty
                              ? 'Verified via $verifiedMethod ($verifiedDestination)'
                              : 'Verified via $verifiedMethod',
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
          ),
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
            children: <Widget>[
              const Text(
                'Profile Completion',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                '$percent%',
                key: const Key('dashboardCompletionPercent'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: percent == 100 ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent == 100 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            percent == 100
                ? 'Your profile is fully completed based on real registered fields.'
                : 'Tip: Add missing details to increase visibility across the Connexa directory.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return AppCard(
      title: 'Quick Actions',
      subtitle: 'Manage your verified profile and discover directory partners',
      child: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < 450;
          return GridView.count(
            crossAxisCount: isNarrow ? 2 : 4,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isNarrow ? 1.4 : 1.2,
            children: <Widget>[
              _buildActionTile(
                icon: Icons.person_outline,
                label: 'My Profile',
                key: 'dashboardQuickActionMyProfile',
                onTap: () => context.push('/profile'),
              ),
              _buildActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                key: 'dashboardQuickActionEditProfile',
                onTap: () => context.push('/profile/edit'),
              ),
              _buildActionTile(
                icon: Icons.storefront_outlined,
                label: 'Directory',
                key: 'dashboardQuickActionDirectory',
                onTap: () => context.push('/directory'),
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
    return InkWell(
      key: key != null ? Key(key) : null,
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 28, color: color ?? AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      title: 'Industry Hierarchy Classification',
      subtitle: '4-Tier Master Data categorization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHierarchyStep(1, 'Industry', industry),
          const SizedBox(height: AppSpacing.sm),
          _buildHierarchyStep(2, 'Business Group', group),
          const SizedBox(height: AppSpacing.sm),
          _buildHierarchyStep(3, 'SubGroup', subGroup),
          const SizedBox(height: AppSpacing.sm),
          _buildHierarchyStep(4, 'Category', category, isLast: true),
        ],
      ),
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
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLast ? AppColors.secondary : AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$level',
            style: AppTextStyles.labelSmall.copyWith(
              color: isLast ? AppColors.onSecondary : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTextStyles.labelSmall),
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
            const Divider(height: AppSpacing.lg),
            ...profile.profileDetails!.entries.map((
              MapEntry<String, dynamic> e,
            ) {
              if (e.key.toLowerCase().endsWith('id')) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _buildInfoRow(
                  Icons.business_outlined,
                  _formatKey(e.key),
                  e.value?.toString() ?? '—',
                ),
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
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
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
}
