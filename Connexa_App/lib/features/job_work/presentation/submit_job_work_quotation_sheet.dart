import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/core/widgets/app_text_field.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';

class SubmitJobWorkQuotationSheet extends ConsumerStatefulWidget {
  const SubmitJobWorkQuotationSheet({
    super.key,
    required this.requirement,
  });

  final JobWorkRequirement requirement;

  static Future<bool?> show(BuildContext context, JobWorkRequirement requirement) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => SubmitJobWorkQuotationSheet(requirement: requirement),
    );
  }

  @override
  ConsumerState<SubmitJobWorkQuotationSheet> createState() =>
      _SubmitJobWorkQuotationSheetState();
}

class _SubmitJobWorkQuotationSheetState
    extends ConsumerState<SubmitJobWorkQuotationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _unitRateController;
  late final TextEditingController _quantityController;
  final TextEditingController _otherChargesController = TextEditingController(text: '0');
  final TextEditingController _taxRateController = TextEditingController(text: '18');
  final TextEditingController _leadTimeController = TextEditingController(text: '10');
  final TextEditingController _machineProposedController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _unitRateController = TextEditingController();
    _quantityController = TextEditingController(
      text: widget.requirement.quantity.truncateToDouble() == widget.requirement.quantity
          ? widget.requirement.quantity.toInt().toString()
          : widget.requirement.quantity.toString(),
    );

    _unitRateController.addListener(_calculateTotals);
    _quantityController.addListener(_calculateTotals);
    _otherChargesController.addListener(_calculateTotals);
    _taxRateController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _unitRateController.dispose();
    _quantityController.dispose();
    _otherChargesController.dispose();
    _taxRateController.dispose();
    _leadTimeController.dispose();
    _machineProposedController.dispose();
    _remarksController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    final double rate = double.tryParse(_unitRateController.text.trim()) ?? 0.0;
    final double qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final double other = double.tryParse(_otherChargesController.text.trim()) ?? 0.0;
    final double taxPercent = double.tryParse(_taxRateController.text.trim()) ?? 18.0;

    final double sub = rate * qty;
    final double tax = sub * (taxPercent / 100.0);
    final double tot = sub + tax + other;

    setState(() {
      _subtotal = sub;
      _taxAmount = tax;
      _totalAmount = tot;
    });
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    final double? rate = double.tryParse(_unitRateController.text.trim());
    final double? qty = double.tryParse(_quantityController.text.trim());
    final int? leadTime = int.tryParse(_leadTimeController.text.trim());

    if (rate == null || rate <= 0) {
      setState(() => _errorMessage = 'Offered rate must be greater than zero.');
      return;
    }
    if (qty == null || qty <= 0) {
      setState(() => _errorMessage = 'Quantity must be greater than zero.');
      return;
    }
    if (leadTime == null || leadTime <= 0) {
      setState(() => _errorMessage = 'Lead time must be at least 1 day.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final double other = double.tryParse(_otherChargesController.text.trim()) ?? 0.0;
    final double taxPercent = double.tryParse(_taxRateController.text.trim()) ?? 18.0;

    final bool success = await ref
        .read(jobWorkDetailsProvider(widget.requirement.id).notifier)
        .submitQuotation(
          offeredUnitPrice: rate,
          quantity: qty,
          taxRatePercent: taxPercent,
          otherCharges: other,
          leadTimeDays: leadTime,
          machineProposed: _machineProposedController.text.trim().isEmpty
              ? null
              : _machineProposedController.text.trim(),
          technicalRemarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
          termsAndConditions: _termsController.text.trim().isEmpty
              ? null
              : _termsController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = ref
              .read(jobWorkDetailsProvider(widget.requirement.id))
              .errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
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
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Submit Quotation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'For Requirement #${widget.requirement.requirementNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_errorMessage != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Pricing Fields
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _unitRateController,
                    label: 'Offered Rate (₹ / ${widget.requirement.unitOfMeasurement}) *',
                    hintText: 'e.g., 450',
                    keyboardType: TextInputType.number,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _quantityController,
                    label: 'Quantity *',
                    keyboardType: TextInputType.number,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _otherChargesController,
                    label: 'Tooling / Other Charges (₹)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _taxRateController,
                    label: 'GST Rate (%)',
                    hintText: '18',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Lead Time & Machine
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _leadTimeController,
                    label: 'Lead Time (Days) *',
                    hintText: '10',
                    keyboardType: TextInputType.number,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _machineProposedController,
                    label: 'Machine Proposed',
                    hintText: 'e.g., Haas VF-4',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(
              controller: _remarksController,
              label: 'Technical Remarks & Capabilities',
              hintText: 'Describe machine capacity, fixture capability, quality inspection tools...',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),

            AppTextField(
              controller: _termsController,
              label: 'Commercial Terms',
              hintText: 'e.g., Delivery ex-works, payment within 15 days upon QC approval...',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('GST Amount:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('₹${_taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Total Quotation Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            AppButton.primary(
              text: 'Submit Formal Quotation',
              height: 46,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitQuotation,
            ),
          ],
        ),
      ),
    );
  }
}

