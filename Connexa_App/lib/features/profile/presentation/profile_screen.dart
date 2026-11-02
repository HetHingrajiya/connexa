import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';

/// Structured report summarizing profile completeness and recommended fields.
class ProfileCompletenessReport {
  const ProfileCompletenessReport({
    required this.percent,
    required this.missingRecommendedFields,
    required this.completedCount,
    required this.totalCount,
  });

  final int percent;
  final List<String> missingRecommendedFields;
  final int completedCount;
  final int totalCount;
}

/// Screen displaying the authenticated member's verified profile details.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authProvider);
    final MemberProfile? profile = authState.profile;

    if (authState.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: AppLoadingIndicator(message: 'Loading profile...')),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: AppErrorState(
            title: 'Unable to Load Profile',
            description:
                'Could not retrieve your verified profile information.',
            onRetry: () => ref.read(authProvider.notifier).refreshProfile(),
          ),
        ),
      );
    }

    final ProfileCompletenessReport completenessReport =
        _calculateCompletenessReport(profile);

    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: <Widget>[
          IconButton(
            key: const Key('profileEditIconButton'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            key: const Key('profileLogoutIconButton'),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => showLogoutConfirmationDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: RefreshIndicator(
            onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.md,
                0,
                AppSpacing.xxxl,
              ),
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
                              // Left Profile Identity & Actions Column
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    AppStaggeredEntrance(
                                      index: 0,
                                      child: _buildHeroCard(context, profile),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AppStaggeredEntrance(
                                      index: 1,
                                      child: _buildVerificationStatusCard(
                                        context,
                                        profile,
                                      ),
                                    ),
                                    if (profile.isAdmin) ...<Widget>[
                                      const SizedBox(height: AppSpacing.lg),
                                      AppStaggeredEntrance(
                                        index: 2,
                                        child: _buildAdminActionCard(context),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.lg),
                                    AppStaggeredEntrance(
                                      index: 3,
                                      child: _buildCompletionCard(
                                        context,
                                        completenessReport,
                                        profile,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AppStaggeredEntrance(
                                      index: 2,
                                      child: AppButton.primary(
                                        key: const Key('profileEditButton'),
                                        text: 'Edit Profile Details',
                                        leadingIcon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                        ),
                                        isFullWidth: true,
                                        onPressed: () =>
                                            context.push('/profile/edit'),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AppStaggeredEntrance(
                                      index: 3,
                                      child: AppButton.secondary(
                                        text: 'Back to Dashboard',
                                        leadingIcon: const Icon(
                                          Icons.dashboard_outlined,
                                          size: 18,
                                        ),
                                        isFullWidth: true,
                                        onPressed: () =>
                                            context.go('/dashboard'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              // Right Details & Classification Column
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    AppStaggeredEntrance(
                                      index: 1,
                                      child: _buildContactCard(profile),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AppStaggeredEntrance(
                                      index: 2,
                                      child: _buildDomainDetailsCard(profile),
                                    ),
                                    if (_hasIndustryHierarchy(
                                      profile,
                                    )) ...<Widget>[
                                      const SizedBox(height: AppSpacing.lg),
                                      AppStaggeredEntrance(
                                        index: 3,
                                        child: _buildHierarchyCard(profile),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.lg),
                                    AppStaggeredEntrance(
                                      index: 4,
                                      child: _buildSecurityCard(
                                        profile,
                                        authState.user,
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
                          AppStaggeredEntrance(
                            index: 0,
                            child: _buildHeroCard(context, profile),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 1,
                            child: _buildVerificationStatusCard(
                              context,
                              profile,
                            ),
                          ),
                          if (profile.isAdmin) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            AppStaggeredEntrance(
                              index: 2,
                              child: _buildAdminActionCard(context),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 3,
                            child: _buildCompletionCard(
                              context,
                              completenessReport,
                              profile,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 2,
                            child: _buildContactCard(profile),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 3,
                            child: _buildDomainDetailsCard(profile),
                          ),
                          if (_hasIndustryHierarchy(profile)) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            AppStaggeredEntrance(
                              index: 4,
                              child: _buildHierarchyCard(profile),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 5,
                            child: _buildSecurityCard(profile, authState.user),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 6,
                            child: AppButton.primary(
                              key: const Key('profileEditButton'),
                              text: 'Edit Profile Details',
                              leadingIcon: const Icon(
                                Icons.edit_rounded,
                                size: 18,
                              ),
                              isFullWidth: true,
                              onPressed: () => context.push('/profile/edit'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppStaggeredEntrance(
                            index: 7,
                            child: AppButton.secondary(
                              text: 'Back to Dashboard',
                              leadingIcon: const Icon(
                                Icons.dashboard_outlined,
                                size: 18,
                              ),
                              isFullWidth: true,
                              onPressed: () => context.go('/dashboard'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppStaggeredEntrance(
                            index: 8,
                            child: AppButton.secondary(
                              key: const Key('profileSignOutButton'),
                              text: 'Sign Out',
                              leadingIcon: const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              isFullWidth: true,
                              onPressed: () =>
                                  showLogoutConfirmationDialog(context, ref),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
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

  Widget _buildHeroCard(BuildContext context, MemberProfile profile) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
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
              radius: 34,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName.substring(0, 1).toUpperCase()
                    : 'M',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
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
                        profile.fullName,
                        key: const Key('profileFullNameText'),
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
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
                      size: 18,
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
                      key: const Key('profileMemberIdBadge'),
                      label: 'Member #${profile.memberId}',
                    ),
                    AppBadge.secondary(
                      label: _formatProfileType(profile.primaryProfileType),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 15,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Verified via ${profile.verifiedMethod}',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(
    BuildContext context,
    ProfileCompletenessReport report,
    MemberProfile profile,
  ) {
    final int percent = report.percent;
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
                        'Profile Completeness',
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                key: const Key('profileCompletionPercentText'),
                label: '$percent%',
                variant: percent == 100
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.primary,
                isPill: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${report.completedCount} of ${report.totalCount} attributes completed',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusFull,
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent == 100 ? AppColors.success : AppColors.secondary,
              ),
            ),
          ),
          if (report.missingRecommendedFields.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Recommended to add:',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  key: const Key('completeProfileLink'),
                  onTap: () => context.push('/profile/edit'),
                  child: Text(
                    'Edit Profile →',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: report.missingRecommendedFields.take(4).map((String field) {
                return ActionChip(
                  key: Key('missingFieldChip_$field'),
                  avatar: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    field,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => context.push('/profile/edit'),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Profile completeness is independent of official verification. To obtain the Verified badge, submit your business registration documents for admin review.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(MemberProfile profile) {
    return AppCard(
      title: 'Contact Information',
      subtitle: 'Verified credentials on record in Connexa database',
      child: Column(
        children: <Widget>[
          _buildRow(
            Icons.email_outlined,
            'Email Address',
            profile.email,
            key: 'profileEmailValue',
          ),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.phone_outlined,
            'Phone Number',
            '${profile.countryCode} ${profile.phoneNumber}',
            key: 'profilePhoneValue',
          ),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.verified_user_outlined,
            'Verification Method',
            '${profile.verifiedMethod} (${profile.verifiedDestination})',
          ),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.calendar_today_outlined,
            'Member Since',
            '${profile.createdAtUtc.day}/${profile.createdAtUtc.month}/${profile.createdAtUtc.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildDomainDetailsCard(MemberProfile profile) {
    final Map<String, dynamic>? details = profile.profileDetails;
    if (details == null || details.isEmpty) {
      return const AppCard(
        title: 'Business & Specialty Details',
        subtitle: 'Domain information retrieved from SQL Server',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'No specialized profile details available.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    final String companyOrWorkName =
        details['companyName']?.toString() ??
        details['tradingName']?.toString() ??
        details['workName']?.toString() ??
        details['jobTitle']?.toString() ??
        details['specialization']?.toString() ??
        '—';

    final dynamic rawCapabilities =
        details['businessCapabilities'] ??
        details['capabilities'] ??
        details['workCapabilities'];

    List<String> capabilities = <String>[];
    if (rawCapabilities is List) {
      capabilities = rawCapabilities.map((dynamic c) => c.toString()).toList();
    }

    final String? description =
        details['businessDescription']?.toString() ??
        details['experience']?.toString() ??
        details['processesSupported']?.toString() ??
        details['productsSupplied']?.toString();

    return AppCard(
      title: 'Business & Specialty Details',
      subtitle: 'Domain information retrieved from SQL Server',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildRow(
            Icons.business_rounded,
            'Company / Work Title',
            companyOrWorkName,
            key: 'profileCompanyNameValue',
          ),
          if (capabilities.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.lg),
            const Text(
              'Capabilities & Offerings',
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: capabilities.map((String cap) {
                return AppBadge.secondary(label: cap, isPill: true);
              }).toList(),
            ),
          ],
          if (description != null && description.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.lg),
            _buildRow(
              Icons.description_outlined,
              'Description & Operations',
              description,
            ),
          ],
          if (profile.address != null && profile.address!.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.lg),
            _buildRow(
              Icons.location_on_outlined,
              'Registered Address',
              '${profile.address}${profile.city != null && profile.city!.isNotEmpty ? ', ${profile.city}' : ''}${profile.state != null && profile.state!.isNotEmpty ? ', ${profile.state}' : ''}${profile.pincode != null && profile.pincode!.isNotEmpty ? ' - ${profile.pincode}' : ''}',
              key: 'profileAddressValue',
            ),
          ],
          if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.lg),
            _buildRow(
              Icons.language_rounded,
              'Website',
              profile.websiteUrl!,
              key: 'profileWebsiteValue',
            ),
          ],
        ],
      ),
    );
  }

  bool _hasIndustryHierarchy(MemberProfile profile) {
    final Map<String, dynamic>? details = profile.profileDetails;
    if (details == null) return false;
    return details.containsKey('industry') ||
        details.containsKey('businessGroup') ||
        details.containsKey('subGroup') ||
        details.containsKey('category');
  }

  Widget _buildHierarchyCard(MemberProfile profile) {
    final Map<String, dynamic>? details = profile.profileDetails;
    final String industry = details?['industry']?.toString() ?? '—';
    final String group = details?['businessGroup']?.toString() ?? '—';
    final String subGroup = details?['subGroup']?.toString() ?? '—';
    final String category = details?['category']?.toString() ?? '—';

    return AppCard(
      title: 'Industry Classification',
      subtitle: '4-Tier Industry Master Data Hierarchy',
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
              fontWeight: FontWeight.bold,
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

  Widget _buildRow(IconData icon, String label, String value, {String? key}) {
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
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(MemberProfile profile, AuthenticatedMember? user) {
    final String role = profile.role.isNotEmpty
        ? profile.role
        : (user?.role ?? 'Member');
    final String formattedDate =
        '${profile.createdAtUtc.day}/${profile.createdAtUtc.month}/${profile.createdAtUtc.year}';

    return AppCard(
      title: 'Session & Security',
      subtitle: 'JWT token rotation and account authorization level',
      child: Column(
        children: <Widget>[
          _buildRow(Icons.admin_panel_settings_outlined, 'Account Role', role),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.lock_clock_outlined,
            'Session Type',
            'Short-lived JWT (15 min) with Refresh Token Rotation',
          ),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.calendar_today_outlined,
            'Member Since',
            formattedDate,
          ),
          const Divider(height: AppSpacing.lg),
          _buildRow(
            Icons.security_rounded,
            'Authorization Status',
            'Active (Strict Member Role)',
          ),
        ],
      ),
    );
  }

  ProfileCompletenessReport _calculateCompletenessReport(MemberProfile profile) {
    final List<String> missing = <String>[];
    int total = 0;
    int completed = 0;

    void checkField(String fieldName, bool isFilled) {
      total++;
      if (isFilled) {
        completed++;
      } else {
        missing.add(fieldName);
      }
    }

    // Basic Account Details
    checkField('Full Name', profile.fullName.trim().isNotEmpty);
    checkField('Email Address', profile.email.trim().isNotEmpty);
    checkField('Phone Number', profile.phoneNumber.trim().isNotEmpty);

    // Business Identity & Description
    final Map<String, dynamic>? details = profile.profileDetails;
    final String? company = profile.companyName ??
        details?['tradingName']?.toString() ??
        details?['workName']?.toString() ??
        details?['jobTitle']?.toString();
    checkField('Company Name', company != null && company.trim().isNotEmpty);

    final String? desc = details?['businessDescription']?.toString();
    checkField('Business Description', desc != null && desc.trim().isNotEmpty);

    final dynamic capabilities = details?['businessCapabilities'];
    final bool hasCapabilities = (capabilities is List && capabilities.isNotEmpty) ||
        (capabilities is String && capabilities.trim().isNotEmpty);
    checkField('Capabilities', hasCapabilities);

    final bool hasIndustry = details?['industryId'] != null ||
        details?['industry'] != null ||
        details?['skills'] != null;
    checkField('Industry', hasIndustry);

    final String? address = profile.address;
    checkField('Address', address != null && address.trim().isNotEmpty);

    final String? city = profile.city;
    final String? state = profile.state;
    checkField(
      'City & State',
      city != null &&
          city.trim().isNotEmpty &&
          state != null &&
          state.trim().isNotEmpty,
    );

    final String? pincode = profile.pincode;
    checkField('Pincode', pincode != null && pincode.trim().isNotEmpty);

    final String? logo = profile.logoUrl;
    checkField('Company Logo', logo != null && logo.trim().isNotEmpty);

    final String? website = profile.websiteUrl;
    checkField('Website URL', website != null && website.trim().isNotEmpty);

    final int percent = total > 0 ? ((completed / total) * 100).round() : 100;

    return ProfileCompletenessReport(
      percent: percent,
      missingRecommendedFields: missing,
      completedCount: completed,
      totalCount: total,
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

  Widget _buildVerificationStatusCard(
    BuildContext context,
    MemberProfile profile,
  ) {
    final String statusStr = profile.verificationStatus;
    final bool isBusiness = profile.primaryProfileType == 'BusinessCompany';

    Widget statusBadge;
    String title;
    String description;
    Color accentColor;
    IconData iconData;

    switch (statusStr.toLowerCase()) {
      case 'approved':
      case 'verified':
        statusBadge = const AppBadge.success(
          label: 'Verified Business',
          icon: Icon(Icons.check_circle_rounded, size: 14),
        );
        title = 'Business Verified';
        description =
            'Your business credentials are officially verified. You enjoy priority search listing and verified trust badges.';
        accentColor = AppColors.success;
        iconData = Icons.verified_rounded;
        break;
      case 'pendingreview':
      case 'pending_review':
      case 'pending':
        statusBadge = const AppBadge.warning(
          label: 'Under Review',
          icon: Icon(Icons.access_time_rounded, size: 14),
        );
        title = 'Verification Pending Review';
        description =
            'Our compliance team is verifying your registration documents.';
        accentColor = AppColors.warning;
        iconData = Icons.pending_actions_rounded;
        break;
      case 'rejected':
        statusBadge = const AppBadge.error(
          label: 'Action Required',
          icon: Icon(Icons.error_outline_rounded, size: 14),
        );
        title = 'Verification Needs Attention';
        description =
            'Your verification was not approved. Please review remarks and update documents.';
        accentColor = AppColors.error;
        iconData = Icons.cancel_outlined;
        break;
      default:
        statusBadge = const AppBadge.neutral(
          label: 'Unverified',
          icon: Icon(Icons.shield_outlined, size: 14),
        );
        title = 'Official Business Verification';
        description =
            'Verify your registration to build trust with buyers and unlock verified badges across Connexa.';
        accentColor = AppColors.primary;
        iconData = Icons.verified_user_outlined;
        break;
    }

    return AppCard(
      borderColor: accentColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(iconData, color: accentColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              statusBadge,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (isBusiness) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                key: const Key('manageVerificationButton'),
                text: statusStr.toLowerCase() == 'approved'
                    ? 'View Verification Details'
                    : 'Manage Business Verification',
                leadingIcon: const Icon(Icons.verified_outlined, size: 16),
                onPressed: () => context.push('/profile/verification'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceContainer,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Administrator Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppBadge.brand(label: 'Admin Privileges'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review pending business verification applications and grant official badges.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            key: const Key('adminVerificationsNavButton'),
            text: 'Review Business Verifications',
            leadingIcon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
            onPressed: () => context.push('/admin/verifications'),
          ),
        ],
      ),
    );
  }
}
