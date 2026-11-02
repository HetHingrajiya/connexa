import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/features/orders/models/order_models.dart';
import 'package:connexa/features/orders/providers/order_provider.dart';

/// Modal bottom sheet for a Buyer to create an Order from an Accepted Quotation.
class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({
    super.key,
    required this.quotationId,
    required this.quotationNumber,
    required this.productName,
    required this.quantity,
    required this.unitOfMeasurement,
    required this.unitPrice,
    required this.subtotal,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.shippingCharges,
    required this.totalAmount,
    this.initialDeliveryAddress,
    this.initialLeadTime,
  });

  final int quotationId;
  final String quotationNumber;
  final String productName;
  final double quantity;
  final String unitOfMeasurement;
  final double unitPrice;
  final double subtotal;
  final double taxRatePercent;
  final double taxAmount;
  final double shippingCharges;
  final double totalAmount;
  final String? initialDeliveryAddress;
  final String? initialLeadTime;

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  final TextEditingController _notesController = TextEditingController();
  DateTime? _expectedDeliveryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.initialDeliveryAddress ?? '');
    _expectedDeliveryDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final request = CreateOrderRequest(
        quotationId: widget.quotationId,
        deliveryAddress: _addressController.text.trim(),
        expectedDeliveryDateUtc: _expectedDeliveryDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final Order order =
          await ref.read(myOrdersProvider.notifier).createOrder(request);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/orders/${order.id}');
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: <Widget>[
                    const Icon(Icons.shopping_cart_checkout_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Place B2B Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Converting accepted quote #${widget.quotationNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Financial Snapshot
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${widget.quantity.toStringAsFixed(0)} ${widget.unitOfMeasurement}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Unit Price: ₹${widget.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            'Subtotal: ₹${widget.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Tax (${widget.taxRatePercent}%): ₹${widget.taxAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            'Shipping: ₹${widget.shippingCharges.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Total Order Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            '₹${widget.totalAmount.toStringAsFixed(2)}',
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
                const SizedBox(height: 16),

                // Delivery Address
                const Text(
                  'Delivery Address *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('orderDeliveryAddressField'),
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter complete warehouse or delivery site address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Delivery address is required';
                    }
                    if (val.trim().length < 5) {
                      return 'Address must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Expected Delivery Date Picker
                const Text(
                  'Expected Delivery Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  key: const Key('orderExpectedDatePicker'),
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _expectedDeliveryDate != null
                              ? formatOrderDate(_expectedDeliveryDate)
                              : 'Select expected delivery date',
                          style: TextStyle(
                            fontSize: 13,
                            color: _expectedDeliveryDate != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                const Text(
                  'Order Notes (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('orderNotesField'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Any special packing or gate entry instructions',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('confirmPlaceOrderButton'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Confirm & Create Order',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for a Supplier to Ship an Order (Carrier & Tracking).
class ShipOrderDialog extends StatefulWidget {
  const ShipOrderDialog({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  State<ShipOrderDialog> createState() => _ShipOrderDialogState();
}

class _ShipOrderDialogState extends State<ShipOrderDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _carrierController = TextEditingController();
  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void dispose() {
    _carrierController.dispose();
    _trackingController.dispose();
    _urlController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: <Widget>[
          const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Ship Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enter shipment details for ${widget.orderNumber}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text('Carrier / Logistics Partner *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('shipCarrierField'),
                controller: _carrierController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blue Dart, FedEx, Delhivery',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) return 'Carrier name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Tracking / AWB Number *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('shipTrackingField'),
                controller: _trackingController,
                decoration: InputDecoration(
                  hintText: 'e.g. 982348123',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) return 'Tracking number is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Tracking URL (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('shipUrlField'),
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://track.bluedart.com/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Dispatch Remarks (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('shipRemarksField'),
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Handed over to carrier in sealed box...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('submitShipOrderButton'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                ShipOrderRequest(
                  carrierName: _carrierController.text.trim(),
                  trackingNumber: _trackingController.text.trim(),
                  trackingUrl: _urlController.text.trim().isNotEmpty
                      ? _urlController.text.trim()
                      : null,
                  remarks: _remarksController.text.trim().isNotEmpty
                      ? _remarksController.text.trim()
                      : null,
                ),
              );
            }
          },
          child: const Text('Confirm Shipment'),
        ),
      ],
    );
  }
}

/// Generic reason dialog for Cancellation or Rejection.
class OrderReasonDialog extends StatefulWidget {
  const OrderReasonDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.actionButtonText,
    this.isDestructive = true,
  });

  final String title;
  final String hintText;
  final String actionButtonText;
  final bool isDestructive;

  @override
  State<OrderReasonDialog> createState() => _OrderReasonDialogState();
}

class _OrderReasonDialogState extends State<OrderReasonDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              key: const Key('orderReasonField'),
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a reason';
                }
                if (val.trim().length < 5) {
                  return 'Reason must be at least 5 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          key: const Key('submitOrderReasonButton'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDestructive ? AppColors.error : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_reasonController.text.trim());
            }
          },
          child: Text(widget.actionButtonText),
        ),
      ],
    );
  }
}
