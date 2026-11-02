import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/features/orders/models/order_models.dart';
import 'package:connexa/features/orders/providers/order_provider.dart';
import 'package:connexa/features/orders/presentation/order_dialogs.dart';

/// Screen displaying complete details, financial breakdown, shipment tracking,
/// status audit timeline, and role-based actions for an Order.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isProcessingAction = false;

  Future<void> _refresh() async {
    ref.invalidate(orderDetailsProvider(widget.orderId));
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return const AppBadge(
          label: 'Pending Confirmation',
          variant: AppBadgeVariant.warning,
          icon: Icon(Icons.hourglass_top_rounded, size: 12),
        );
      case OrderStatus.confirmed:
        return const AppBadge(
          label: 'Confirmed',
          variant: AppBadgeVariant.info,
          icon: Icon(Icons.check_circle_outline_rounded, size: 12),
        );
      case OrderStatus.processing:
        return const AppBadge(
          label: 'Processing',
          variant: AppBadgeVariant.primary,
          icon: Icon(Icons.precision_manufacturing_outlined, size: 12),
        );
      case OrderStatus.shipped:
        return const AppBadge(
          label: 'Shipped',
          variant: AppBadgeVariant.secondary,
          icon: Icon(Icons.local_shipping_outlined, size: 12),
        );
      case OrderStatus.delivered:
        return const AppBadge(
          label: 'Completed',
          variant: AppBadgeVariant.success,
          icon: Icon(Icons.task_alt_rounded, size: 12),
        );
      case OrderStatus.cancelled:
        return const AppBadge(
          label: 'Cancelled',
          variant: AppBadgeVariant.neutral,
          icon: Icon(Icons.cancel_outlined, size: 12),
        );
      case OrderStatus.rejected:
        return const AppBadge(
          label: 'Rejected',
          variant: AppBadgeVariant.error,
          icon: Icon(Icons.highlight_off_rounded, size: 12),
        );
    }
  }

  // --- Action Handlers ---

  Future<void> _handleConfirmOrder(Order order) async {
    final String? remarks = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => const OrderReasonDialog(
        title: 'Confirm Order',
        hintText: 'Enter internal notes or production confirmation remarks (Optional)',
        actionButtonText: 'Confirm Order',
        isDestructive: false,
      ),
    );

    // If cancelled dialog
    if (remarks == null && !mounted) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(receivedOrdersProvider.notifier).confirmOrder(
            order.id,
            ConfirmOrderRequest(remarks: remarks),
          );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleRejectOrder(Order order) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => const OrderReasonDialog(
        title: 'Reject Order',
        hintText: 'Provide the reason for rejecting this order *',
        actionButtonText: 'Reject Order',
        isDestructive: true,
      ),
    );

    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(receivedOrdersProvider.notifier).rejectOrder(
            order.id,
            RejectOrderRequest(reason: reason),
          );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleProcessOrder(Order order) async {
    setState(() => _isProcessingAction = true);
    try {
      await ref.read(receivedOrdersProvider.notifier).processOrder(
            order.id,
            const ProcessOrderRequest(remarks: 'Order moved to processing/manufacturing.'),
          );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order is now in processing.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleShipOrder(Order order) async {
    final ShipOrderRequest? request = await showDialog<ShipOrderRequest>(
      context: context,
      builder: (BuildContext ctx) => ShipOrderDialog(orderNumber: order.orderNumber),
    );

    if (request == null) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(receivedOrdersProvider.notifier).shipOrder(order.id, request);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as shipped! Tracking details updated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleDeliverOrder(Order order) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Mark Order Completed'),
        content: Text(
          order.isBuyer
              ? 'Are you sure you have received all items for order #${order.orderNumber}? This will mark the order as Completed.'
              : 'Confirm that client has received the items for order #${order.orderNumber} to mark it as Completed?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirmDeliveryButton'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Completed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingAction = true);
    try {
      if (order.isSupplier) {
        await ref.read(receivedOrdersProvider.notifier).deliverOrder(
              order.id,
              const DeliverOrderRequest(remarks: 'Delivered/handed over to client destination.'),
            );
      } else {
        await ref.read(myOrdersProvider.notifier).deliverOrder(
              order.id,
              const DeliverOrderRequest(remarks: 'Client received items and confirmed completion.'),
            );
      }
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as Completed!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleCancelOrder(Order order) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => const OrderReasonDialog(
        title: 'Cancel Order',
        hintText: 'Enter reason for cancellation *',
        actionButtonText: 'Cancel Order',
        isDestructive: true,
      ),
    );

    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isProcessingAction = true);
    try {
      await ref.read(myOrdersProvider.notifier).cancelOrder(
            order.id,
            CancelOrderRequest(reason: reason),
          );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Order> orderAsync = ref.watch(orderDetailsProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          orderAsync.value?.orderNumber ?? 'Order Details',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: <Widget>[
          if (orderAsync.value != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.textSecondary),
              tooltip: 'Copy Order Number',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: orderAsync.value!.orderNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order number copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace? stack) => Center(
          child: AppErrorState(
            title: 'Failed to load order',
            description: error.toString().replaceFirst('Exception: ', ''),
            onRetry: _refresh,
          ),
        ),
        data: (Order order) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Top Overview Banner
                  _buildOverviewCard(order),
                  const SizedBox(height: 14),

                  // Product Details Card
                  _buildProductCard(order),
                  const SizedBox(height: 14),

                  // Commercial & Financial Breakdown Card
                  _buildFinancialBreakdownCard(order),
                  const SizedBox(height: 14),

                  // Delivery & Shipping Information Card
                  _buildDeliveryAndShippingCard(order),
                  const SizedBox(height: 14),

                  // Status History & Audit Timeline Card
                  _buildTimelineCard(order),
                  const SizedBox(height: 24),

                  // Action Buttons Bar
                  _buildActionBar(order),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed on ${formatOrderDate(order.createdAtUtc)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Buyer Company',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.buyerCompanyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.buyerFullName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Supplier Company',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.supplierCompanyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.supplierFullName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quantity: ${order.quantity.toStringAsFixed(0)} ${order.unitOfMeasurement}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatOrderCurrency(order.subtotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  'Quotation Ref: #${order.quotationNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Text(
                  'RFQ Ref: #${order.rfqNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBreakdownCard(Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Commercial Terms & Payment Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Unit Price (${order.unitOfMeasurement})',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatOrderCurrency(order.unitPrice),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatOrderCurrency(order.subtotal),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Taxes / GST (${order.taxRatePercent}%)',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatOrderCurrency(order.taxAmount),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Shipping & Logistics',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatOrderCurrency(order.shippingCharges),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Total Order Value',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        formatOrderCurrency(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (order.termsAndConditionsSnapshot != null &&
                order.termsAndConditionsSnapshot!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Agreed Terms & Conditions:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                order.termsAndConditionsSnapshot!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAndShippingCard(Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Delivery & Logistics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Delivery Address',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Expected Delivery: ${order.expectedDeliveryDateUtc != null ? formatOrderDate(order.expectedDeliveryDateUtc) : 'Not specified'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.notes_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buyer Notes: ${order.notes}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],

            // Shipment Tracking Info (when Shipped or Delivered)
            if (order.carrierName != null) ...<Widget>[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Carrier: ${order.carrierName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Text(
                          'Tracking / AWB: ${order.trackingNumber}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: order.trackingNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tracking number copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    if (order.shippedAtUtc != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        'Shipped on: ${formatOrderDateTime(order.shippedAtUtc)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Order order) {
    final List<OrderStatusHistory> history = order.statusHistory;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Order Audit & Status Timeline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${history.length} events',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (history.isEmpty)
              const Text(
                'No status events recorded.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (BuildContext ctx, int i) => const SizedBox(height: 12),
                itemBuilder: (BuildContext ctx, int index) {
                  final OrderStatusHistory item = history[index];
                  final OrderStatus stepStatus = OrderStatus.fromString(item.newStatus);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: stepStatus.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(stepStatus.icon, size: 16, color: stepStatus.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  stepStatus.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  formatOrderDate(item.changedAtUtc),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Updated by ${item.changedByMemberName}${item.changedByCompanyName != null ? ' (${item.changedByCompanyName})' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (item.remarks != null && item.remarks!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                item.remarks!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(Order order) {
    if (_isProcessingAction) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isBuyer = order.isBuyer;
    final bool isSupplier = order.isSupplier;

    // Supplier Actions
    if (isSupplier) {
      switch (order.status) {
        case OrderStatus.pendingConfirmation:
          return Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  key: const Key('rejectOrderButton'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleRejectOrder(order),
                  child: const Text('Reject Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('confirmOrderButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleConfirmOrder(order),
                  child: const Text('Confirm Order'),
                ),
              ),
            ],
          );

        case OrderStatus.confirmed:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('startProcessingButton'),
                  icon: const Icon(Icons.precision_manufacturing_outlined, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleProcessOrder(order),
                  label: const Text('Start Processing Order'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('supplierMarkDeliveredButton'),
                  icon: const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.success),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleDeliverOrder(order),
                  label: const Text('Direct Delivery / Mark Completed'),
                ),
              ),
            ],
          );

        case OrderStatus.processing:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('shipOrderButton'),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleShipOrder(order),
                  label: const Text('Enter Shipping Details & Mark Shipped'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('supplierMarkDeliveredButton'),
                  icon: const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.success),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleDeliverOrder(order),
                  label: const Text('Mark Order as Completed'),
                ),
              ),
            ],
          );

        case OrderStatus.shipped:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('supplierMarkDeliveredButton'),
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _handleDeliverOrder(order),
              label: const Text('Confirm Order Completed'),
            ),
          );

        case OrderStatus.delivered:
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Completed',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );

        case OrderStatus.cancelled:
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.cancel_outlined, color: AppColors.textSecondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );

        case OrderStatus.rejected:
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.highlight_off_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Declined / Rejected',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
      }
    }

    // Buyer Actions
    if (isBuyer) {
      switch (order.status) {
        case OrderStatus.pendingConfirmation:
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('buyerCancelOrderButton'),
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _handleCancelOrder(order),
              label: const Text('Cancel Order'),
            ),
          );

        case OrderStatus.confirmed:
        case OrderStatus.processing:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('buyerConfirmReceiptButton'),
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleDeliverOrder(order),
                  label: const Text('Confirm Order Received & Completed'),
                ),
              ),
              if (order.status == OrderStatus.confirmed) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('buyerCancelOrderButton'),
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _handleCancelOrder(order),
                    label: const Text('Cancel Order'),
                  ),
                ),
              ],
            ],
          );

        case OrderStatus.shipped:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('buyerConfirmReceiptButton'),
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _handleDeliverOrder(order),
              label: const Text('Confirm Order Received & Completed'),
            ),
          );

        case OrderStatus.delivered:
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Completed',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );

        case OrderStatus.cancelled:
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.cancel_outlined, color: AppColors.textSecondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );

        default:
          return const SizedBox.shrink();
      }
    }

    return const SizedBox.shrink();
  }
}
