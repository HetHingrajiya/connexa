import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/providers/services_providers.dart';
import 'package:connexa/features/services/services/services_marketplace_service.dart';

class ServiceInquirySheet extends ConsumerStatefulWidget {
  const ServiceInquirySheet({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerName,
  });

  final int serviceId;
  final String serviceTitle;
  final String providerName;

  static Future<bool?> show(
    BuildContext context, {
    required int serviceId,
    required String serviceTitle,
    required String providerName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => ServiceInquirySheet(
        serviceId: serviceId,
        serviceTitle: serviceTitle,
        providerName: providerName,
      ),
    );
  }

  @override
  ConsumerState<ServiceInquirySheet> createState() =>
      _ServiceInquirySheetState();
}

class _ServiceInquirySheetState extends ConsumerState<ServiceInquirySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  String _selectedUrgency = 'Normal';
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _scopeController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final double? budget = _budgetController.text.isNotEmpty
          ? double.tryParse(_budgetController.text.trim())
          : null;

      final CreateServiceInquiryRequest req = CreateServiceInquiryRequest(
        serviceId: widget.serviceId,
        subject: _subjectController.text,
        requirementDescription: _descController.text,
        scopeOfWork: _scopeController.text.isNotEmpty
            ? _scopeController.text
            : null,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        preferredStartDate: _preferredDate,
        estimatedBudget: budget,
        urgency: _selectedUrgency,
      );

      final ServiceInquiry inquiry = await ref
          .read(servicesMarketplaceServiceProvider)
          .createInquiry(req);

      ref.read(serviceInquiriesProvider.notifier).loadInquiries();

      if (mounted) {
        Navigator.of(context).pop(true);
        context.push('/service-inquiries/${inquiry.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + keyboardHeight,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Send Service Inquiry',
                          style: AppTextStyles.headlineSmall,
                        ),
                        Text(
                          'To: ${widget.providerName} • ${widget.serviceTitle}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // Subject
              AppTextField(
                controller: _subjectController,
                label: 'Inquiry Subject *',
                hintText: 'e.g. Requirement for 500 pcs CNC turning & threading',
                validator: (String? val) =>
                    val == null || val.trim().isEmpty
                        ? 'Subject is required'
                        : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              AppTextField(
                controller: _descController,
                label: 'Requirement Description *',
                hintText:
                    'Provide details on materials, tolerances, scope, breakdown conditions...',
                maxLines: 3,
                validator: (String? val) =>
                    val == null || val.trim().isEmpty
                        ? 'Description is required'
                        : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Scope of Work
              AppTextField(
                controller: _scopeController,
                label: 'Scope of Work (Optional)',
                hintText: 'e.g. Installation, testing, calibration, warranty',
              ),
              const SizedBox(height: AppSpacing.md),

              // Location & Budget
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _locationController,
                      label: 'Work Site Location',
                      hintText: 'e.g. Pune, MH',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _budgetController,
                      label: 'Target Budget (₹)',
                      hintText: 'e.g. 50000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Urgency & Preferred Date
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Urgency',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUrgency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'Normal',
                              child: Text('Normal'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Urgent',
                              child: Text('Urgent'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Emergency',
                              child: Text('Emergency'),
                            ),
                          ],
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _selectedUrgency = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Preferred Start Date',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            _preferredDate != null
                                ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                                : 'Select Date',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton.primary(
                key: const Key('submitServiceInquiryButton'),
                text: 'Send Inquiry to Provider',
                isLoading: _isSubmitting,
                trailingIcon: const Icon(Icons.send_rounded, size: 18),
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
