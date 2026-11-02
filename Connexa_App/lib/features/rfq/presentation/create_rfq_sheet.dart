import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/providers/rfq_provider.dart';

/// Modal sheet for creating a formal B2B Request for Quotation (RFQ).
class CreateRfqSheet extends ConsumerStatefulWidget {
  const CreateRfqSheet({
    super.key,
    required this.product,
    this.onRfqCreated,
  });

  final Product product;
  final void Function(Rfq rfq)? onRfqCreated;

  static Future<Rfq?> show(
    BuildContext context, {
    required Product product,
    void Function(Rfq rfq)? onRfqCreated,
  }) {
    return showModalBottomSheet<Rfq>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => CreateRfqSheet(
        product: product,
        onRfqCreated: onRfqCreated,
      ),
    );
  }

  @override
  ConsumerState<CreateRfqSheet> createState() => _CreateRfqSheetState();
}

class _CreateRfqSheetState extends ConsumerState<CreateRfqSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _quantityController;
  late final TextEditingController _targetPriceController;
  late final TextEditingController _locationController;
  late final TextEditingController _specsController;
  late final TextEditingController _attachmentController;

  String _selectedUom = 'Pieces';
  DateTime? _selectedDeliveryDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _uomOptions = <String>[
    'Pieces',
    'Kg',
    'Metric Tonnes',
    'Bales',
    'Meters',
    'Boxes',
    'Liters',
    'Units',
  ];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _targetPriceController = TextEditingController();
    _locationController = TextEditingController(text: 'Gujarat, India');
    _specsController = TextEditingController();
    _attachmentController = TextEditingController();
    _selectedDeliveryDate = DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _targetPriceController.dispose();
    _locationController.dispose();
    _specsController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? now.add(const Duration(days: 14)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _submitRfq() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final double quantity = double.parse(_quantityController.text.trim());
      final double? targetPrice = _targetPriceController.text.trim().isNotEmpty
          ? double.tryParse(_targetPriceController.text.trim())
          : null;

      final CreateRfqRequest request = CreateRfqRequest(
        productId: widget.product.id,
        quantity: quantity,
        unitOfMeasurement: _selectedUom,
        targetPrice: targetPrice,
        requiredDeliveryDateUtc: _selectedDeliveryDate,
        deliveryLocation: _locationController.text.trim(),
        additionalSpecifications: _specsController.text.trim().isNotEmpty
            ? _specsController.text.trim()
            : null,
        attachmentUrl: _attachmentController.text.trim().isNotEmpty
            ? _attachmentController.text.trim()
            : null,
        title: 'RFQ for ${widget.product.name}',
      );

      final Rfq rfq = await ref.read(myRfqsProvider.notifier).createRfq(request);

      if (mounted) {
        widget.onRfqCreated?.call(rfq);
        Navigator.of(context).pop(rfq);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Request for Quotation (RFQ)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_errorMessage != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity and UOM Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Quantity *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('rfqQuantityField'),
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 500',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (String? val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Quantity required';
                                  }
                                  final double? numVal = double.tryParse(val.trim());
                                  if (numVal == null || numVal <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Unit (UOM) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: const Key('rfqUomField'),
                                initialValue: _selectedUom,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                ),
                                items: _uomOptions
                                    .map((String uom) => DropdownMenuItem<String>(
                                          value: uom,
                                          child: Text(
                                            uom,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (String? val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedUom = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target Price
                    const Text(
                      'Target Unit Price (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('rfqTargetPriceField'),
                      controller: _targetPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 150.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Required Delivery Date Picker
                    const Text(
                      'Required Delivery Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDeliveryDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _selectedDeliveryDate != null
                                  ? formatRfqDate(_selectedDeliveryDate)
                                  : 'Select required date',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDeliveryDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Location
                    const Text(
                      'Delivery Location / Address *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('rfqLocationField'),
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'City, State or Factory Address',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      validator: (String? val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Delivery location is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Additional Specifications
                    const Text(
                      'Technical / Commercial Specifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('rfqSpecsField'),
                      controller: _specsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Specify packaging, material grades, lab certificates, or custom tolerances...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attachment / Link
                    const Text(
                      'Attachment URL / Specification Link',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('rfqAttachmentField'),
                      controller: _attachmentController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('submitRfqButton'),
                onPressed: _isSubmitting ? null : _submitRfq,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Submitting RFQ...' : 'Submit RFQ to Supplier',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
