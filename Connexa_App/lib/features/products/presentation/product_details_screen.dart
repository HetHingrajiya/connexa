import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_badge.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/responsive_layout.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/presentation/widgets/add_edit_product_dialog.dart';
import 'package:connexa/features/products/presentation/widgets/product_image_gallery.dart';
import 'package:connexa/features/products/presentation/widgets/product_inquiry_sheet.dart';
import 'package:connexa/features/products/providers/product_provider.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/presentation/create_rfq_sheet.dart';

/// Dedicated Product Details Screen showcasing product specifications, swipeable image gallery,
/// verified supplier company credentials, and product inquiry workflow.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final int productId;
  final Product? initialProduct;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  Future<void> _handleEditProduct(Product product) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AddEditProductDialog(
        product: product,
        onSave:
            ({
              required String name,
              required String description,
              required String category,
              String? subCategory,
              List<String> tags = const <String>[],
              String? imageUrl,
              Map<String, String> specifications = const <String, String>{},
            }) async {
              final UpdateProductRequest req = UpdateProductRequest(
                name: name,
                description: description,
                category: category,
                subCategory: subCategory,
                tags: tags,
                imageUrl: imageUrl,
                specifications: specifications,
              );
              await ref
                  .read(myProductsProvider.notifier)
                  .editProduct(product.id, req);
              ref.invalidate(productDetailsProvider(product.id));
            },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDeleteProduct(Product product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmDeleteProductDetailsButton'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final bool success = await ref
          .read(myProductsProvider.notifier)
          .removeProduct(product.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product removed from showcase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  void _openInquirySheet(Product product) {
    ProductInquirySheet.show(
      context,
      product: product,
      onInquirySubmitted: (ProductInquiry inquiry) {
        // Refresh product details to show updated real inquiry count
        ref.invalidate(productDetailsProvider(product.id));
      },
    );
  }

  void _openRfqSheet(Product product) {
    CreateRfqSheet.show(
      context,
      product: product,
      onRfqCreated: (Rfq rfq) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RFQ #${rfq.rfqNumber} submitted successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.push('/rfqs/${rfq.id}'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final int currentMemberId = authState.profile?.memberId ?? 0;

    final AsyncValue<Product?> productAsync = ref.watch(
      productDetailsProvider(widget.productId),
    );

    // Prefer live data from API, falling back to initialProduct if loading
    final Product? product = productAsync.valueOrNull ?? widget.initialProduct;

    final bool isProductOwner =
        product != null &&
        (product.isOwner ||
            (currentMemberId > 0 && product.memberId == currentMemberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF062747), // Connexa Deep Navy
        elevation: 0,
        leading: IconButton(
          key: const Key('productDetailsBackButton'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back to products',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          if (product != null && isProductOwner) ...<Widget>[
            IconButton(
              key: const Key('productDetailsEditButton'),
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Edit Product',
              onPressed: () => _handleEditProduct(product),
            ),
            IconButton(
              key: const Key('productDetailsDeleteButton'),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Delete Product',
              onPressed: () => _handleDeleteProduct(product),
            ),
          ],
        ],
      ),
      bottomNavigationBar: product != null
          ? _buildBottomActionBar(product, isProductOwner)
          : null,
      body: SafeArea(
        child: productAsync.when(
          loading: () {
            if (product != null) {
              return _buildProductBody(product, isProductOwner);
            }
            return const Center(
              child: AppLoadingIndicator(message: 'Loading product details...'),
            );
          },
          error: (Object err, _) {
            if (product != null) {
              return _buildProductBody(product, isProductOwner);
            }
            return Center(
              child: AppErrorState(
                title: 'Product Unavailable',
                description: err.toString().replaceAll('Exception: ', ''),
                retryLabel: 'Retry',
                onRetry: () =>
                    ref.refresh(productDetailsProvider(widget.productId)),
              ),
            );
          },
          data: (Product? liveProduct) {
            final Product? resolved = liveProduct ?? product;
            if (resolved == null) {
              return Center(
                child: AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product Not Found',
                  description:
                      'This product may have been removed or is no longer active in the network.',
                  actionLabel: 'Back to Products',
                  onAction: () => context.pop(),
                ),
              );
            }
            return _buildProductBody(resolved, isProductOwner);
          },
        ),
      ),
    );
  }

  Widget _buildProductBody(Product product, bool isProductOwner) {
    return ResponsiveCenterBox(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      maxTabletWidth: AppSpacing.maxContentWidthTablet,
      maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productDetailsProvider(product.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Image Gallery / Hero Preview
              ProductImageGallery(
                images: product.allImages,
                productName: product.name,
                category: product.category,
                height: 230,
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Primary Information Card (Header, Category, Status, Tracking)
              _buildPrimaryInfoCard(product, isProductOwner),
              const SizedBox(height: AppSpacing.md),

              // 3. Highlighted Attributes Banner (Price, MOQ if present)
              if (_hasKeyAttributes(product)) ...<Widget>[
                _buildKeyAttributesCard(product),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. Product Description Card
              _buildDescriptionCard(product),
              const SizedBox(height: AppSpacing.md),

              // 5. Specifications and Attributes Card
              if (product.specifications.isNotEmpty) ...<Widget>[
                _buildSpecificationsCard(product),
                const SizedBox(height: AppSpacing.md),
              ],

              // 6. Tags and Capabilities Card
              if (product.tags.isNotEmpty) ...<Widget>[
                _buildTagsCard(product),
                const SizedBox(height: AppSpacing.md),
              ],

              // 7. Verified Supplier / Product Owner Information Card
              _buildSupplierInfoCard(product, isProductOwner),
              const SizedBox(height: AppSpacing.md),

              // 8. Related Products Section
              _buildRelatedProductsSection(product),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Primary Product Information Card
  Widget _buildPrimaryInfoCard(Product product, bool isProductOwner) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Product Name
          Text(
            product.name,
            key: const Key('productDetailsName'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category, Subcategory, and Status Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppBadge.primary(label: product.category, isPill: true),
              if (product.subCategory != null &&
                  product.subCategory!.trim().isNotEmpty)
                AppBadge.secondary(label: product.subCategory!, isPill: true),

              // PUBLISHED STATUS: Displayed ONLY for the Product Owner
              if (isProductOwner)
                Container(
                  key: const Key('productOwnerStatusBadge'),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        product.isActive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        size: 13,
                        color: product.isActive
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.isActive ? 'Published' : 'Draft / Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: product.isActive
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Real Tracking Metrics (Views & Inquiries)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${product.viewCount} views',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${product.inquiryCount} inquiries',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
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

  bool _hasKeyAttributes(Product product) {
    final Map<String, String> specs = product.specifications;
    return specs.containsKey('Price') ||
        specs.containsKey('MOQ') ||
        specs.containsKey('Minimum Order Quantity') ||
        specs.containsKey('Lead Time');
  }

  /// 3. Highlighted Attributes (MOQ, Price, Lead Time)
  Widget _buildKeyAttributesCard(Product product) {
    final Map<String, String> specs = product.specifications;
    final List<MapEntry<String, String>> keySpecs = specs.entries
        .where(
          (MapEntry<String, String> e) =>
              e.key.toLowerCase().contains('moq') ||
              e.key.toLowerCase().contains('price') ||
              e.key.toLowerCase().contains('lead time') ||
              e.key.toLowerCase().contains('minimum order'),
        )
        .take(3)
        .toList();

    if (keySpecs.isEmpty) return const SizedBox.shrink();

    return Row(
      children: keySpecs.map((MapEntry<String, String> e) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Soft Blue
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 4. Product Description Card
  Widget _buildDescriptionCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Product Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            product.description,
            key: const Key('productDetailsDescription'),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Specifications & Attributes Card
  Widget _buildSpecificationsCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Specifications & Attributes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: product.specifications.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((MapEntry<int, MapEntry<String, String>> item) {
                    final bool isEven = item.key % 2 == 0;
                    final MapEntry<String, String> spec = item.value;
                    return Container(
                      color: isEven ? const Color(0xFFF8FAFC) : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Text(
                              spec.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              spec.value,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Tags and Capabilities Card
  Widget _buildTagsCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.tag_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tags & Capabilities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: product.tags.map((String t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  '#$t',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 7. Supplier / Product Owner Information Card
  Widget _buildSupplierInfoCard(Product product, bool isProductOwner) {
    final String companyName =
        product.companyName ?? (product.isOwnerVerified ? 'Connexa Verified Supplier' : 'Connexa Supplier');
    final String ownerName = product.ownerName ?? 'Representative';
    final String location = product.location ?? 'Gujarat, India';
    final String businessType = product.businessType ?? 'Supplier';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Supplier Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.isOwnerVerified) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  key: const Key('supplierVerifiedBadge'),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Verified Member',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  companyName.isNotEmpty
                      ? companyName.substring(0, 1).toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            companyName,
                            key: const Key('productDetailsCompanyName'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (product.isOwnerVerified) ...<Widget>[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            key: Key('productDetailsVerifiedIcon'),
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$ownerName • $businessType',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            key: const Key('productDetailsLocation'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  /// 8. Related Products Section
  Widget _buildRelatedProductsSection(Product product) {
    final AsyncValue<List<Product>> relatedAsync = ref.watch(
      relatedProductsProvider(product.id),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Related Products',
                  key: Key('relatedProductsSectionTitle'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                key: const Key('relatedProductsViewAllButton'),
                onTap: () => context.push('/products'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View Catalog →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            product.industryName != null
                ? 'Similar offerings from ${product.industryName} suppliers'
                : 'Similar offerings from verified Connexa suppliers',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          relatedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: AppLoadingIndicator(
                  message: 'Finding related products...',
                ),
              ),
            ),
            error: (Object error, StackTrace stackTrace) => Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Could not load related products.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.refresh(relatedProductsProvider(product.id)),
                    child: const Text('Retry', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            data: (List<Product> products) {
              // Exclude currently viewed product and ensure uniqueness
              final List<Product> filtered = products
                  .where((Product p) => p.id != product.id && p.isActive)
                  .toList();

              if (filtered.isEmpty) {
                return Container(
                  key: const Key('relatedProductsEmptyState'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 30,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No other related products found',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Browse the catalog to discover products across all sectors.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 195,
                child: ListView.separated(
                  key: const Key('relatedProductsList'),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final Product item = filtered[index];
                    return _buildRelatedProductMiniCard(item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductMiniCard(Product item) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('relatedProductCard_${item.id}'),
          onTap: () {
            context.push('/products/${item.id}', extra: item);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Thumbnail
                Container(
                  height: 75,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imageUrl != null &&
                          item.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object err,
                                StackTrace? stack,
                              ) => const Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 26,
                                ),
                              ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF94A3B8),
                            size: 26,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                // Product Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Company
                Text(
                  item.companyName ?? 'Connexa Supplier',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                // Price highlight or View Details text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (item.displayPrice.isNotEmpty)
                      Flexible(
                        child: Text(
                          item.displayPrice,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    const Text(
                      'Details →',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sticky Bottom Action Bar with responsive layout and safe area protection
  Widget _buildBottomActionBar(Product product, bool isProductOwner) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: isProductOwner
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Owner Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      key: const Key('ownerEditProductButton'),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _handleEditProduct(product),
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('sendInquiryButton'),
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: const Text(
                          'Inquiry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _openInquirySheet(product),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        key: const Key('requestRfqButton'),
                        icon: const Icon(Icons.request_quote_rounded, size: 18),
                        label: const Text(
                          'Request Quote (RFQ)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openRfqSheet(product),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
