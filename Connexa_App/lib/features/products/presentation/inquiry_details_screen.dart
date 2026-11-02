import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/responsive_layout.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/providers/product_provider.dart';
import 'package:connexa/features/products/services/product_service.dart';

/// Dedicated Inquiry Details screen showing full verified trade inquiry data,
/// authorized contact details, quick navigation to product details, and
/// response composer for product owners.
class InquiryDetailsScreen extends ConsumerStatefulWidget {
  const InquiryDetailsScreen({
    super.key,
    required this.inquiryId,
    this.initialInquiry,
  });

  final int inquiryId;
  final ProductInquiry? initialInquiry;

  @override
  ConsumerState<InquiryDetailsScreen> createState() =>
      _InquiryDetailsScreenState();
}

class _InquiryDetailsScreenState extends ConsumerState<InquiryDetailsScreen> {
  final TextEditingController _responseController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmittingResponse = false;
  String? _submissionError;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResponse(ProductInquiry inquiry) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmittingResponse = true;
      _submissionError = null;
    });

    try {
      final ProductService service = ref.read(productServiceProvider);
      await service.respondToInquiry(
        inquiry.id,
        RespondToInquiryRequest(
          responseMessage: _responseController.text.trim(),
        ),
      );

      // Refresh providers
      ref.invalidate(inquiryDetailsProvider(widget.inquiryId));
      ref.invalidate(recentInquiriesProvider);
      ref.invalidate(sentInquiriesProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        _responseController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response sent successfully to buyer.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submissionError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingResponse = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProductInquiry?> inquiryAsync = ref.watch(
      inquiryDetailsProvider(widget.inquiryId),
    );

    final ProductInquiry? inquiry =
        inquiryAsync.valueOrNull ?? widget.initialInquiry;
    final int? currentMemberId =
        ref.watch(authProvider).user?.memberId ??
        ref.watch(authProvider).profile?.memberId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: const Color(0xFF062747), // Deep Navy
          elevation: 0,
          leading: IconButton(
            key: const Key('inquiryDetailsBackButton'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Inquiry Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          actions: <Widget>[
            if (inquiry != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(child: _buildStatusBadge(inquiry.status)),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: inquiryAsync.when(
          loading: () {
            if (inquiry != null) {
              return _buildContent(inquiry, currentMemberId);
            }
            return const Center(
              child: AppLoadingIndicator(message: 'Loading inquiry details...'),
            );
          },
          error: (Object error, _) {
            if (inquiry != null) {
              return _buildContent(inquiry, currentMemberId);
            }
            return Center(
              child: AppErrorState(
                title: 'Unable to Load Inquiry',
                description: error.toString(),
                onRetry: () =>
                    ref.invalidate(inquiryDetailsProvider(widget.inquiryId)),
              ),
            );
          },
          data: (ProductInquiry? liveInquiry) {
            final ProductInquiry? active = liveInquiry ?? inquiry;
            if (active == null) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 56,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Inquiry Not Found or Unauthorized',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You do not have permission to view this inquiry or it has been removed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back to Inquiries'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildContent(active, currentMemberId);
          },
        ),
      ),
    );
  }

  Widget _buildContent(ProductInquiry inquiry, int? currentMemberId) {
    final bool isRecipientOwner =
        currentMemberId != null && inquiry.recipientMemberId == currentMemberId;
    final bool isSenderBuyer =
        currentMemberId != null && inquiry.senderMemberId == currentMemberId;

    return ResponsiveCenterBox(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      maxTabletWidth: AppSpacing.maxContentWidthTablet,
      maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inquiryDetailsProvider(widget.inquiryId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Linked Product Banner
              _buildProductBanner(inquiry),
              const SizedBox(height: AppSpacing.md),

              // 2. Sender / Recipient Metadata Card
              _buildPartiesCard(inquiry, isRecipientOwner, isSenderBuyer),
              const SizedBox(height: AppSpacing.md),

              // 3. Authorized Contact Details Card (if authorized)
              if (inquiry.contactPhone != null ||
                  inquiry.contactEmail != null) ...<Widget>[
                _buildAuthorizedContactCard(inquiry),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. Quantity Requirement Card (if specified)
              if (inquiry.quantityRequirement != null &&
                  inquiry.quantityRequirement!.trim().isNotEmpty) ...<Widget>[
                _buildQuantityRequirementCard(inquiry.quantityRequirement!),
                const SizedBox(height: AppSpacing.md),
              ],

              // 5. Inquiry Message Card
              _buildMessageCard(inquiry),
              const SizedBox(height: AppSpacing.md),

              // 6. Response Section (Existing response or Response composer)
              _buildResponseSection(inquiry, isRecipientOwner, isSenderBuyer),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductBanner(ProductInquiry inquiry) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < 290;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _buildThumbnail(inquiry.productThumbnailUrl),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Inquiry For Product',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            inquiry.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('inquiryViewProductButton'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      context.push('/products/${inquiry.productId}');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Text(
                          'View Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: <Widget>[
              // Thumbnail
              _buildThumbnail(inquiry.productThumbnailUrl),
              const SizedBox(width: AppSpacing.md),
              // Product name and context
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Inquiry For Product',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inquiry.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // View Product Button
              ElevatedButton(
                key: const Key('inquiryViewProductButton'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  context.push('/products/${inquiry.productId}');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      'View Product',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      final String first = url.split(RegExp(r'[,;]'))[0].trim();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          first,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext ctx, Object err, _) =>
              _buildThumbnailFallback(),
        ),
      );
    }
    return _buildThumbnailFallback();
  }

  Widget _buildThumbnailFallback() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 24,
        color: Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildPartiesCard(
    ProductInquiry inquiry,
    bool isRecipientOwner,
    bool isSenderBuyer,
  ) {
    final String senderCompany = inquiry.senderCompanyName.isNotEmpty
        ? inquiry.senderCompanyName
        : inquiry.senderName;
    final String recipientCompany =
        inquiry.recipientCompanyName?.isNotEmpty == true
        ? inquiry.recipientCompanyName!
        : 'Product Supplier';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              const Text(
                'Inquiry Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                _formatDateTime(inquiry.createdAtUtc),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: AppSpacing.sm),

          // Sender Row
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Buyer / Sender',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '$senderCompany (${inquiry.senderName})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Recipient Row
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Supplier / Recipient',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      recipientCompany,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizedContactCard(ProductInquiry inquiry) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Subtle Emerald Green
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF16A34A),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Authorized Contact Information',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified member contact details authorized for direct communication regarding this inquiry.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF166534),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: Color(0xFFDCFCE7)),
          const SizedBox(height: AppSpacing.sm),

          // Phone
          if (inquiry.contactPhone != null && inquiry.contactPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inquiry.contactPhone!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    color: const Color(0xFF15803D),
                    tooltip: 'Copy Phone',
                    onPressed: () =>
                        _copyToClipboard(inquiry.contactPhone!, 'Phone number'),
                  ),
                ],
              ),
            ),

          // Email
          if (inquiry.contactEmail != null && inquiry.contactEmail!.isNotEmpty)
            Row(
              children: <Widget>[
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 16,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inquiry.contactEmail!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: const Color(0xFF15803D),
                  tooltip: 'Copy Email',
                  onPressed: () =>
                      _copyToClipboard(inquiry.contactEmail!, 'Email address'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityRequirementCard(String quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.inventory_2_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Text(
                  'Quantity Requirement:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  quantity,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(ProductInquiry inquiry) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Inquiry Message',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            inquiry.subject,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            inquiry.message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSection(
    ProductInquiry inquiry,
    bool isRecipientOwner,
    bool isSenderBuyer,
  ) {
    // Case 1: Already responded
    if (inquiry.responseMessage != null &&
        inquiry.responseMessage!.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(
                      Icons.reply_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Supplier Response',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                if (inquiry.respondedAtUtc != null)
                  Text(
                    _formatDateTime(inquiry.respondedAtUtc!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: Color(0xFFDCFCE7)),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              inquiry.responseMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF14532D),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Product Owner view and not responded yet -> Show response composer!
    if (isRecipientOwner) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  Icon(Icons.reply_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reply to Buyer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Provide your pricing, product availability, or lead time directly to the buyer.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('responseMessageField'),
                controller: _responseController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Enter your response message here...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a response message.';
                  }
                  return null;
                },
              ),
              if (_submissionError != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  _submissionError!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('sendResponseButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmittingResponse
                      ? null
                      : () => _handleSendResponse(inquiry),
                  icon: _isSubmittingResponse
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _isSubmittingResponse ? 'Sending...' : 'Send Response',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Case 3: Buyer view and no response yet
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: const <Widget>[
          Icon(
            Icons.hourglass_empty_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Awaiting response from product supplier. You will be notified once a response is submitted.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return switch (status.toLowerCase()) {
      'responded' => const AppBadge.success(
        label: 'Responded',
        isPill: true,
        fontSize: 11,
      ),
      'read' => const AppBadge.info(label: 'Read', isPill: true, fontSize: 11),
      _ => const AppBadge.warning(label: 'Pending', isPill: true, fontSize: 11),
    };
  }

  String _formatDateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    final List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String hour = local.hour.toString().padLeft(2, '0');
    final String min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} at $hour:$min';
  }
}
