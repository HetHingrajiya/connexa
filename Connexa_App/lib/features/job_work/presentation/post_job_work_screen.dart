import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/core/widgets/app_text_field.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';
import 'package:connexa/features/job_work/services/job_work_service.dart';

class PostJobWorkScreen extends ConsumerStatefulWidget {
  const PostJobWorkScreen({super.key});

  @override
  ConsumerState<PostJobWorkScreen> createState() => _PostJobWorkScreenState();
}

class _PostJobWorkScreenState extends ConsumerState<PostJobWorkScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _processController = TextEditingController(text: 'CNC Milling');
  final TextEditingController _machineTypeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _axesController = TextEditingController();
  final TextEditingController _toleranceController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: 'Pieces');
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(text: 'Gujarat, India');
  final TextEditingController _deliveryTermsController = TextEditingController();

  MaterialResponsibility _materialResponsibility = MaterialResponsibility.buyerSupplied;
  DateTime? _targetCompletionDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<JobWorkAttachment> _uploadedAttachments = <JobWorkAttachment>[];
  bool _isUploadingFile = false;

  static const List<String> _standardProcesses = <String>[
    'CNC Milling',
    'CNC Turning',
    'Fiber Laser Cutting',
    'Sheet Metal Fabrication',
    'Injection Molding',
    'Die Casting',
    'Gear Hobbing',
    'Wire EDM',
    'Precision Surface Grinding',
    'TIG/MIG Welding',
    'Powder Coating & Anodizing',
    'Other Specialized Machining',
  ];

  static const List<String> _standardUnits = <String>[
    'Pieces',
    'Kg',
    'Meters',
    'Sets',
    'Lots',
    'Assemblies',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _processController.dispose();
    _machineTypeController.dispose();
    _capacityController.dispose();
    _axesController.dispose();
    _toleranceController.dispose();
    _materialController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _deliveryTermsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDrawing() async {
    final TextEditingController nameController = TextEditingController();
    String selectedDocType = '2D CAD Blueprint (PDF)';

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Attach Technical Drawing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Select or specify drawing specification to attach to this requirement.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDocType,
                    decoration: const InputDecoration(
                      labelText: 'Drawing Document Type',
                      isDense: true,
                    ),
                    items: const <String>[
                      '2D CAD Blueprint (PDF)',
                      '3D CAD Model (STEP/IGES)',
                      'Component Specification (PDF)',
                      'Machining Tolerance Sheet (PDF)',
                    ].map((String t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setModalState(() => selectedDocType = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'File Name (Optional)',
                      hintText: 'e.g. impeller_drawing_rev2.pdf',
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
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Attach File'),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceed != true) return;

    final String finalName = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()
        : '${selectedDocType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}_sample.pdf';

    setState(() {
      _isUploadingFile = true;
      _errorMessage = null;
    });

    try {
      final List<int> sampleBytes = utf8.encode(
        'Connexa Technical Drawing / Blueprint Attachment: $selectedDocType - $finalName',
      );
      final JobWorkAttachment attachment = await ref
          .read(jobWorkServiceProvider)
          .uploadAttachmentBytes(sampleBytes, finalName);

      if (mounted) {
        setState(() {
          _uploadedAttachments.add(attachment);
          _isUploadingFile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _errorMessage = 'Failed to upload attachment.';
        });
      }
    }
  }

  Future<void> _submitRequirement() async {
    if (!_formKey.currentState!.validate()) return;

    final double? qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive quantity.');
      return;
    }

    final double? budget = _budgetController.text.trim().isNotEmpty
        ? double.tryParse(_budgetController.text.trim())
        : null;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final JobWorkRequirement req = await ref
          .read(jobWorkServiceProvider)
          .createRequirement(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            industryId: 1, // Default Precision Engineering & Manufacturing
            jobWorkProcess: _processController.text.trim(),
            machineType: _machineTypeController.text.trim().isEmpty
                ? null
                : _machineTypeController.text.trim(),
            requiredMachineCapacity: _capacityController.text.trim().isEmpty
                ? null
                : _capacityController.text.trim(),
            requiredTolerance: _toleranceController.text.trim().isEmpty
                ? null
                : _toleranceController.text.trim(),
            materialType: _materialController.text.trim().isEmpty
                ? null
                : _materialController.text.trim(),
            materialResponsibility: _materialResponsibility,
            quantity: qty,
            unitOfMeasurement: _unitController.text.trim(),
            targetBudget: budget,
            location: _locationController.text.trim(),
            deliveryTerms: _deliveryTermsController.text.trim().isEmpty
                ? null
                : _deliveryTermsController.text.trim(),
            targetCompletionDateUtc: _targetCompletionDate,
            attachmentIds: _uploadedAttachments.map((JobWorkAttachment a) => a.id).toList(),
          );

      // Refresh providers
      ref.read(jobWorkMarketplaceProvider.notifier).loadMarketplace(isRefresh: true);
      ref.read(myJobWorkRequirementsProvider.notifier).loadMyRequirements();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Requirement #${req.requirementNumber} published successfully!'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
        context.pushReplacement('/job-works/${req.id}');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to publish requirement. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Job Work Requirement'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (_errorMessage != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 1. Core Info Card
              _buildSectionCard(
                title: 'Job Requirement Details',
                icon: Icons.assignment_outlined,
                children: <Widget>[
                  AppTextField(
                    controller: _titleController,
                    label: 'Job Title *',
                    hintText: 'e.g., CNC Milling of 4-Axis Aluminium Manifolds',
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Detailed Scope & Technical Requirements *',
                    hintText: 'Describe geometry, finish, testing, inspection standards...',
                    maxLines: 4,
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Manufacturing & Machine Specs Card
              _buildSectionCard(
                title: 'Manufacturing & Machine Specs',
                icon: Icons.precision_manufacturing_rounded,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _processController.text,
                    decoration: InputDecoration(
                      labelText: 'Manufacturing Process *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _standardProcesses
                        .map((String p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(p, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (String? val) {
                      if (val != null) setState(() => _processController.text = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _machineTypeController,
                    label: 'Preferred Machine Type',
                    hintText: 'e.g., VMC 4-Axis, 5-Axis CNC, 6kW Fiber Laser',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          controller: _capacityController,
                          label: 'Bed / Envelope Size',
                          hintText: 'e.g., 800 x 500 mm',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _toleranceController,
                          label: 'Required Tolerance',
                          hintText: 'e.g., +/- 0.01 mm',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Material & Responsibility Card
              _buildSectionCard(
                title: 'Raw Material & Supply',
                icon: Icons.inventory_2_outlined,
                children: <Widget>[
                  AppTextField(
                    controller: _materialController,
                    label: 'Material Grade / Spec',
                    hintText: 'e.g., Aluminium 6061-T6, SS 304, MS Plate IS 2062',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Material Supply Responsibility *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<MaterialResponsibility>(
                    segments: const <ButtonSegment<MaterialResponsibility>>[
                      ButtonSegment<MaterialResponsibility>(
                        value: MaterialResponsibility.buyerSupplied,
                        label: Text('Buyer Supplied', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment<MaterialResponsibility>(
                        value: MaterialResponsibility.contractorSupplied,
                        label: Text('Contractor', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment<MaterialResponsibility>(
                        value: MaterialResponsibility.sharedOrNegotiable,
                        label: Text('Negotiable', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: <MaterialResponsibility>{_materialResponsibility},
                    onSelectionChanged: (Set<MaterialResponsibility> set) {
                      setState(() => _materialResponsibility = set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Commercial & Delivery Card
              _buildSectionCard(
                title: 'Quantity & Commercial Terms',
                icon: Icons.currency_rupee_rounded,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: _quantityController,
                          label: 'Quantity *',
                          hintText: 'e.g., 500',
                          keyboardType: TextInputType.number,
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _unitController.text,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _standardUnits
                              .map((String u) => DropdownMenuItem<String>(
                                    value: u,
                                    child: Text(u, style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) setState(() => _unitController.text = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          controller: _budgetController,
                          label: 'Target Budget (₹, Optional)',
                          hintText: 'e.g., 200000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _locationController,
                          label: 'Delivery Location *',
                          hintText: 'e.g., Rajkot, Gujarat',
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                    title: Text(
                      _targetCompletionDate == null
                          ? 'Select Target Completion Date'
                          : 'Target Date: ${_targetCompletionDate!.day}/${_targetCompletionDate!.month}/${_targetCompletionDate!.year}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 15)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _targetCompletionDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Engineering Drawings & Attachments Card
              _buildSectionCard(
                title: 'Drawings & CAD Files',
                icon: Icons.attach_file_rounded,
                children: <Widget>[
                  const Text(
                    'Upload 2D drawings (PDF, DWG, DXF) or 3D CAD models (STEP, IGES, STL). Max 25MB.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    icon: _isUploadingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(_isUploadingFile ? 'Uploading...' : 'Attach Drawing / Image'),
                    onPressed: _isUploadingFile ? null : _pickAndUploadDrawing,
                  ),
                  if (_uploadedAttachments.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    ..._uploadedAttachments.map((JobWorkAttachment a) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.insert_drive_file_outlined,
                              color: AppColors.primary, size: 20),
                          title: Text(a.originalFileName,
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(a.formattedFileSize,
                              style: const TextStyle(fontSize: 10)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              setState(() => _uploadedAttachments.remove(a));
                            },
                          ),
                        )),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton.primary(
                text: 'Publish Job Work Requirement',
                height: 48,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitRequirement,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
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
              children: <Widget>[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

