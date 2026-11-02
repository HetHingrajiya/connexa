import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/profile/models/business_verification_models.dart';
import 'package:connexa/features/profile/providers/business_verification_provider.dart';

/// Screen allowing business owners to view verification status and submit credentials.
class BusinessVerificationScreen extends ConsumerStatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  ConsumerState<BusinessVerificationScreen> createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends ConsumerState<BusinessVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _regNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _notesController;

  final List<DocumentUploadItem> _attachedDocuments = <DocumentUploadItem>[];
  String _selectedDocType = 'GST Certificate';

  static const List<String> _docTypes = <String>[
    'GST Certificate',
    'PAN Card',
    'Trade License',
    'MSME Certificate',
    'Certificate of Incorporation',
  ];

  bool _initialized = false;
  String? _documentError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final MemberProfile? profile = ref.read(authProvider).profile;
      _regNumberController = TextEditingController();
      _addressController = TextEditingController(text: profile?.address ?? '');
      _cityController = TextEditingController(text: profile?.city ?? '');
      _stateController = TextEditingController(text: profile?.state ?? '');
      _pincodeController = TextEditingController(text: profile?.pincode ?? '');
      _notesController = TextEditingController();

      // Pre-add a sample GST document placeholder for convenient testing & demo
      _addSampleDocument('GST Certificate', 'gst_certificate.pdf');

      _initialized = true;
    }
  }

  void _addSampleDocument(String docType, String fileName) {
    final List<int> dummyBytes = utf8.encode(
      'Connexa Verified Business Document Sample: $docType ($fileName)',
    );
    _attachedDocuments.add(
      DocumentUploadItem(
        fileName: fileName,
        documentType: docType,
        bytes: dummyBytes,
        contentType: fileName.endsWith('.pdf')
            ? 'application/pdf'
            : 'image/png',
      ),
    );
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _documentError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_attachedDocuments.isEmpty) {
      setState(() {
        _documentError = 'Please attach at least one verification document.';
      });
      return;
    }

    final bool success = await ref
        .read(verificationSubmitProvider.notifier)
        .submitVerification(
          registrationNumber: _regNumberController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateName: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          documents: _attachedDocuments,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification application submitted successfully! Our team will review it.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<VerificationStatusResponse> statusAsync = ref.watch(
      verificationStatusProvider,
    );
    final VerificationSubmitState submitState = ref.watch(
      verificationSubmitProvider,
    );
    final MemberProfile? profile = ref.watch(authProvider).profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Verification'),
        actions: <Widget>[
          if (profile?.isAdmin == true)
            TextButton.icon(
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
              label: const Text('Admin Panel'),
              onPressed: () => context.push('/admin/verifications'),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: statusAsync.when(
            loading: () => const Center(
              child: AppLoadingIndicator(
                message: 'Checking verification status...',
              ),
            ),
            error: (Object err, _) => Center(
              child: AppErrorState(
                title: 'Status Unavailable',
                description: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(verificationStatusProvider),
              ),
            ),
            data: (VerificationStatusResponse statusData) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.sm),

                    // Top Status Banner
                    _buildStatusBanner(context, statusData, profile),
                    const SizedBox(height: AppSpacing.lg),

                    // Show application form if Not Submitted or Rejected
                    if (statusData.status == VerificationStatus.notSubmitted ||
                        statusData.status == VerificationStatus.rejected) ...<
                      Widget
                    >[
                      _buildSubmissionForm(submitState),
                    ] else ...<Widget>[
                      _buildSubmittedDetailsCard(statusData),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    VerificationStatusResponse statusData,
    MemberProfile? profile,
  ) {
    switch (statusData.status) {
      case VerificationStatus.approved:
        return AppCard(
          backgroundColor: AppColors.successContainer.withValues(alpha: 0.4),
          borderColor: AppColors.success.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile?.companyName ?? 'Verified Business',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const AppBadge.success(
                          label: 'Officially Verified',
                          icon: Icon(Icons.check_circle_rounded, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Congratulations! Your business is officially verified on Connexa. You enjoy highest search visibility and verified trust badges across our B2B directory.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case VerificationStatus.pendingReview:
        return AppCard(
          backgroundColor: AppColors.warningContainer.withValues(alpha: 0.4),
          borderColor: AppColors.warning.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Verification Under Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        AppBadge.warning(
                          label: 'Pending Admin Review',
                          icon: Icon(Icons.access_time_rounded, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Our compliance team is verifying your registration documents. We will notify you via in-app and push notification as soon as verification completes.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case VerificationStatus.rejected:
        return AppCard(
          backgroundColor: AppColors.errorContainer.withValues(alpha: 0.4),
          borderColor: AppColors.error.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Verification Rejected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(height: 2),
                        AppBadge.error(
                          label: 'Action Required',
                          icon: Icon(Icons.priority_high_rounded, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (statusData.rejectionReason != null &&
                  statusData.rejectionReason!.isNotEmpty) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Reviewer Feedback:',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusData.rejectionReason!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                'Please update your details or upload updated documentation below to resubmit your verification request.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case VerificationStatus.notSubmitted:
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Get Your Business Verified',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        AppBadge.primary(
                          label: 'Verification Pending',
                          icon: Icon(Icons.shield_rounded, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Stand out in the Connexa B2B network. Verified businesses receive trust badges, direct quotation requests, and prioritized placement in search results.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSubmissionForm(VerificationSubmitState submitState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Official Registration Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '1. Official Registration Details',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Provide your registered business identification number (GSTIN, PAN, CIN, or Trade License).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  key: const Key('verificationRegNumberField'),
                  controller: _regNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Business Registration / Tax ID *',
                    hintText: 'e.g. 24AAACB1234C1Z5 (GSTIN) or PAN',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Registration number is required.';
                    }
                    if (value.trim().length < 5) {
                      return 'Enter a valid registration number (at least 5 characters).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Registered Address Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '2. Registered Business Address',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  key: const Key('verificationAddressField'),
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Premises / Street Address *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Address is required.' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        key: const Key('verificationCityField'),
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'City is required.' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        key: const Key('verificationPincodeField'),
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Pincode is required.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  key: const Key('verificationStateField'),
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State / Province *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'State is required.' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  key: const Key('verificationNotesField'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'e.g. Years in operation, branches, certifications',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Supporting Documents Card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '3. Supporting Documents',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Upload official business proofs (GST certificate, PAN card, Trade license, MSME registration). Confidential documents are stored securely outside public web roots.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Attached Documents List
                if (_attachedDocuments.isNotEmpty) ...<Widget>[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attachedDocuments.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (BuildContext context, int index) {
                      final DocumentUploadItem doc = _attachedDocuments[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    doc.fileName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    doc.documentType,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Remove',
                              onPressed: () {
                                setState(() {
                                  _attachedDocuments.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Document Picker / Add Control
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedDocType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          isDense: true,
                        ),
                        items: _docTypes.map((String t) {
                          return DropdownMenuItem<String>(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              _selectedDocType = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 4,
                      child: AppButton.secondary(
                        key: const Key('addDocumentButton'),
                        text: 'Attach Doc',
                        leadingIcon: const Icon(Icons.attach_file_rounded, size: 16),
                        onPressed: () {
                          final String sanitizedName =
                              '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}.pdf';
                          setState(() {
                            _addSampleDocument(_selectedDocType, sanitizedName);
                            _documentError = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (_documentError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _documentError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error banner from notifier
          if (submitState.errorMessage != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      submitState.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
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

          // Submit Action Button
          AppButton.primary(
            key: const Key('submitVerificationButton'),
            text: submitState.isSubmitting
                ? 'Submitting Application...'
                : 'Submit Verification Application',
            leadingIcon: submitState.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            isFullWidth: true,
            onPressed: submitState.isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedDetailsCard(VerificationStatusResponse statusData) {
    final BusinessVerificationRequest? req = statusData.latestRequest;
    if (req == null) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Application Details',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Registration ID', req.businessRegistrationNumber),
          _buildInfoRow('Address', '${req.registeredAddress}, ${req.city}, ${req.state} - ${req.pincode}'),
          if (req.notes != null && req.notes!.isNotEmpty)
            _buildInfoRow('Notes', req.notes!),
          _buildInfoRow(
            'Submitted On',
            '${req.submittedAtUtc.day}/${req.submittedAtUtc.month}/${req.submittedAtUtc.year}',
          ),
          if (req.documents.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Attached Documents (${req.documents.length})',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...req.documents.map((BusinessVerificationDocument doc) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.file_present_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${doc.originalFileName} (${doc.documentType})',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
