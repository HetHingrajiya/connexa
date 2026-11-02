import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/presentation/service_inquiry_sheet.dart';
import 'package:connexa/features/services/providers/services_providers.dart';
import 'package:connexa/features/services/services/services_marketplace_service.dart';

final AutoDisposeFutureProviderFamily<ServiceDetail, int> serviceDetailProvider =
    FutureProvider.autoDispose.family<ServiceDetail, int>((Ref ref, int id) async {
  final ServicesMarketplaceService service =
      ref.watch(servicesMarketplaceServiceProvider);
  return service.getServiceById(id);
});

class ServiceDetailsScreen extends ConsumerWidget {
  const ServiceDetailsScreen({super.key, required this.serviceId});

  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ServiceDetail> detailAsync =
        ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/services');
            }
          },
        ),
        actions: <Widget>[
          detailAsync.maybeWhen(
            data: (ServiceDetail detail) {
              if (detail.isOwner) {
                return PopupMenuButton<String>(
                  onSelected: (String action) async {
                    if (action == 'edit') {
                      context.push('/services/edit/${detail.id}');
                    } else if (action == 'delete') {
                      final bool confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext ctx) => AlertDialog(
                              title: const Text('Delete Service'),
                              content: const Text(
                                'Are you sure you want to deactivate or remove this service?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                ),
                                AppButton.primary(
                                  text: 'Delete',
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirm && context.mounted) {
                        await ref
                            .read(servicesMarketplaceServiceProvider)
                            .deleteService(detail.id);
                        ref
                            .read(myServicesProvider.notifier)
                            .loadMyServices();
                        ref
                            .read(servicesMarketplaceProvider.notifier)
                            .loadServices(refresh: true);
                        if (context.mounted) {
                          context.pop();
                        }
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Text('Edit Service'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          SizedBox(width: AppSpacing.sm),
                          Text('Delete Service',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (ServiceDetail detail) => _buildBody(context, ref, detail),
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading service details...'),
        ),
        error: (Object err, _) => Center(
          child: AppErrorState(
            title: 'Failed to Load Service',
            description: err.toString(),
            onRetry: () => ref.invalidate(serviceDetailProvider(serviceId)),
          ),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (ServiceDetail detail) {
          if (detail.isOwner) return null;
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          detail.pricingModel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          detail.startingPrice != null
                              ? '₹${detail.startingPrice!.toStringAsFixed(0)} ${detail.priceUnit ?? ""}'
                              : 'Custom Quote',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton.primary(
                    key: const Key('inquireServiceButton'),
                    text: 'Send Service Inquiry',
                    trailingIcon:
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: () => ServiceInquirySheet.show(
                      context,
                      serviceId: detail.id,
                      serviceTitle: detail.title,
                      providerName:
                          detail.providerCompanyName ?? detail.providerName,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ServiceDetail detail) {
    return ResponsiveCenterBox(
      padding: AppSpacing.screenPaddingMobile,
      maxTabletWidth: AppSpacing.maxContentWidthTablet,
      maxDesktopWidth: 800,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),

            // Header Overview Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      AppBadge.primary(label: detail.serviceCategory),
                      AppBadge(
                        label: detail.serviceType,
                        variant: AppBadgeVariant.secondary,
                        isPill: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    detail.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${detail.viewCount} views',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${detail.inquiryCount} inquiries received',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Provider Profile Card
            AppCard(
              title: 'Service Provider',
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      detail.providerName.isNotEmpty
                          ? detail.providerName.substring(0, 1).toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          detail.providerCompanyName ?? detail.providerName,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (detail.providerCompanyName != null)
                          Text(
                            detail.providerName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (detail.providerCity != null)
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${detail.providerCity}, ${detail.providerState ?? ""}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Service Specifications Grid Card
            AppCard(
              title: 'Service Specifications',
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: <Widget>[
                  _buildSpecRow(
                    Icons.category_outlined,
                    'Category',
                    detail.serviceCategory,
                  ),
                  const Divider(height: AppSpacing.md),
                  _buildSpecRow(
                    Icons.home_repair_service_outlined,
                    'Delivery Mode',
                    detail.serviceType,
                  ),
                  const Divider(height: AppSpacing.md),
                  _buildSpecRow(
                    Icons.price_change_outlined,
                    'Pricing Model',
                    detail.pricingModel,
                  ),
                  if (detail.turnaroundTime != null) ...<Widget>[
                    const Divider(height: AppSpacing.md),
                    _buildSpecRow(
                      Icons.timer_outlined,
                      'Turnaround Time',
                      detail.turnaroundTime!,
                    ),
                  ],
                  if (detail.coverageArea != null) ...<Widget>[
                    const Divider(height: AppSpacing.md),
                    _buildSpecRow(
                      Icons.map_outlined,
                      'Coverage Area',
                      detail.coverageArea!,
                    ),
                  ],
                  if (detail.certifications != null) ...<Widget>[
                    const Divider(height: AppSpacing.md),
                    _buildSpecRow(
                      Icons.verified_outlined,
                      'Certifications',
                      detail.certifications!,
                    ),
                  ],
                  if (detail.yearsOfExperience != null) ...<Widget>[
                    const Divider(height: AppSpacing.md),
                    _buildSpecRow(
                      Icons.workspace_premium_outlined,
                      'Experience',
                      '${detail.yearsOfExperience} Years in Industry',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Description Card
            AppCard(
              title: 'Detailed Scope & Deliverables',
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                detail.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

