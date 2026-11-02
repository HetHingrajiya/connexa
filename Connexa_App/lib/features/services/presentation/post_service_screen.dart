import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/providers/services_providers.dart';
import 'package:connexa/features/services/services/services_marketplace_service.dart';

class PostServiceScreen extends ConsumerStatefulWidget {
  const PostServiceScreen({super.key, this.serviceId});

  final int? serviceId;

  @override
  ConsumerState<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends ConsumerState<PostServiceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _startingPriceController = TextEditingController();
  final TextEditingController _priceUnitController = TextEditingController();
  final TextEditingController _turnaroundTimeController = TextEditingController();
  final TextEditingController _coverageAreaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _certificationsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedServiceType = 'On-Site';
  String _selectedPricingModel = 'Quote-Based';
  bool _isLoading = false;
  bool _isFetchingInitial = false;

  final List<String> _popularCategories = <String>[
    'CNC Machining',
    'Industrial Maintenance',
    'Machine Repair',
    'Fabrication',
    'Industrial Design',
    'Installation',
    'Consultancy',
    'Automation Services',
    'Electrical Services',
    'Technical Support',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _loadExistingService(widget.serviceId!);
    } else {
      _categoryController.text = _popularCategories.first;
    }
  }

  Future<void> _loadExistingService(int id) async {
    setState(() => _isFetchingInitial = true);
    try {
      final ServiceDetail detail = await ref
          .read(servicesMarketplaceServiceProvider)
          .getServiceById(id);

      _titleController.text = detail.title;
      _descriptionController.text = detail.description;
      _categoryController.text = detail.serviceCategory;
      _selectedServiceType = detail.serviceType;
      _selectedPricingModel = detail.pricingModel;
      if (detail.startingPrice != null) {
        _startingPriceController.text = detail.startingPrice!.toString();
      }
      _priceUnitController.text = detail.priceUnit ?? '';
      _turnaroundTimeController.text = detail.turnaroundTime ?? '';
      _coverageAreaController.text = detail.coverageArea ?? '';
      _locationController.text = detail.location ?? '';
      _certificationsController.text = detail.certifications ?? '';
      if (detail.yearsOfExperience != null) {
        _experienceController.text = detail.yearsOfExperience!.toString();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load existing service details.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingInitial = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _startingPriceController.dispose();
    _priceUnitController.dispose();
    _turnaroundTimeController.dispose();
    _coverageAreaController.dispose();
    _locationController.dispose();
    _certificationsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final double? startingPrice = _startingPriceController.text.isNotEmpty
          ? double.tryParse(_startingPriceController.text.trim())
          : null;
      final int? experience = _experienceController.text.isNotEmpty
          ? int.tryParse(_experienceController.text.trim())
          : null;

      if (widget.serviceId != null) {
        final UpdateServiceRequest req = UpdateServiceRequest(
          title: _titleController.text,
          description: _descriptionController.text,
          serviceCategory: _categoryController.text,
          serviceType: _selectedServiceType,
          pricingModel: _selectedPricingModel,
          startingPrice: startingPrice,
          priceUnit: _priceUnitController.text.isNotEmpty
              ? _priceUnitController.text
              : null,
          turnaroundTime: _turnaroundTimeController.text.isNotEmpty
              ? _turnaroundTimeController.text
              : null,
          coverageArea: _coverageAreaController.text.isNotEmpty
              ? _coverageAreaController.text
              : null,
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          certifications: _certificationsController.text.isNotEmpty
              ? _certificationsController.text
              : null,
          yearsOfExperience: experience,
        );

        await ref
            .read(servicesMarketplaceServiceProvider)
            .updateService(widget.serviceId!, req);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(myServicesProvider.notifier).loadMyServices();
          ref.read(servicesMarketplaceProvider.notifier).loadServices(refresh: true);
          context.pop();
        }
      } else {
        final CreateServiceRequest req = CreateServiceRequest(
          title: _titleController.text,
          description: _descriptionController.text,
          serviceCategory: _categoryController.text,
          serviceType: _selectedServiceType,
          pricingModel: _selectedPricingModel,
          startingPrice: startingPrice,
          priceUnit: _priceUnitController.text.isNotEmpty
              ? _priceUnitController.text
              : null,
          turnaroundTime: _turnaroundTimeController.text.isNotEmpty
              ? _turnaroundTimeController.text
              : null,
          coverageArea: _coverageAreaController.text.isNotEmpty
              ? _coverageAreaController.text
              : null,
          location: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          certifications: _certificationsController.text.isNotEmpty
              ? _certificationsController.text
              : null,
          yearsOfExperience: experience,
        );

        await ref
            .read(servicesMarketplaceServiceProvider)
            .createService(req);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service published successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(myServicesProvider.notifier).loadMyServices();
          ref.read(servicesMarketplaceProvider.notifier).loadServices(refresh: true);
          context.pop();
        }
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.serviceId != null;

    if (_isFetchingInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Service')),
        body: const Center(
          child: AppLoadingIndicator(message: 'Loading service...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Business Service' : 'Offer a Business Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: 700,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),

                  // Basic Information Card
                  AppCard(
                    title: 'Basic Service Information',
                    subtitle: 'Define the core offering and industrial category',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppTextField(
                          controller: _titleController,
                          label: 'Service Title *',
                          hintText: 'e.g. 5-Axis Precision CNC Machining & Tooling',
                          validator: (String? val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Title is required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Service Category *',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _popularCategories.contains(_categoryController.text)
                              ? _categoryController.text
                              : _popularCategories.first,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          items: _popularCategories
                              .map((String cat) => DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _categoryController.text = val);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'Detailed Service Description *',
                          hintText:
                              'Describe your machinery, tolerances, capabilities, materials handled, and deliverable standards...',
                          maxLines: 4,
                          validator: (String? val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Description is required'
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Delivery & Commercial Card
                  AppCard(
                    title: 'Delivery Mode & Pricing',
                    subtitle: 'Set up work locations and commercial terms',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Delivery Mode',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: <String>[
                            'On-Site',
                            'Remote',
                            'Workshop',
                            'Hybrid'
                          ].map((String mode) {
                            final bool isSel = _selectedServiceType == mode;
                            return ChoiceChip(
                              label: Text(mode),
                              selected: isSel,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() => _selectedServiceType = mode);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Pricing Model',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: <String>[
                            'Quote-Based',
                            'Fixed Quote',
                            'Hourly Rate',
                            'Daily Rate',
                            'Project Based'
                          ].map((String model) {
                            final bool isSel = _selectedPricingModel == model;
                            return ChoiceChip(
                              label: Text(model),
                              selected: isSel,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() => _selectedPricingModel = model);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: AppTextField(
                                controller: _startingPriceController,
                                label: 'Starting Price (₹)',
                                hintText: 'e.g. 5000',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                controller: _priceUnitController,
                                label: 'Unit / Period',
                                hintText: 'e.g. /hour, /part',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _turnaroundTimeController,
                          label: 'Estimated Turnaround Time',
                          hintText: 'e.g. 2-3 Days, 24 Hours Emergency Response',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Location & Qualifications Card
                  AppCard(
                    title: 'Coverage, Location & Credentials',
                    subtitle: 'Geographical availability and quality accreditations',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppTextField(
                          controller: _coverageAreaController,
                          label: 'Service Coverage Area',
                          hintText: 'e.g. Pan India, Within 100 km, Gujarat Region',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _locationController,
                          label: 'Base Location / City',
                          hintText: 'e.g. Ahmedabad, Gujarat',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _certificationsController,
                          label: 'Quality Certifications',
                          hintText: 'e.g. ISO 9001:2015, CE, AS9100D',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _experienceController,
                          label: 'Years of Experience',
                          hintText: 'e.g. 12',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Button
                  AppButton.primary(
                    key: const Key('submitServiceButton'),
                    text: isEditing ? 'Save Changes' : 'Publish Service',
                    isLoading: _isLoading,
                    isFullWidth: true,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
