import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/providers/rfq_provider.dart';

/// Modal sheet for suppliers to submit or revise a formal quotation.
class SubmitQuotationSheet extends ConsumerStatefulWidget {
  const SubmitQuotationSheet({
    super.key,
    required this.rfq,
    this.existingQuotation,
    this.onQuotationSubmitted,
  });

  final Rfq rfq;
  final Quotation? existingQuotation;
  final void Function(Quotation quotation)? onQuotationSubmitted;

  static Future<Quotation?> show(
    BuildContext context, {
    required Rfq rfq,
    Quotation? existingQuotation,
    void Function(Quotation quotation)? onQuotationSubmitted,
  }) {
    return showModalBottomSheet<Quotation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => SubmitQuotationSheet(
        rfq: rfq,
        existingQuotation: existingQuotation,
        onQuotationSubmitted: onQuotationSubmitted,
      ),
    );
  }

  @override
  ConsumerState<SubmitQuotationSheet> createState() => _SubmitQuotationSheetState();
}

class _SubmitQuotationSheetState extends ConsumerState<SubmitQuotationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _unitPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _shippingController;
  late final TextEditingController _deliveryTimeController;
  late final TextEditingController _termsController;
  late final TextEditingController _documentUrlController;

  DateTime? _validUntilDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final Quotation? prev = widget.existingQuotation ?? widget.rfq.latestQuotation;

    _unitPriceController = TextEditingController(
      text: prev != null ? prev.unitPrice.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(
      text: prev != null
          ? prev.quantity.toString()
          : widget.rfq.quantity.toString(),
    );
    _taxRateController = TextEditingController(
      text: prev != null
          ? prev.taxRatePercent.toString()
          : '18.0',
    );
    _shippingController = TextEditingController(
      text: prev != null
          ? prev.shippingCharges.toStringAsFixed(2)
          : '0.00',
    );
    _deliveryTimeController = TextEditingController(
      text: prev != null
          ? prev.estimatedDeliveryTime
          : '7 to 10 Business Days',
    );
    _termsController = TextEditingController(
      text: prev?.termsAndConditions ?? 'Payment: 30% advance, balance on delivery.',
    );
    _documentUrlController = TextEditingController(
      text: prev?.documentUrl ?? '',
    );

    _validUntilDate = prev != null && prev.validUntilUtc.isAfter(DateTime.now())
        ? prev.validUntilUtc
        : DateTime.now().add(const Duration(days: 30));

    // Listeners for live price recalculations
    _unitPriceController.addListener(_updateCalc);
    _quantityController.addListener(_updateCalc);
    _taxRateController.addListener(_updateCalc);
    _shippingController.addListener(_updateCalc);
  }

  void _updateCalc() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _quantityController.dispose();
    _taxRateController.dispose();
    _shippingController.dispose();
    _deliveryTimeController.dispose();
    _termsController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }

  double get _subtotal {
    final double price = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    final double qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    return price * qty;
  }

  double get _taxAmount {
    final double taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    return (_subtotal * taxRate) / 100.0;
  }

  double get _shipping {
    return double.tryParse(_shippingController.text.trim()) ?? 0.0;
  }

  double get _total => _subtotal + _taxAmount + _shipping;

  Future<void> _pickValidUntilDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntilDate ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() {
        _validUntilDate = picked;
      });
    }
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final double unitPrice = double.parse(_unitPriceController.text.trim());
      final double quantity = double.parse(_quantityController.text.trim());
      final double taxRate = double.tryParse(_taxRateController.text.trim()) ?? 18.0;
      final double shipping = double.tryParse(_shippingController.text.trim()) ?? 0.0;

      final SubmitQuotationRequest request = SubmitQuotationRequest(
        unitPrice: unitPrice,
        quantity: quantity,
        taxRatePercent: taxRate,
        shippingCharges: shipping,
        validUntilUtc: _validUntilDate,
        estimatedDeliveryTime: _deliveryTimeController.text.trim(),
        termsAndConditions: _termsController.text.trim().isNotEmpty
            ? _termsController.text.trim()
            : null,
        documentUrl: _documentUrlController.text.trim().isNotEmpty
            ? _documentUrlController.text.trim()
            : null,
      );

      final Quotation quote = await ref
          .read(receivedRfqsProvider.notifier)
          .submitQuotation(widget.rfq.id, request);

      if (mounted) {
        widget.onQuotationSubmitted?.call(quote);
        Navigator.of(context).pop(quote);
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
    final bool isRevision = widget.rfq.quotationsCount > 0;

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
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isRevision ? 'Submit Revised Quotation' : 'Submit Formal Quotation',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'For RFQ #${widget.rfq.rfqNumber} • ${widget.rfq.productName}',
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

                    // Pricing breakdown card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Calculated Subtotal',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textSecondary)),
                              Text('₹ ${_subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Tax (${_taxRateController.text.trim()}%)',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textSecondary)),
                              Text('₹ ${_taxAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Shipping Charges',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textSecondary)),
                              Text('₹ ${_shipping.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          const Divider(height: 16, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Total Quotation Amount',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark)),
                              Text('₹ ${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unit Price & Quantity Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Unit Price (₹) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('quoteUnitPriceField'),
                                controller: _unitPriceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (String? val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Unit price required';
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Quantity (${widget.rfq.unitOfMeasurement}) *',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('quoteQuantityField'),
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tax Rate & Shipping Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Tax Rate (%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('quoteTaxRateField'),
                                controller: _taxRateController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  hintText: '18.0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Shipping (₹)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('quoteShippingField'),
                                controller: _shippingController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Delivery Time
                    const Text(
                      'Estimated Delivery Lead Time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('quoteDeliveryTimeField'),
                      controller: _deliveryTimeController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 7 to 10 Business Days',
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

                    // Valid Until Picker
                    const Text(
                      'Quotation Validity (Valid Until) *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickValidUntilDate,
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
                              _validUntilDate != null
                                  ? formatRfqDate(_validUntilDate)
                                  : 'Select expiry date',
                              style: TextStyle(
                                fontSize: 14,
                                color: _validUntilDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                            const Icon(
                              Icons.event_available_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms and Conditions
                    const Text(
                      'Commercial Terms & Conditions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('quoteTermsField'),
                      controller: _termsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Payment milestones, freight terms (FOB/CIF), warranty...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document URL
                    const Text(
                      'Quotation PDF / Spec Sheet URL (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('quoteDocumentField'),
                      controller: _documentUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
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
                key: const Key('submitQuoteButton'),
                onPressed: _isSubmitting ? null : _submitQuotation,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : (isRevision ? 'Send Revised Quotation' : 'Submit Quotation to Buyer'),
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
