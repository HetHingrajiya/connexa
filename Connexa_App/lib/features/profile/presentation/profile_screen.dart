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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Hero Identity Card
                  _buildHeroCard(context, profile),
                  const SizedBox(height: AppSpacing.lg),

                  // Real-Field Profile Completion Card
                  _buildCompletionCard(completionPercent),
                  const SizedBox(height: AppSpacing.lg),

                  // Contact Details Card
                  _buildContactCard(profile),
                  const SizedBox(height: AppSpacing.lg),

                  // Domain Profile Details (Business / Trade / Worker)
                  _buildDomainDetailsCard(profile),
                  const SizedBox(height: AppSpacing.lg),

                  // 4-Tier Hierarchy Card (if applicable)
                  if (_hasIndustryHierarchy(profile)) ...<Widget>[
                    _buildHierarchyCard(profile),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Edit Profile Primary Action
                  AppButton.primary(
                    key: const Key('profileEditButton'),
                    text: 'Edit Profile Details',
                    leadingIcon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppButton.secondary(
                    text: 'Back to Dashboard',
                    leadingIcon: const Icon(Icons.dashboard_outlined, size: 18),
                    onPressed: () => context.go('/dashboard'),
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

  Widget _buildHeroCard(BuildContext context, MemberProfile profile) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 36,
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
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.fullName,
                  key: const Key('profileFullNameText'),
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        'Member #${profile.memberId}',
                        key: const Key('profileMemberIdBadge'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        profile.primaryProfileType.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Verified via ${profile.verifiedMethod}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
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
            children: <Widget>[
              const Text(
                'Profile Completion',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                '$percent%',
                key: const Key('profileCompletionPercentText'),
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
              value: percent / 100.0,
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
                ? 'Your profile is fully completed and verified.'
                : 'Complete all business and category attributes for maximum visibility.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
        title: 'Profile Information',
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
                return Chip(
                  label: Text(cap, style: AppTextStyles.labelSmall),
                  backgroundColor: AppColors.secondaryContainer,
                  visualDensity: VisualDensity.compact,
                );
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
          width: 24,
          height: 24,
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
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
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

  Widget _buildRow(IconData icon, String label, String value, {String? key}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTextStyles.labelSmall),
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
}
