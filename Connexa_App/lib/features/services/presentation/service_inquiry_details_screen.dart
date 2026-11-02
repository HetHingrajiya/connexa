import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/providers/services_providers.dart';
import 'package:connexa/features/services/services/services_marketplace_service.dart';

final AutoDisposeFutureProviderFamily<ServiceInquiry, int> serviceInquiryDetailProvider =
    FutureProvider.autoDispose.family<ServiceInquiry, int>((Ref ref, int id) async {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return service.getInquiryById(id);
});

class ServiceInquiryDetailsScreen extends ConsumerStatefulWidget {
  const ServiceInquiryDetailsScreen({super.key, required this.inquiryId});

  final int inquiryId;

  @override
  ConsumerState<ServiceInquiryDetailsScreen> createState() =>
      _ServiceInquiryDetailsScreenState();
}

class _ServiceInquiryDetailsScreenState
    extends ConsumerState<ServiceInquiryDetailsScreen> {
  void _showRespondDialog(ServiceInquiry inquiry) {
    final TextEditingController responseController = TextEditingController();
    bool acceptInquiry = true;
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext modalCtx, StateSetter setModalState) {
          return AlertDialog(
            title: const Text('Respond to Inquiry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Inquiry #${inquiry.inquiryNumber} from ${inquiry.senderCompanyName ?? inquiry.senderName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Accept / Quote'),
                          selected: acceptInquiry,
                          onSelected: (bool selected) {
                            if (selected) {
                              setModalState(() => acceptInquiry = true);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Decline'),
                          selected: !acceptInquiry,
                          onSelected: (bool selected) {
                            if (selected) {
                              setModalState(() => acceptInquiry = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: responseController,
                    label: 'Response / Quote Message *',
                    hintText:
                        'Provide pricing, availability, equipment confirmation, or reason for declining...',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              AppButton.primary(
                text: 'Send Response',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final String text = responseController.text.trim();
                        if (text.isEmpty) return;

                        setModalState(() => isSubmitting = true);
                        final bool ok = await ref
                            .read(serviceInquiriesProvider.notifier)
                            .respondInquiry(
                              inquiry.id,
                              RespondServiceInquiryRequest(
                                responseMessage: text,
                                acceptInquiry: acceptInquiry,
                              ),
                            );

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (ok && mounted) {
                          ref.invalidate(
                              serviceInquiryDetailProvider(widget.inquiryId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Response sent successfully.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusDialog(ServiceInquiry inquiry) {
    ServiceInquiryStatus selectedStatus = inquiry.status;
    final TextEditingController remarksController = TextEditingController();
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext modalCtx, StateSetter setModalState) {
          return AlertDialog(
            title: const Text('Update Inquiry Status'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Change status for #${inquiry.inquiryNumber}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<ServiceInquiryStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ServiceInquiryStatus.values
                        .map((ServiceInquiryStatus s) =>
                            DropdownMenuItem<ServiceInquiryStatus>(
                              value: s,
                              child: Text(s.label),
                            ))
                        .toList(),
                    onChanged: (ServiceInquiryStatus? s) {
                      if (s != null) {
                        setModalState(() => selectedStatus = s);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: remarksController,
                    label: 'Remarks (Optional)',
                    hintText: 'e.g. Agreement signed, project completed, etc.',
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              AppButton.primary(
                text: 'Update Status',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        final bool ok = await ref
                            .read(serviceInquiriesProvider.notifier)
                            .updateStatus(
                              inquiry.id,
                              selectedStatus,
                              remarksController.text.trim(),
                            );

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (ok && mounted) {
                          ref.invalidate(
                              serviceInquiryDetailProvider(widget.inquiryId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status updated successfully.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ServiceInquiry> inqAsync =
        ref.watch(serviceInquiryDetailProvider(widget.inquiryId));
    final int? currentMemberId = ref.watch(authProvider).user?.memberId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inquiry Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: inqAsync.when(
        data: (ServiceInquiry inq) {
          final bool isProvider = currentMemberId == inq.recipientMemberId;

          return ResponsiveCenterBox(
            padding: AppSpacing.screenPaddingMobile,
            maxTabletWidth: AppSpacing.maxContentWidthTablet,
            maxDesktopWidth: 800,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Header Status Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              inq.inquiryNumber,
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Submitted on ${inq.createdAtUtc.day}/${inq.createdAtUtc.month}/${inq.createdAtUtc.year}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: inq.status.color.withValues(alpha: 0.15),
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            inq.status.label,
                            style: TextStyle(
                              color: inq.status.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Service Reference Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: const Icon(
                          Icons.home_repair_service_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        inq.serviceTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(inq.serviceCategory),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16),
                      onTap: () => context.push('/services/${inq.serviceId}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Parties Card
                  AppCard(
                    title: 'Involved Parties',
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.person_pin_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Client / Inquirer',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    inq.senderCompanyName ?? inq.senderName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (inq.senderEmail != null)
                                    Text(
                                      inq.senderEmail!,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.business_rounded,
                                color: AppColors.secondary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Service Provider',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    inq.recipientCompanyName ??
                                        inq.recipientName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Requirement Details Card
                  AppCard(
                    title: inq.subject,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          inq.requirementDescription,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.5,
                          ),
                        ),
                        if (inq.scopeOfWork != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Scope of Work:',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            inq.scopeOfWork!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            if (inq.location != null)
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    inq.location!,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            if (inq.estimatedBudget != null)
                              Text(
                                'Budget: ₹${inq.estimatedBudget!.toStringAsFixed(0)}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Provider Response Card (if present)
                  if (inq.responseMessage != null) ...<Widget>[
                    AppCard(
                      title: 'Provider Response',
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            inq.responseMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.5,
                            ),
                          ),
                          if (inq.respondedAtUtc != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Responded on ${inq.respondedAtUtc!.day}/${inq.respondedAtUtc!.month}/${inq.respondedAtUtc!.year}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Status History Timeline Card
                  if (inq.statusHistory.isNotEmpty) ...<Widget>[
                    AppCard(
                      title: 'Timeline & History',
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: inq.statusHistory.map((ServiceInquiryStatusHistory h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(Icons.fiber_manual_record,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Status changed to ${h.statusName} by ${h.changedByName}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (h.remarks != null &&
                                          h.remarks!.isNotEmpty)
                                        Text(
                                          h.remarks!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary),
                                        ),
                                      Text(
                                        '${h.changedAtUtc.day}/${h.changedAtUtc.month}/${h.changedAtUtc.year} ${h.changedAtUtc.hour.toString().padLeft(2, '0')}:${h.changedAtUtc.minute.toString().padLeft(2, '0')}',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                                color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Action Buttons
                  Row(
                    children: <Widget>[
                      if (isProvider && inq.status == ServiceInquiryStatus.pending)
                        Expanded(
                          child: AppButton.primary(
                            key: const Key('respondServiceInquiryButton'),
                            text: 'Respond to Inquiry',
                            onPressed: () => _showRespondDialog(inq),
                          ),
                        ),
                      if (isProvider && inq.status == ServiceInquiryStatus.pending)
                        const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton.secondary(
                          key: const Key('updateInquiryStatusButton'),
                          text: 'Update Status',
                          onPressed: () => _showStatusDialog(inq),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading inquiry details...'),
        ),
        error: (Object err, _) => Center(
          child: AppErrorState(
            title: 'Failed to Load Inquiry',
            description: err.toString(),
            onRetry: () =>
                ref.invalidate(serviceInquiryDetailProvider(widget.inquiryId)),
          ),
        ),
      ),
    );
  }
}
