import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';

/// Screen allowing the authenticated member to edit supported profile fields.
/// Enforces server-side validation and ownership checks.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _companyOrWorkController;
  late TextEditingController _descriptionController;

  // Selected 4-Tier IDs
  int? _selectedIndustryId;
  int? _selectedBusinessGroupId;
  int? _selectedSubGroupId;
  int? _selectedCategoryId;

  // Selected Capabilities
  final Set<String> _selectedCapabilities = <String>{};

  static const List<String> _availableCapabilities = <String>[
    'Manufacturer',
    'Supplier',
    'Exporter',
    'Importer',
    'Distributor',
    'Wholesaler',
    'Retailer',
    'Service Provider',
    'Contractor',
    'Consultant',
  ];

  bool _initialized = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final MemberProfile? profile = ref.read(authProvider).profile;
      _fullNameController = TextEditingController(
        text: profile?.fullName ?? '',
      );

      final Map<String, dynamic>? details = profile?.profileDetails;
      final String companyName =
          details?['companyName']?.toString() ??
          details?['workName']?.toString() ??
          details?['tradingName']?.toString() ??
          details?['jobTitle']?.toString() ??
          '';

      _companyOrWorkController = TextEditingController(text: companyName);
      _descriptionController = TextEditingController(
        text: details?['businessDescription']?.toString() ?? '',
      );

      // Initialize Capabilities
      final dynamic rawCaps =
          details?['businessCapabilities'] ??
          details?['workCapabilities'] ??
          details?['capabilities'];
      if (rawCaps is List) {
        for (final dynamic c in rawCaps) {
          if (c != null && c.toString().isNotEmpty) {
            _selectedCapabilities.add(c.toString());
          }
        }
      }

      // Initialize 4-Tier IDs
      _selectedIndustryId = (details?['industryId'] as num?)?.toInt();
      _selectedBusinessGroupId = (details?['businessGroupId'] as num?)?.toInt();
      _selectedSubGroupId = (details?['subGroupId'] as num?)?.toInt();
      _selectedCategoryId = (details?['categoryId'] as num?)?.toInt();

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyOrWorkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final MemberProfile? profile = ref.read(authProvider).profile;
    if (profile == null) return;

    setState(() {
      _errorMessage = null;
    });

    final String fullName = _fullNameController.text.trim();
    final Map<String, dynamic> payload = <String, dynamic>{
      'fullName': fullName,
    };

    final String profileType = profile.primaryProfileType;
    if (profileType == 'BusinessCompany') {
      if (_selectedIndustryId == null ||
          _selectedBusinessGroupId == null ||
          _selectedSubGroupId == null ||
          _selectedCategoryId == null) {
        setState(() {
          _errorMessage =
              'Please complete all 4 tiers of Industry classification.';
        });
        return;
      }

      payload['businessDetails'] = <String, dynamic>{
        'companyName': _companyOrWorkController.text.trim(),
        'businessCapabilities': _selectedCapabilities.toList(),
        'businessDescription': _descriptionController.text.trim(),
        'industryId': _selectedIndustryId,
        'businessGroupId': _selectedBusinessGroupId,
        'subGroupId': _selectedSubGroupId,
        'categoryId': _selectedCategoryId,
      };
    } else if (profileType == 'EmployeeJobSeeker') {
      payload['employeeDetails'] = <String, dynamic>{
        'jobTitle': _companyOrWorkController.text.trim(),
        'skills': _descriptionController.text.trim(),
      };
    } else if (profileType == 'ContractorJobWorker') {
      if (_selectedIndustryId == null ||
          _selectedBusinessGroupId == null ||
          _selectedSubGroupId == null ||
          _selectedCategoryId == null) {
        setState(() {
          _errorMessage =
              'Please complete all 4 tiers of Industry classification.';
        });
        return;
      }

      payload['contractorDetails'] = <String, dynamic>{
        'workName': _companyOrWorkController.text.trim(),
        'workCapabilities': _selectedCapabilities.toList(),
        'workCoverage': _descriptionController.text.trim(),
        'industryId': _selectedIndustryId,
        'businessGroupId': _selectedBusinessGroupId,
        'subGroupId': _selectedSubGroupId,
        'categoryId': _selectedCategoryId,
      };
    }

    final bool success = await ref
        .read(authProvider.notifier)
        .updateProfile(payload);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        setState(() {
          _errorMessage =
              ref.read(authProvider).errorMessage ??
              'Failed to update profile. Please verify your entries.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final MemberProfile? profile = authState.profile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('No active profile found.')),
      );
    }

    final bool isBusiness =
        profile.primaryProfileType == 'BusinessCompany' ||
        profile.primaryProfileType == 'ContractorJobWorker';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Error notification if any
                  if (_errorMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Identity Section Card
                  AppCard(
                    title: 'Personal Identity',
                    subtitle: 'Full name and verified identifiers',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppTextField(
                          controller: _fullNameController,
                          label: 'Full Name *',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (String? val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Full name cannot be blank';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Email (${profile.email}) and Phone (${profile.phoneNumber}) are verified credentials and cannot be edited directly.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Business Details Card
                  AppCard(
                    title: 'Business Information',
                    subtitle:
                        'Visible to verified Connexa members in Directory',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppTextField(
                          controller: _companyOrWorkController,
                          label: isBusiness
                              ? 'Company / Business Name *'
                              : 'Job Title / Specialization *',
                          hintText: 'e.g. Acme Industrial Solutions',
                          prefixIcon: const Icon(Icons.business_outlined),
                          validator: (String? val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'This field is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'Description & Capabilities',
                          hintText:
                              'Describe your business operations, services, or equipment...',
                          maxLines: 3,
                          prefixIcon: const Icon(Icons.notes_outlined),
                        ),
                        if (isBusiness) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Business Capabilities',
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _availableCapabilities.map((String cap) {
                              final bool isSelected = _selectedCapabilities
                                  .contains(cap);
                              return FilterChip(
                                label: Text(cap),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCapabilities.add(cap);
                                    } else {
                                      _selectedCapabilities.remove(cap);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4-Tier Hierarchy Card (for Business / Contractor)
                  if (isBusiness) ...<Widget>[
                    _buildHierarchyDropdownsCard(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Action Buttons
                  AppButton.primary(
                    key: const Key('editProfileSaveButton'),
                    text: 'Save Changes',
                    isLoading: authState.isLoading,
                    leadingIcon: const Icon(Icons.save_rounded, size: 18),
                    onPressed: authState.isLoading ? null : _handleSubmit,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppButton.secondary(
                    text: 'Cancel',
                    onPressed: () => context.pop(),
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

  Widget _buildHierarchyDropdownsCard() {
    final AsyncValue<List<Industry>> industriesAsync = ref.watch(
      industriesProvider,
    );

    return AppCard(
      title: 'Industry Classification',
      subtitle: 'Select exact 4-tier industry category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Industry Dropdown
          industriesAsync.when(
            data: (List<Industry> industries) {
              return DropdownButtonFormField<int>(
                key: const Key('editProfileIndustryDropdown'),
                isExpanded: true,
                initialValue:
                    _selectedIndustryId != null &&
                        industries.any(
                          (Industry i) => i.id == _selectedIndustryId,
                        )
                    ? _selectedIndustryId
                    : null,
                decoration: const InputDecoration(
                  labelText: '1. Industry *',
                  prefixIcon: Icon(Icons.factory_outlined),
                ),
                items: industries.map((Industry i) {
                  return DropdownMenuItem<int>(
                    value: i.id,
                    child: Text(i.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (int? newId) {
                  setState(() {
                    _selectedIndustryId = newId;
                    _selectedBusinessGroupId = null;
                    _selectedSubGroupId = null;
                    _selectedCategoryId = null;
                  });
                },
              );
            },
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (Object err, _) => Text(
              'Failed to load industries: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Business Group Dropdown
          if (_selectedIndustryId != null) ...<Widget>[
            ref
                .watch(businessGroupsProvider(_selectedIndustryId!))
                .when(
                  data: (List<BusinessGroup> groups) {
                    return DropdownButtonFormField<int>(
                      key: const Key('editProfileBusinessGroupDropdown'),
                      isExpanded: true,
                      initialValue:
                          _selectedBusinessGroupId != null &&
                              groups.any(
                                (BusinessGroup g) =>
                                    g.id == _selectedBusinessGroupId,
                              )
                          ? _selectedBusinessGroupId
                          : null,
                      decoration: const InputDecoration(
                        labelText: '2. Business Group *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: groups.map((BusinessGroup g) {
                        return DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(g.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (int? newId) {
                        setState(() {
                          _selectedBusinessGroupId = newId;
                          _selectedSubGroupId = null;
                          _selectedCategoryId = null;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (Object err, _) => Text('Failed to load groups: $err'),
                ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 3. SubGroup Dropdown
          if (_selectedBusinessGroupId != null) ...<Widget>[
            ref
                .watch(subGroupsProvider(_selectedBusinessGroupId!))
                .when(
                  data: (List<SubGroup> subGroups) {
                    return DropdownButtonFormField<int>(
                      key: const Key('editProfileSubGroupDropdown'),
                      isExpanded: true,
                      initialValue:
                          _selectedSubGroupId != null &&
                              subGroups.any(
                                (SubGroup s) => s.id == _selectedSubGroupId,
                              )
                          ? _selectedSubGroupId
                          : null,
                      decoration: const InputDecoration(
                        labelText: '3. SubGroup *',
                        prefixIcon: Icon(Icons.account_tree_outlined),
                      ),
                      items: subGroups.map((SubGroup s) {
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (int? newId) {
                        setState(() {
                          _selectedSubGroupId = newId;
                          _selectedCategoryId = null;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (Object err, _) =>
                      Text('Failed to load subgroups: $err'),
                ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 4. Category Dropdown
          if (_selectedSubGroupId != null) ...<Widget>[
            ref
                .watch(categoriesProvider(_selectedSubGroupId!))
                .when(
                  data: (List<Category> categories) {
                    return DropdownButtonFormField<int>(
                      key: const Key('editProfileCategoryDropdown'),
                      isExpanded: true,
                      initialValue:
                          _selectedCategoryId != null &&
                              categories.any(
                                (Category c) => c.id == _selectedCategoryId,
                              )
                          ? _selectedCategoryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: '4. Category *',
                        prefixIcon: Icon(Icons.grid_view_outlined),
                      ),
                      items: categories.map((Category c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (int? newId) {
                        setState(() {
                          _selectedCategoryId = newId;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (Object err, _) =>
                      Text('Failed to load categories: $err'),
                ),
          ],
        ],
      ),
    );
  }
}
