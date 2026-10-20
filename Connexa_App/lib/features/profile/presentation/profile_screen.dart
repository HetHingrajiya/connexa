import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';

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

    final double completionFraction = _calculateCompletion(profile);
    final int completionPercent = (completionFraction * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: <Widget>[
          IconButton(
            key: const Key('profileEditIconButton'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: RefreshIndicator(
            onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
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
                                      child: _buildCompletionCard(
                                        completionPercent,
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
                            child: _buildHeroCard(context, profile),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppStaggeredEntrance(
                            index: 1,
                            child: _buildCompletionCard(completionPercent),
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
                            index: 6,
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

  Widget _buildCompletionCard(int percent) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
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
                  const Text(
                    'Profile Completion',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
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
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            percent == 100
                ? 'Your profile is fully completed and verified.'
                : 'Complete all business and category attributes for maximum visibility across the network.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
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
