import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';
import 'package:connexa/features/job_work/services/job_work_service.dart';

final FutureProviderFamily<JobWorkOrder, int> jobWorkSingleOrderProvider =
    FutureProvider.family<JobWorkOrder, int>((Ref ref, int orderId) async {
  final JobWorkService service = ref.watch(jobWorkServiceProvider);
  return service.getOrderById(orderId);
});

class JobWorkOrderDetailsScreen extends ConsumerStatefulWidget {
  const JobWorkOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  final int orderId;

  @override
  ConsumerState<JobWorkOrderDetailsScreen> createState() =>
      _JobWorkOrderDetailsScreenState();
}

class _JobWorkOrderDetailsScreenState
    extends ConsumerState<JobWorkOrderDetailsScreen> {
  bool _isActionLoading = false;

  Future<void> _updateStatus(JobWorkOrderStatus newStatus, {String? defaultRemarks}) async {
    final TextEditingController remarksCtrl = TextEditingController(text: defaultRemarks ?? '');
    final String actionTitle = newStatus == JobWorkOrderStatus.processing
        ? 'Start Job Work Processing'
        : newStatus == JobWorkOrderStatus.completed
            ? 'Mark Order as Completed'
            : 'Update Order Status';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Are you sure you want to transition this order to ${newStatus.label}?'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes (Optional)',
                hintText: 'e.g. Material loaded on VMC, completed QC report',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(jobWorkServiceProvider).updateOrderStatus(
            orderId: widget.orderId,
            newStatus: newStatus,
            remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
          );

      // Refresh order
      ref.invalidate(jobWorkSingleOrderProvider(widget.orderId));
      ref.read(jobWorkOrdersProvider('buyer').notifier).loadOrders();
      ref.read(jobWorkOrdersProvider('contractor').notifier).loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.label} successfully!'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final TextEditingController reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cancel Job Work Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason *',
                hintText: 'e.g. Specifications changed, timeline delay',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(jobWorkServiceProvider).cancelOrder(
            orderId: widget.orderId,
            reason: reasonCtrl.text.trim(),
          );

      ref.invalidate(jobWorkSingleOrderProvider(widget.orderId));
      ref.read(jobWorkOrdersProvider('buyer').notifier).loadOrders();
      ref.read(jobWorkOrdersProvider('contractor').notifier).loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel order.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<JobWorkOrder> orderAsync =
        ref.watch(jobWorkSingleOrderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading order...'),
        ),
        error: (Object err, _) => AppErrorState(
          title: 'Failed to load order',
          description: err.toString(),
          onRetry: () =>
              ref.invalidate(jobWorkSingleOrderProvider(widget.orderId)),
        ),
        data: (JobWorkOrder order) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jobWorkSingleOrderProvider(widget.orderId));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              // 1. Order Header Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Process: ${order.process} • Lead Time: ${order.leadTimeDays} days',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Lifecycle Stepper
              _buildLifecycleTimeline(order.status),
              const SizedBox(height: AppSpacing.md),

              // 3. Financial Breakdown Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Commercial Snapshot',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        'Agreed Unit Rate:',
                        '${order.formattedRate} / ${order.unitOfMeasurement}',
                      ),
                      _buildSummaryRow(
                        'Quantity:',
                        '${order.quantity.toInt()} ${order.unitOfMeasurement}',
                      ),
                      _buildSummaryRow(
                        'Subtotal:',
                        '₹${order.subtotal.toStringAsFixed(2)}',
                      ),
                      _buildSummaryRow(
                        'GST Amount:',
                        '₹${order.taxAmount.toStringAsFixed(2)}',
                      ),
                      if (order.otherCharges > 0)
                        _buildSummaryRow(
                          'Tooling / Other:',
                          '₹${order.otherCharges.toStringAsFixed(2)}',
                        ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Total Order Value:',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            order.formattedTotal,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Counterparty Details
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Counterparty Information',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Divider(height: 16),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(Icons.business_outlined,
                              size: 18, color: AppColors.primary),
                        ),
                        title: Text(
                          order.isBuyer
                              ? 'Contractor: ${order.contractorCompanyName}'
                              : 'Buyer: ${order.buyerCompanyName}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          order.isBuyer
                              ? 'Contact: ${order.contractorFullName}'
                              : 'Contact: ${order.buyerFullName}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Delivery: ${order.deliveryLocation}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Status Audit Trail Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Audit Trail & Status History',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const Divider(height: 16),
                      if (order.statusHistory.isEmpty)
                        const Text('No status updates recorded.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary))
                      else
                        ...order.statusHistory
                            .map((JobWorkOrderStatusHistory h) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Icon(Icons.radio_button_checked,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Text(
                                                  h.newStatus,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  '${h.changedAtUtc.day}/${h.changedAtUtc.month} ${h.changedAtUtc.hour}:${h.changedAtUtc.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'By ${h.changedByMemberName}${h.changedByCompanyName != null ? ' (${h.changedByCompanyName})' : ''}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary),
                                            ),
                                            if (h.remarks != null &&
                                                h.remarks!.isNotEmpty)
                                              Text(
                                                'Remarks: ${h.remarks!}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF334155),
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Action Buttons
              _buildActionButtons(order),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLifecycleTimeline(JobWorkOrderStatus current) {
    final bool isConfirmed = current == JobWorkOrderStatus.confirmed ||
        current == JobWorkOrderStatus.processing ||
        current == JobWorkOrderStatus.completed;
    final bool isProcessing = current == JobWorkOrderStatus.processing ||
        current == JobWorkOrderStatus.completed;
    final bool isCompleted = current == JobWorkOrderStatus.completed;

    if (current == JobWorkOrderStatus.cancelled ||
        current == JobWorkOrderStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.cancel_outlined,
                color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 8),
            Text(
              'Order has been ${current.label}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          _buildStep('1. Confirmed', isConfirmed, true),
          Expanded(
            child: Container(
              height: 2,
              color: isProcessing
                  ? const Color(0xFF15803D)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          _buildStep('2. Processing', isProcessing, isConfirmed),
          Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? const Color(0xFF15803D)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          _buildStep('3. Completed', isCompleted, isProcessing),
        ],
      ),
    );
  }

  Widget _buildStep(String title, bool isDone, bool isReached) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone
              ? const Color(0xFF15803D)
              : isReached
                  ? AppColors.primary
                  : const Color(0xFFE2E8F0),
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: isDone ? 14 : 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? const Color(0xFF15803D) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(JobWorkOrder order) {
    if (order.status == JobWorkOrderStatus.completed ||
        order.status == JobWorkOrderStatus.cancelled ||
        order.status == JobWorkOrderStatus.rejected) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        // Contractor actions
        if (order.isContractor) ...<Widget>[
          if (order.status == JobWorkOrderStatus.confirmed)
            AppButton.primary(
              text: 'Start Job Work Processing',
              isLoading: _isActionLoading,
              onPressed: () => _updateStatus(JobWorkOrderStatus.processing),
            ),
          if (order.status == JobWorkOrderStatus.processing)
            AppButton.primary(
              text: 'Mark Job Work as Delivered / Completed',
              isLoading: _isActionLoading,
              onPressed: () => _updateStatus(JobWorkOrderStatus.completed),
            ),
        ],

        // Buyer actions
        if (order.isBuyer) ...<Widget>[
          if (order.status == JobWorkOrderStatus.processing)
            AppButton.primary(
              text: 'Confirm Delivery & Mark Completed',
              isLoading: _isActionLoading,
              onPressed: () => _updateStatus(JobWorkOrderStatus.completed),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              minimumSize: const Size.fromHeight(42),
            ),
            onPressed: _isActionLoading ? null : _cancelOrder,
            child: const Text('Cancel Job Work Order'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(JobWorkOrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case JobWorkOrderStatus.confirmed:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
      case JobWorkOrderStatus.processing:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case JobWorkOrderStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case JobWorkOrderStatus.cancelled:
      case JobWorkOrderStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case JobWorkOrderStatus.pendingConfirmation:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

