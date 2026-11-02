import 'package:flutter/material.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/features/products/models/product_models.dart';

/// Comprehensive modal dialog for creating or editing products with full schema support.
class AddEditProductDialog extends StatefulWidget {
  const AddEditProductDialog({super.key, this.product, required this.onSave});

  final Product? product;
  final Future<void> Function({
    required String name,
    required String description,
    required String category,
    String? subCategory,
    List<String> tags,
    String? imageUrl,
    Map<String, String> specifications,
  })
  onSave;

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _tagsController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _priceController;
  late final TextEditingController _moqController;

  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _suggestedCategories = <String>[
    'Fasteners & Bolts',
    'Industrial Hardware',
    'CNC Machining & Tooling',
    'Raw Materials & Metals',
    'Valves & Actuators',
    'Electrical & Automation',
    'Precision Bushings & Bearings',
    'Pumps & Compressors',
    'Packaging & Industrial Supplies',
    'Engineering Services',
  ];

  @override
  void initState() {
    super.initState();
    final Product? p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _subCategoryController = TextEditingController(text: p?.subCategory ?? '');
    _tagsController = TextEditingController(text: p?.tags.join(', ') ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');

    final Map<String, String> specs = p?.specifications ?? <String, String>{};
    _priceController = TextEditingController(text: specs['Price'] ?? '');
    _moqController = TextEditingController(text: specs['MOQ'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _moqController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final List<String> tags = _tagsController.text
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();

      final Map<String, String> specs = <String, String>{};
      if (_priceController.text.trim().isNotEmpty) {
        specs['Price'] = _priceController.text.trim();
      }
      if (_moqController.text.trim().isNotEmpty) {
        specs['MOQ'] = _moqController.text.trim();
      }

      // Preserve any other existing specifications when editing
      if (widget.product?.specifications != null) {
        widget.product!.specifications.forEach((String k, String v) {
          if (!specs.containsKey(k)) {
            specs[k] = v;
          }
        });
      }

      await widget.onSave(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _categoryController.text.trim(),
        subCategory: _subCategoryController.text.trim().isNotEmpty
            ? _subCategoryController.text.trim()
            : null,
        tags: tags,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        specifications: specs,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isEdit ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_errorMessage != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Product Name
                TextFormField(
                  key: const Key('productFormName'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Hexagonal Brass Fasteners M8',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category with suggestions
                TextFormField(
                  key: const Key('productFormCategory'),
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    hintText: 'e.g. Fasteners & Bolts',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onSelected: (String cat) {
                        _categoryController.text = cat;
                      },
                      itemBuilder: (BuildContext ctx) => _suggestedCategories
                          .map(
                            (String cat) => PopupMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  validator: (String? val) => val == null || val.trim().isEmpty
                      ? 'Category is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subcategory
                TextFormField(
                  key: const Key('productFormSubCategory'),
                  controller: _subCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (optional)',
                    hintText: 'e.g. Industrial Bolts',
                    prefixIcon: Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Description
                TextFormField(
                  key: const Key('productFormDescription'),
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText:
                        'Describe technical specifications, materials, and capabilities...',
                    alignLabelWithHint: true,
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (val.trim().length < 10) {
                      return 'Please provide at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Specifications (Price & MOQ)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        key: const Key('productFormPrice'),
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price / Unit',
                          hintText: 'e.g. ₹18.50 / pc',
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        key: const Key('productFormMoq'),
                        controller: _moqController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Order (MOQ)',
                          hintText: 'e.g. 1000 Pcs',
                          prefixIcon: Icon(Icons.layers_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Tags
                TextFormField(
                  key: const Key('productFormTags'),
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g. Brass, CNC, IS:1364, Exporter',
                    prefixIcon: Icon(Icons.tag_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Image URL with Live Preview
                TextFormField(
                  key: const Key('productFormImageUrl'),
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.image_outlined, size: 20),
                    suffixIcon: _imageUrlController.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() => _imageUrlController.clear());
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (_imageUrlController.text.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (BuildContext ctx, Object err, StackTrace? st) =>
                              const Center(
                                child: Text(
                                  'Preview unavailable for this URL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('productFormSubmitButton'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isEdit ? 'Save Changes' : 'Publish Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

/// View Product Details Modal Dialog
class ViewProductDialog extends StatelessWidget {
  const ViewProductDialog({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (product.imageUrl != null &&
                  product.imageUrl!.isNotEmpty) ...<Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext ctx, Object err, StackTrace? st) =>
                            const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  AppBadge.primary(label: product.category, isPill: true),
                  if (product.subCategory != null &&
                      product.subCategory!.isNotEmpty)
                    AppBadge.secondary(
                      label: product.subCategory!,
                      isPill: true,
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isActive ? 'Published' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.isActive
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (product.specifications.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Specifications',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: product.specifications.entries
                        .map(
                          (MapEntry<String, String> e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (product.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: product.tags
                      .map(
                        (String t) =>
                            AppBadge.secondary(label: t, isPill: true),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.viewCount} Views',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.inquiryCount} Inquiries',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
