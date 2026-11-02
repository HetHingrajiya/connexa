import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/providers/product_provider.dart';
import 'package:connexa/features/products/services/product_service.dart';

/// Interactive modal sheet/dialog for composing and submitting a formal B2B product inquiry.
class ProductInquirySheet extends ConsumerStatefulWidget {
  const ProductInquirySheet({
    super.key,
    required this.product,
    this.onInquirySubmitted,
  });

  final Product product;
  final void Function(ProductInquiry inquiry)? onInquirySubmitted;

  static Future<bool?> show(
    BuildContext context, {
    required Product product,
    void Function(ProductInquiry inquiry)? onInquirySubmitted,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => ProductInquirySheet(
        product: product,
        onInquirySubmitted: onInquirySubmitted,
      ),
    );
  }

  @override
  ConsumerState<ProductInquirySheet> createState() =>
      _ProductInquirySheetState();
}

class _ProductInquirySheetState extends ConsumerState<ProductInquirySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _subjectController;
  late final TextEditingController _quantityController;
  late final TextEditingController _messageController;
  late final TextEditingController _contactController;

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _quickTopics = const <String>[
    'Price & MOQ Quote',
    'Bulk Order Request',
    'Custom Specification',
    'Sample Request',
  ];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: 'Inquiry regarding ${widget.product.name}',
    );
    _quantityController = TextEditingController();
    _messageController = TextEditingController();
    _contactController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final AuthState authState = ref.read(authProvider);
    final MemberProfile? member = authState.profile;

    final String contactPhone = _contactController.text.trim().isNotEmpty
        ? _contactController.text.trim()
        : (member != null ? '${member.countryCode}${member.phoneNumber}' : '');

    final String contactEmail = member?.email ?? '';

    final CreateProductInquiryRequest req = CreateProductInquiryRequest(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      quantityRequirement: _quantityController.text.trim().isNotEmpty
          ? _quantityController.text.trim()
          : null,
      contactPhone: contactPhone.isNotEmpty ? contactPhone : null,
      contactEmail: contactEmail.isNotEmpty ? contactEmail : null,
    );

    try {
      final ProductService service = ref.read(productServiceProvider);
      final ProductInquiry inquiry = await service.sendInquiry(
        widget.product.id,
        req,
      );

      // Invalidate relevant providers to refresh live counters
      ref.invalidate(recentInquiriesProvider);
      ref.invalidate(sentInquiriesProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productDetailsProvider(widget.product.id));

      if (widget.onInquirySubmitted != null) {
        widget.onInquirySubmitted!(inquiry);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(true);

        // Show confirmation banner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Inquiry sent successfully to ${widget.product.companyName ?? "seller"}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final MemberProfile? member = authState.profile;

    final String senderName = member?.fullName ?? 'Verified Member';
    final String senderCompany =
        member?.profileDetails?['companyName']?.toString() ??
        member?.profileDetails?['tradingName']?.toString() ??
        member?.profileDetails?['workName']?.toString() ??
        'Connexa Partner';

    final String targetCompany =
        widget.product.companyName ?? 'Verified Supplier';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Send Product Inquiry',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Direct B2B message to $targetCompany',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('closeInquirySheetButton'),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Error banner if any
                      if (_errorMessage != null) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Linked Product Overview Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDBEAFE),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  widget.product.imageUrl != null &&
                                      widget.product.imageUrl!.trim().isNotEmpty
                                  ? Image.network(
                                      widget.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            BuildContext c,
                                            Object o,
                                            StackTrace? s,
                                          ) => const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Color(0xFF2563EB),
                                            size: 24,
                                          ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF2563EB),
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.product.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.product.category} • Supplier: $targetCompany',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Sender Authentication Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Inquiring as: $senderName ($senderCompany)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Quick Topic Selection Chips
                      const Text(
                        'Select Inquiry Topic',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickTopics.map((String topic) {
                          final bool isSelected = _subjectController.text
                              .contains(topic);
                          return ActionChip(
                            label: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            backgroundColor: isSelected
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _subjectController.text =
                                    '$topic - ${widget.product.name}';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Subject Field
                      TextFormField(
                        key: const Key('inquirySubjectField'),
                        controller: _subjectController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Subject *',
                          hintText: 'e.g. Price & MOQ Quote',
                          prefixIcon: Icon(
                            Icons.topic_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please provide a subject.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Quantity or Requirement Field
                      TextFormField(
                        key: const Key('inquiryQuantityField'),
                        controller: _quantityController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Required Quantity / Volume (Optional)',
                          hintText: 'e.g. 500 Units / 10 Tons / Monthly order',
                          prefixIcon: Icon(
                            Icons.format_list_numbered_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Inquiry Message Field
                      TextFormField(
                        key: const Key('inquiryMessageField'),
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Inquiry Message *',
                          hintText:
                              'Describe your requirement, required specifications, delivery timeline, or questions for the supplier...',
                          alignLabelWithHint: true,
                        ),
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Inquiry message cannot be empty.';
                          }
                          if (val.trim().length < 5) {
                            return 'Please write at least 5 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Additional Preferred Contact Notes
                      TextFormField(
                        key: const Key('inquiryContactField'),
                        controller: _contactController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText:
                              'Alternate Phone / Instructions (Optional)',
                          hintText: member != null
                              ? '${member.countryCode}${member.phoneNumber}'
                              : '+91 ...',
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Verified Contact Info Notice
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Your verified profile credentials (${member?.email ?? "Email"} / ${member != null ? "${member.countryCode}${member.phoneNumber}" : "Phone"}) are automatically shared with the seller.',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit & Cancel Buttons
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              key: const Key('submitInquiryButton'),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: Text(
                                _isSubmitting ? 'Sending...' : 'Send Inquiry',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isSubmitting ? null : _submitInquiry,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
