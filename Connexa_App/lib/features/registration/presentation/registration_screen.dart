import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Screen 1 of Registration: Collects Basic Details and Profile Type.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String _countryCode = '+91';
  ProfileType? _selectedProfileType;
  String? _profileTypeError;
  bool _isSubmitting = false;

  final List<String> _countryCodes = const <String>[
    '+91', // India
    '+1', // USA / Canada
    '+44', // UK
    '+971', // UAE
    '+65', // Singapore
    '+49', // Germany
  ];

  @override
  void initState() {
    super.initState();
    final RegistrationDraft draft = ref.read(registrationDraftProvider);
    _nameController = TextEditingController(text: draft.fullName);
    _phoneController = TextEditingController(text: draft.mobileNumber);
    _emailController = TextEditingController(text: draft.email);
    _countryCode = draft.countryCode;
    _selectedProfileType = draft.profileType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onProfileTypeSelected(ProfileType type) {
    setState(() {
      _selectedProfileType = type;
      _profileTypeError = null;
    });
  }

  String? _validateName(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Please enter your full name';
    }
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (_countryCode == '+91') {
      final RegExp indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
      if (!indianPhoneRegex.hasMatch(trimmed)) {
        return 'Please enter a valid 10-digit Indian mobile number';
      }
    } else {
      final RegExp generalPhoneRegex = RegExp(r'^\d{7,15}$');
      if (!generalPhoneRegex.hasMatch(trimmed)) {
        return 'Please enter a valid mobile number (7–15 digits)';
      }
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Please enter your email address';
    }
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    final bool isProfileSelected = _selectedProfileType != null;

    if (!isProfileSelected) {
      setState(() {
        _profileTypeError = 'Please select what describes you best';
      });
    }

    if (!isFormValid || !isProfileSelected) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Save values into in-memory registration draft, preserving existing details if profile type is unchanged
    final RegistrationDraft currentDraft = ref.read(registrationDraftProvider);
    final bool sameProfileType =
        _selectedProfileType == currentDraft.profileType;

    final RegistrationDraft updatedDraft = currentDraft.copyWith(
      fullName: _nameController.text.trim(),
      countryCode: _countryCode,
      mobileNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      profileType: _selectedProfileType,
      clearBusinessDetails: !sameProfileType,
      clearEmployeeDetails: !sameProfileType,
      clearServiceEngineerDetails: !sameProfileType,
      clearTraderDetails: !sameProfileType,
      clearContractorDetails: !sameProfileType,
    );

    ref.read(registrationDraftProvider.notifier).state = updatedDraft;

    if (!mounted) return;
    context.go('/registration/profile-details');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexa Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Step Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: AppSpacing.xl),

                  // Header Titles
                  const Text(
                    'Create Your Connexa Account',
                    style: AppTextStyles.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Start building meaningful business connections.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Section: Basic Contact Details Card
                  AppCard(
                    title: 'Contact Details',
                    subtitle:
                        'Enter your verified personal or enterprise contact information.',
                    child: Column(
                      children: <Widget>[
                        // Full Name
                        AppTextField(
                          key: const Key('fullNameField'),
                          controller: _nameController,
                          label: 'Full Name *',
                          hintText: 'e.g., Rajesh Sharma',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Mobile Number with Country Code
                        _buildMobileField(),
                        const SizedBox(height: AppSpacing.lg),

                        // Email Address
                        AppTextField(
                          key: const Key('emailField'),
                          controller: _emailController,
                          label: 'Email Address *',
                          hintText: 'name@company.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          validator: _validateEmail,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Section: Profile Type Selection
                  _buildProfileTypeSection(),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Submit Action Button
                  AppButton.primary(
                    key: const Key('continueButton'),
                    text: 'Continue',
                    isLoading: _isSubmitting,
                    isFullWidth: true,
                    trailingIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    onPressed: _isSubmitting ? null : _handleContinue,
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
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Step 1 of the registration process — Basic Details',
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

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Mobile Number *', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Country Code Selector
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCode,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  items: _countryCodes.map((String code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(code),
                    );
                  }).toList(),
                  onChanged: (String? newCode) {
                    if (newCode != null) {
                      setState(() {
                        _countryCode = newCode;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Number Input
            Expanded(
              child: TextFormField(
                key: const Key('phoneField'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyMedium,
                validator: _validatePhone,
                decoration: const InputDecoration(
                  hintText: '98765 43210',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'What describes you best? *',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose the role that represents your primary participation on Connexa.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Selectable Profile Cards
        ...ProfileType.values.map((ProfileType type) {
          final bool isSelected = _selectedProfileType == type;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onProfileTypeSelected(type),
                borderRadius: AppSpacing.borderRadiusLg,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      // Icon Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainer,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Icon(
                          type.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.onSecondaryContainer
                              : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Text Labels
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              type.label,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              type.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      // Selection Indicator
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.outline,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        if (_profileTypeError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _profileTypeError!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
