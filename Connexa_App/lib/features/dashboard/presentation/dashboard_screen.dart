import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/providers/product_provider.dart';

/// Responsive, authentic Member Dashboard screen for Connexa.
/// Displays real member profile, business statistics, my products catalog,
/// recommended companies, and recent product inquiries.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _handleRefresh() async {
    await ref.read(authProvider.notifier).restoreSession();
    await ref.read(myProductsProvider.notifier).refresh();
    await ref.read(recommendedCompaniesProvider.notifier).refresh();
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(recentInquiriesProvider);
  }

  void _showAddEditProductModal([Product? existingProduct]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return _AddEditProductDialog(
          product: existingProduct,
          onSave: (CreateProductRequest req) async {
            if (existingProduct == null) {
              await ref.read(myProductsProvider.notifier).addProduct(req);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product published successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              await ref
                  .read(myProductsProvider.notifier)
                  .editProduct(
                    existingProduct.id,
                    UpdateProductRequest(
                      name: req.name,
                      description: req.description,
                      category: req.category,
                      subCategory: req.subCategory,
                      tags: req.tags,
                      imageUrl: req.imageUrl,
                      specifications: req.specifications,
                    ),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _showProductDetailsModal(Product product) {
    context.push('/products/${product.id}', extra: product);
  }

  void _showDeleteConfirmationModal(Product product) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('confirmDeleteProductButton'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final bool deleted = await ref
                    .read(myProductsProvider.notifier)
                    .removeProduct(product.id);
                if (mounted && deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product removed from catalog.'),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInquiryDetailsModal(ProductInquiry inquiry) {
    context.push('/inquiries/${inquiry.id}', extra: inquiry);
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);
    final MemberProfile? profile = authState.profile;
    final AsyncValue<DashboardStats> statsAsync = ref.watch(
      dashboardStatsProvider,
    );
    final AsyncValue<List<Product>> productsAsync = ref.watch(
      myProductsProvider,
    );
    final AsyncValue<List<RecommendedCompany>> recommendedAsync = ref.watch(
      recommendedCompaniesProvider,
    );
    final AsyncValue<List<ProductInquiry>> inquiriesAsync = ref.watch(
      recentInquiriesProvider,
    );

    final DashboardStats stats =
        statsAsync.valueOrNull ?? const DashboardStats();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(context, profile, stats),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: authState.isLoading && profile == null
            ? const Center(
                child: AppLoadingIndicator(message: 'Loading dashboard...'),
              )
            : authState.errorMessage != null && profile == null
            ? Center(
                child: AppErrorState(
                  title: 'Unable to Load Dashboard',
                  description: authState.errorMessage!,
                  onRetry: _handleRefresh,
                ),
              )
            : ResponsiveCenterBox(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                maxTabletWidth: AppSpacing.maxContentWidthTablet,
                maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xxxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // 1. Member Profile Summary Card
                        if (profile != null) ...<Widget>[
                          _buildMemberSummaryCard(context, profile),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 2. Business Statistics
                        _buildBusinessStatsSection(stats),
                        const SizedBox(height: AppSpacing.lg),

                        // 3. My Products — Most Important Section
                        _buildMyProductsSection(productsAsync),
                        const SizedBox(height: AppSpacing.lg),

                        // 4. Recommended Companies
                        _buildRecommendedCompaniesSection(recommendedAsync),
                        const SizedBox(height: AppSpacing.lg),

                        // 5. Recent Product Inquiries
                        _buildRecentInquiriesSection(inquiriesAsync),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// 1. Premium Top App Bar (#062747 dark navy)
  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    MemberProfile? profile,
    DashboardStats stats,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF062747),
      elevation: 0,
      toolbarHeight: 60,
      titleSpacing: AppSpacing.sm,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Text(
                  'Connexa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          key: const Key('dashboardOrdersButton'),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: const EdgeInsets.all(7),
          icon: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 21),
          tooltip: 'B2B Orders',
          onPressed: () => context.push('/orders'),
        ),
        IconButton(
          key: const Key('dashboardRfqsButton'),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: const EdgeInsets.all(7),
          icon: const Icon(Icons.request_quote_outlined, color: Colors.white, size: 21),
          tooltip: 'B2B RFQs & Quotes',
          onPressed: () => context.push('/rfqs'),
        ),
        IconButton(
          key: const Key('dashboardSearchButton'),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: const EdgeInsets.all(7),
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 21),
          tooltip: 'Search Businesses & Products',
          onPressed: () => context.push('/directory'),
        ),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            IconButton(
              key: const Key('dashboardNotificationsButton'),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: const EdgeInsets.all(7),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 21,
              ),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
            if (stats.unreadNotificationsCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  key: const Key('notificationsUnreadBadge'),
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    stats.unreadNotificationsCount > 9
                        ? '9+'
                        : '${stats.unreadNotificationsCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm, left: 2),
          child: InkWell(
            key: const Key('dashboardAvatarButton'),
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  profile?.fullName.isNotEmpty == true
                      ? profile!.fullName.substring(0, 1).toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Member Profile Summary Card (Compact White Card)
  Widget _buildMemberSummaryCard(BuildContext context, MemberProfile profile) {
    final Map<String, dynamic>? details = profile.profileDetails;
    final String companyName =
        details?['companyName']?.toString() ??
        details?['tradingName']?.toString() ??
        details?['workName']?.toString() ??
        profile.fullName;

    final String location =
        details?['workCoverage']?.toString() ??
        details?['serviceCoverage']?.toString() ??
        'Gujarat, India';

    final String memberType = _formatProfileType(profile.primaryProfileType);

    return InkWell(
      onTap: () => context.push('/profile'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName.substring(0, 1).toUpperCase()
                    : 'M',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          profile.fullName,
                          key: const Key('dashboardMemberName'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0D9488), // Teal verified badge
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${profile.memberId}',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          memberType,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Business Statistics (4 Compact Stat Cards)
  Widget _buildBusinessStatsSection(DashboardStats stats) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < 600;

        final Widget card1 = _buildStatCard(
          icon: Icons.inventory_2_outlined,
          value: '${stats.myProductsCount}',
          label: 'My Products',
          key: const Key('statMyProducts'),
        );
        final Widget card2 = _buildStatCard(
          icon: Icons.visibility_outlined,
          value: '${stats.companyViewsCount}',
          label: 'Company Views',
          key: const Key('statCompanyViews'),
        );
        final Widget card3 = _buildStatCard(
          icon: Icons.bar_chart_rounded,
          value: '${stats.productViewsCount}',
          label: 'Product Views',
          key: const Key('statProductViews'),
        );
        final Widget card4 = _buildStatCard(
          icon: Icons.person_add_outlined,
          value: '${stats.connectionRequestsCount}',
          label: 'Connection Requests',
          key: const Key('statConnectionRequests'),
        );

        if (isNarrow) {
          // 2x2 grid for mobile
          return Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: card1),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(child: card3),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        // Horizontal row for wider screens
        return Row(
          children: <Widget>[
            Expanded(child: card1),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: card2),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: card3),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Key key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft blue surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 4. My Products — Most Important Section
  Widget _buildMyProductsSection(AsyncValue<List<Product>> productsAsync) {
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
          // Section Header
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      'My Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Showcase your products and services to the network',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ElevatedButton.icon(
                key: const Key('dashboardAddProductButton'),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Add Product',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _showAddEditProductModal(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Content
          productsAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: AppLoadingIndicator(message: 'Loading products...'),
              ),
            ),
            error: (Object err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: AppErrorState(
                title: 'Failed to load products',
                description: err.toString(),
                onRetry: () => ref.read(myProductsProvider.notifier).refresh(),
              ),
            ),
            data: (List<Product> products) {
              if (products.isEmpty) {
                return _buildEmptyProductsState();
              }

              return SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final Product product = products[index];
                    return _buildProductCard(product);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'No products added yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Showcase your first product to reach more businesses.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            key: const Key('emptyStateAddProductButton'),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Product', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => _showAddEditProductModal(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showProductDetailsModal(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Product Image Slot
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext ctx,
                                Object err,
                                StackTrace? stack,
                              ) {
                                return _buildImagePlaceholder(product.category);
                              },
                        )
                      : _buildImagePlaceholder(product.category),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Name and 3-dot menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 120),
                          onSelected: (String action) {
                            switch (action) {
                              case 'view':
                                _showProductDetailsModal(product);
                                break;
                              case 'edit':
                                _showAddEditProductModal(product);
                                break;
                              case 'delete':
                                _showDeleteConfirmationModal(product);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext ctx) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'view',
                                  child: Text(
                                    'View Product',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text(
                                    'Edit Product',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(
                                    'Delete Product',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    Text(
                      product.subCategory ?? product.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Tags
                    if (product.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: product.tags.take(2).map((String tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                    // Views and Inquiries count bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.visibility_outlined,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.viewCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.inquiryCount}',
                              style: const TextStyle(
                                fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF94A3B8),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            category,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 5. Recommended Companies Section
  Widget _buildRecommendedCompaniesSection(
    AsyncValue<List<RecommendedCompany>> recommendedAsync,
  ) {
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
                  'Recommended Companies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                key: const Key('recommendedCompaniesViewAllButton'),
                onPressed: () => context.push('/directory'),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          recommendedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: AppLoadingIndicator(
                  message: 'Loading recommendations...',
                ),
              ),
            ),
            error: (Object err, _) => Text(
              'Unable to load recommendations at this time.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            data: (List<RecommendedCompany> companies) {
              if (companies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No recommended companies found at this time.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: companies.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: AppSpacing.lg),
                itemBuilder: (BuildContext context, int index) {
                  final RecommendedCompany company = companies[index];
                  return _buildCompanyRow(company);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRow(RecommendedCompany company) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            company.companyName.isNotEmpty
                ? company.companyName.substring(0, 1).toUpperCase()
                : 'C',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                company.companyName,
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
                '${company.businessType} • ${company.location}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (company.productCount > 0) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  'Products (${company.productCount}): ${company.productPreviews.join(', ')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildConnectionActionButton(company),
      ],
    );
  }

  Widget _buildConnectionActionButton(RecommendedCompany company) {
    switch (company.connectionStatus) {
      case 'Connected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 14),
              SizedBox(width: 2),
              Text(
                'Connected',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'Request Sent':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Request Sent',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'Respond to Request':
        return SizedBox(
          height: 32,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => context.push('/network?tab=1'),
            child: const Text('Respond', style: TextStyle(fontSize: 11)),
          ),
        );
      default:
        return SizedBox(
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              final bool success = await ref
                  .read(recommendedCompaniesProvider.notifier)
                  .sendConnectionRequest(company.memberId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Connection request sent to ${company.companyName}.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Connect',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
  }

  /// 6. Recent Product Inquiries Section
  Widget _buildRecentInquiriesSection(
    AsyncValue<List<ProductInquiry>> inquiriesAsync,
  ) {
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
          const Text(
            'Recent Product Inquiries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          inquiriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: AppLoadingIndicator(message: 'Loading inquiries...'),
              ),
            ),
            error: (Object err, _) => const Text(
              'No product inquiries available.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            data: (List<ProductInquiry> inquiries) {
              if (inquiries.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: const <Widget>[
                      Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 28,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No product inquiries yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Inquiries from businesses interested in your products will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: <Widget>[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inquiries.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int index) {
                      final ProductInquiry inquiry = inquiries[index];
                      return _buildInquiryRow(inquiry);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('dashboardViewAllInquiriesButton'),
                      onPressed: () => context.push('/inquiries'),
                      child: const Text('View All Inquiries'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryRow(ProductInquiry inquiry) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF2563EB),
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      inquiry.senderCompanyName.isNotEmpty
                          ? inquiry.senderCompanyName
                          : inquiry.senderName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${inquiry.createdAtUtc.day}/${inquiry.createdAtUtc.month}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                'Re: ${inquiry.productName}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                inquiry.message,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: () => _showInquiryDetailsModal(inquiry),
          child: const Text('View', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  String _formatProfileType(String raw) {
    return switch (raw) {
      'BusinessCompany' => 'Company',
      'ContractorJobWorker' => 'Contractor',
      'EmployeeJobSeeker' => 'Professional',
      'ServiceEngineer' => 'Engineer',
      'TraderSupplier' => 'Supplier',
      _ => raw,
    };
  }
}

/// Product Creation and Editing Dialog Modal
class _AddEditProductDialog extends StatefulWidget {
  const _AddEditProductDialog({this.product, required this.onSave});

  final Product? product;
  final Future<void> Function(CreateProductRequest) onSave;

  @override
  State<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<_AddEditProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _tagsController;
  late final TextEditingController _imageUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );
    _subCategoryController = TextEditingController(
      text: widget.product?.subCategory ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.product?.tags.join(', ') ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final List<String> tags = _tagsController.text
          .split(',')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();

      final CreateProductRequest req = CreateProductRequest(
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
      );

      await widget.onSave(req);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const Key('productFormName'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Industrial Valve V-200',
                  ),
                  validator: (String? val) => val == null || val.trim().isEmpty
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('productFormCategory'),
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    hintText: 'e.g. Industrial Hardware',
                  ),
                  validator: (String? val) => val == null || val.trim().isEmpty
                      ? 'Category is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('productFormSubCategory'),
                  controller: _subCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (optional)',
                    hintText: 'e.g. Stainless Steel Valves',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('productFormDescription'),
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe product specifications and features...',
                  ),
                  validator: (String? val) => val == null || val.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('productFormTags'),
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g. SS316, High Pressure, ANSI',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('productFormImageUrl'),
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('productFormSubmitButton'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
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
              : Text(isEdit ? 'Save Changes' : 'Save & Publish'),
        ),
      ],
    );
  }
}
