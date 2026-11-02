import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/profile/models/business_verification_models.dart';
import 'package:connexa/features/profile/providers/business_verification_provider.dart';
import 'package:connexa/features/profile/services/business_verification_service.dart';

/// Screen allowing administrators to review, approve, or reject business verification applications.
class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends ConsumerState<AdminVerificationScreen> {
  String _selectedStatus = 'PendingReview';
  int _currentPage = 1;

  static const List<String> _statusFilters = <String>[
    'PendingReview',
    'Approved',
    'Rejected',
    'All',
  ];

  AdminVerificationFilter get _filter =>
      AdminVerificationFilter(status: _selectedStatus, page: _currentPage);

  @override
  Widget build(BuildContext context) {
    final MemberProfile? profile = ref.watch(authProvider).profile;

    if (profile?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access Required')),
        body: const Center(
          child: AppErrorState(
            title: 'Unauthorized Access',
            description:
                'You must have Administrator privileges to review business verifications.',
          ),
        ),
      );
    }

    final AsyncValue<AdminVerificationListResponse> listAsync = ref.watch(
      adminVerificationsProvider(_filter),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Verifications Review'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(adminVerificationsProvider(_filter));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilters.map((String status) {
                    final bool isSelected = _selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        key: Key('filterChip_$status'),
                        label: Text(_formatFilterLabel(status)),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = status;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Applications Content
              Expanded(
                child: listAsync.when(
                  loading: () => const Center(
                    child: AppLoadingIndicator(
                      message: 'Loading verification requests...',
                    ),
                  ),
                  error: (Object err, _) => Center(
                    child: AppErrorState(
                      title: 'Error Loading Requests',
                      description: err.toString().replaceAll('Exception: ', ''),
                      onRetry: () {
                        ref.invalidate(adminVerificationsProvider(_filter));
                      },
                    ),
                  ),
                  data: (AdminVerificationListResponse listData) {
                    if (listData.items.isEmpty) {
                      return Center(
                        child: AppEmptyState(
                          title: 'No Applications Found',
                          description:
                              'There are no verification requests matching "${_formatFilterLabel(_selectedStatus)}".',
                          actionLabel: 'Check All Statuses',
                          onAction: () {
                            setState(() {
                              _selectedStatus = 'All';
                              _currentPage = 1;
                            });
                          },
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(adminVerificationsProvider(_filter));
                      },
                      child: ListView.separated(
                        itemCount: listData.items.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (BuildContext context, int index) {
                          final BusinessVerificationRequest req =
                              listData.items[index];
                          return _buildApplicationCard(context, req);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    BusinessVerificationRequest req,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _showReviewDetailsSheet(context, req),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  req.companyName.isEmpty ? 'Unnamed Company' : req.companyName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Owner: ${req.ownerFullName} • ${req.ownerPhoneNumber}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(
                Icons.badge_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Reg ID: ${req.businessRegistrationNumber}',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.attach_file_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              Text(
                '${req.documents.length} docs',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return const AppBadge.success(
          label: 'Approved',
          icon: Icon(Icons.check_circle_rounded, size: 14),
        );
      case VerificationStatus.pendingReview:
        return const AppBadge.warning(
          label: 'Pending Review',
          icon: Icon(Icons.access_time_rounded, size: 14),
        );
      case VerificationStatus.rejected:
        return const AppBadge.error(
          label: 'Rejected',
          icon: Icon(Icons.cancel_rounded, size: 14),
        );
      case VerificationStatus.notSubmitted:
        return const AppBadge.neutral(label: 'Not Submitted');
    }
  }

  void _showReviewDetailsSheet(
    BuildContext context,
    BusinessVerificationRequest req,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              req.companyName,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Submitted by ${req.ownerFullName} (${req.ownerEmail})',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(req.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Verification Details
                  Text(
                    'Business Credentials',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow(
                    'Registration Number',
                    req.businessRegistrationNumber,
                  ),
                  _buildDetailRow('Registered Address', req.registeredAddress),
                  _buildDetailRow(
                    'Location',
                    '${req.city}, ${req.state} - ${req.pincode}',
                  ),
                  if (req.notes != null && req.notes!.isNotEmpty)
                    _buildDetailRow('Applicant Notes', req.notes!),
                  _buildDetailRow(
                    'Submitted At',
                    '${req.submittedAtUtc.toLocal()}',
                  ),

                  if (req.rejectionReason != null &&
                      req.rejectionReason!.isNotEmpty)
                    _buildDetailRow('Rejection Remarks', req.rejectionReason!),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Uploaded Documents
                  Text(
                    'Uploaded Verification Documents (${req.documents.length})',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (req.documents.isEmpty)
                    const Text('No documents uploaded.')
                  else
                    ...req.documents.map((BusinessVerificationDocument doc) {
                      return ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          doc.originalFileName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${doc.documentType} • ${(doc.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                        ),
                        trailing: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                      );
                    }),

                  const SizedBox(height: AppSpacing.xl),

                  // Admin Action Buttons if Pending Review
                  if (req.status == VerificationStatus.pendingReview) ...<
                    Widget
                  >[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton.secondary(
                            text: 'Reject with Remarks',
                            leadingIcon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showRejectDialog(req.id);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton.primary(
                            text: 'Approve & Verify',
                            leadingIcon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _confirmApprove(req.id);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmApprove(int requestId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Approve Verification?'),
          content: const Text(
            'This business will receive the official Verified badge, increased visibility, and an instant push notification.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      final BusinessVerificationService service = ref.read(
        businessVerificationServiceProvider,
      );
      await service.approveVerification(requestId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(adminVerificationsProvider(_filter));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approval failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(int requestId) async {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? shouldReject = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reject Verification Application'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'A valid rejection reason is required so the business owner knows what corrections are needed.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('rejectionReasonField'),
                  controller: reasonController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason *',
                    hintText:
                        'e.g. GST Certificate expired; name does not match.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Rejection reason is strictly required.';
                    }
                    if (val.trim().length < 5) {
                      return 'Please provide a clear reason (at least 5 characters).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      },
    );

    if (shouldReject != true || !mounted) return;

    try {
      final BusinessVerificationService service = ref.read(
        businessVerificationServiceProvider,
      );
      await service.rejectVerification(requestId, reasonController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification application rejected with remarks.'),
          backgroundColor: AppColors.warning,
        ),
      );
      ref.invalidate(adminVerificationsProvider(_filter));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejection failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
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
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFilterLabel(String status) {
    switch (status) {
      case 'PendingReview':
        return 'Pending Review';
      case 'Approved':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
      default:
        return 'All Applications';
    }
  }
}
