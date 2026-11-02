import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_bottom_nav_bar.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/responsive_layout.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/presentation/widgets/add_edit_product_dialog.dart';
import 'package:connexa/features/products/providers/product_provider.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';

/// Dedicated Products Screen for authenticated members:
/// - Global Industry-Wise Product Discovery across all eligible businesses and members.
/// - Personal Showcase Management to publish, edit, and manage own products.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  // View mode: 0 = Explore Catalog (Global Discovery), 1 = My Products (Personal Showcase)
  int _selectedTabIndex = 0;

  // Catalog Discovery Filters
  final TextEditingController _catalogSearchController =
      TextEditingController();
  Timer? _searchDebounce;
  int? _selectedIndustryId;
  String _selectedCategory = 'All';
  String _selectedSortBy = 'newest';
  bool _verifiedOnly = false;

  // Personal Showcase Filters
  final TextEditingController _mySearchController = TextEditingController();
  bool _isMySearchExpanded = false;
  String _mySelectedCategory = 'All';
  String _mySelectedStatus = 'All';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _catalogSearchController.dispose();
    _mySearchController.dispose();
    super.dispose();
  }

  void _onCatalogSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productCatalogProvider.notifier).setSearch(query);
    });
  }

  void _onSelectIndustry(int? industryId) {
    setState(() {
      _selectedIndustryId = industryId;
    });
    ref.read(productCatalogProvider.notifier).setIndustry(industryId);
  }

  void _onToggleVerifiedOnly() {
    setState(() {
      _verifiedOnly = !_verifiedOnly;
    });
    ref.read(productCatalogProvider.notifier).toggleVerifiedOnly();
  }

  void _onSelectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(productCatalogProvider.notifier).setCategory(category);
  }

  void _onSelectSort(String sortBy) {
    setState(() {
      _selectedSortBy = sortBy;
    });
    ref.read(productCatalogProvider.notifier).setSortBy(sortBy);
  }

  void _clearCatalogFilters() {
    _searchDebounce?.cancel();
    _catalogSearchController.clear();
    setState(() {
      _selectedIndustryId = null;
      _selectedCategory = 'All';
      _selectedSortBy = 'newest';
      _verifiedOnly = false;
    });
    ref.read(productCatalogProvider.notifier).clearFilters();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(recommendedProductsProvider);
    await Future.wait(<Future<void>>[
      ref.read(productCatalogProvider.notifier).refresh(),
      ref.read(myProductsProvider.notifier).refresh(),
    ]);
  }

  Future<void> _showAddEditProductModal([Product? product]) async {
    final bool isEdit = product != null;

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
              if (isEdit) {
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
              } else {
                final CreateProductRequest req = CreateProductRequest(
                  name: name,
                  description: description,
                  category: category,
                  subCategory: subCategory,
                  tags: tags,
                  imageUrl: imageUrl,
                  specifications: specifications,
                );
                await ref.read(myProductsProvider.notifier).addProduct(req);
              }
              // Refresh both personal showcase and network catalog
              ref.read(productCatalogProvider.notifier).refresh();
            },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Product updated successfully.'
                : 'Product published to network successfully.',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showProductDetailsModal(Product product) {
    context.push('/products/${product.id}', extra: product);
  }

  Future<void> _showDeleteConfirmationModal(Product product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to remove "${product.name}"? It will no longer be visible in the global product discovery.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirmDeleteProductButton'),
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
        ref.read(productCatalogProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Product> _filterMyProducts(List<Product> products) {
    final String query = _mySearchController.text.trim().toLowerCase();

    return products.where((Product p) {
      if (_mySelectedCategory != 'All' &&
          p.category.toLowerCase() != _mySelectedCategory.toLowerCase()) {
        return false;
      }
      if (_mySelectedStatus == 'Published' && !p.isActive) {
        return false;
      }
      if (_mySelectedStatus == 'Draft / Inactive' && p.isActive) {
        return false;
      }
      if (query.isNotEmpty) {
        final bool nameMatch = p.name.toLowerCase().contains(query);
        final bool descMatch = p.description.toLowerCase().contains(query);
        final bool catMatch = p.category.toLowerCase().contains(query);
        final bool tagMatch = p.tags.any(
          (String t) => t.toLowerCase().contains(query),
        );
        return nameMatch || descMatch || catMatch || tagMatch;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: const Color(0xFF062747), // Deep Navy
          elevation: 0,
          toolbarHeight: 64,
          titleSpacing: AppSpacing.md,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text(
                'Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              key: const Key('productsRefreshButton'),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Refresh',
              onPressed: _refreshAll,
            ),
            IconButton(
              key: const Key('productsInquiriesAppBarButton'),
              icon: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Inquiries',
              onPressed: () => context.push('/inquiries'),
            ),
            IconButton(
              key: const Key('productsAddProductAppBarButton'),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Add Product',
              onPressed: () => _showAddEditProductModal(),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenterBox(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              // Segmented View Mode Switcher: Explore Catalog vs My Products
              _buildViewSwitcher(),
              const SizedBox(height: AppSpacing.sm),
              // Main View Body
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildGlobalDiscoveryView()
                    : _buildMyShowcaseView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented Tab Switcher allowing toggle between Global Discovery and My Showcase
  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildTabButton(
              key: const Key('exploreCatalogTabButton'),
              label: 'Explore Catalog',
              icon: Icons.explore_outlined,
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() => _selectedTabIndex = 0);
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              key: const Key('myProductsTabButton'),
              label: 'My Products',
              icon: Icons.inventory_2_outlined,
              isSelected: _selectedTabIndex == 1,
              onTap: () {
                setState(() => _selectedTabIndex = 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    Key? key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: GLOBAL INDUSTRY-WISE PRODUCT DISCOVERY
  // ===========================================================================

  Widget _buildGlobalDiscoveryView() {
    final AsyncValue<ProductCatalogResponse> catalogAsync = ref.watch(
      productCatalogProvider,
    );
    final AsyncValue<List<Industry>> industriesAsync = ref.watch(
      industriesProvider,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(productCatalogProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          // 1. Search Bar with Live Debounce & Sort Dropdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const Key('catalogSearchInput'),
                      controller: _catalogSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search products, suppliers, tags...',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _catalogSearchController.text.isNotEmpty
                            ? IconButton(
                                key: const Key('catalogClearSearchButton'),
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _catalogSearchController.clear();
                                  _onCatalogSearchChanged('');
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (String text) {
                        setState(() {});
                        _onCatalogSearchChanged(text);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _buildSortDropdown(),
                ],
              ),
            ),
          ),

          // 2. Industry Selector Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Industries',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_selectedIndustryId != null ||
                          _selectedCategory != 'All' ||
                          _catalogSearchController.text.isNotEmpty ||
                          _selectedSortBy != 'newest' ||
                          _verifiedOnly)
                        InkWell(
                          key: const Key('catalogResetFiltersButton'),
                          onTap: _clearCatalogFilters,
                          child: const Text(
                            'Reset All',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  industriesAsync.when(
                    data: (List<Industry> industries) =>
                        _buildIndustryChips(industries),
                    loading: () => _buildIndustryChipsSkeleton(),
                    error: (Object? error, StackTrace? stackTrace) =>
                        _buildIndustryChips(const <Industry>[]),
                  ),
                ],
              ),
            ),
          ),

          // 3. Smart "Recommended for You" Section
          _buildRecommendedSection(),

          // 4. Category Filter Chips (dynamically gathered from catalog items)
          catalogAsync.maybeWhen(
            data: (ProductCatalogResponse res) {
              final Set<String> categories = <String>{'All'};
              for (final Product p in res.items) {
                if (p.category.trim().isNotEmpty) {
                  categories.add(p.category.trim());
                }
              }
              if (categories.length <= 1) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SizedBox(
                    height: 28,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 6),
                      itemBuilder: (BuildContext ctx, int idx) {
                        final String cat = categories.elementAt(idx);
                        final bool isSel = _selectedCategory == cat;
                        return FilterChip(
                          selected: isSel,
                          label: Text(
                            cat,
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          labelStyle: TextStyle(
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF334155),
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF1E3A8A),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSel
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (_) => _onSelectCategory(cat),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // 4. Catalog Products List / Loading / Error
          catalogAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppLoadingIndicator(
                  message: 'Discovering products across Connexa...',
                ),
              ),
            ),
            error: (Object err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppErrorState(
                  title: 'Failed to load product catalog',
                  description: err.toString(),
                  onRetry: () =>
                      ref.read(productCatalogProvider.notifier).refresh(),
                ),
              ),
            ),
            data: (ProductCatalogResponse catalog) {
              if (catalog.items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildCatalogEmptyState(),
                );
              }

              return SliverMainAxisGroup(
                slivers: <Widget>[
                  // Catalog Header Info (Count & Summary)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 2,
                        bottom: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Products (${catalog.totalCount})',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Page ${catalog.page} of ${catalog.totalPages}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Products Grid/List
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      final Product product = catalog.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildCatalogProductCard(product),
                      );
                    }, childCount: catalog.items.length),
                  ),

                  // Pagination Footer
                  if (catalog.totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: _buildPaginationBar(catalog),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Sort dropdown menu
  Widget _buildSortDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: PopupMenuButton<String>(
        key: const Key('catalogSortMenuButton'),
        icon: const Icon(
          Icons.sort_rounded,
          color: Color(0xFF334155),
          size: 20,
        ),
        tooltip: 'Sort Products',
        initialValue: _selectedSortBy,
        onSelected: _onSelectSort,
        itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'newest',
            child: Text('Newest First', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem<String>(
            value: 'name_asc',
            child: Text('Name (A-Z)', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem<String>(
            value: 'price_asc',
            child: Text('Price: Low to High', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem<String>(
            value: 'price_desc',
            child: Text('Price: High to Low', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrolling Industry chips with real data from Master Data API
  Widget _buildIndustryChips(List<Industry> industries) {
    final bool isAllSelected = _selectedIndustryId == null;

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          // "Verified Suppliers" Chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              key: const Key('verifiedSuppliersFilterChip'),
              selected: _verifiedOnly,
              avatar: Icon(
                Icons.verified_rounded,
                size: 14,
                color: _verifiedOnly ? Colors.white : const Color(0xFF2563EB),
              ),
              label: const Text(
                'Verified Only',
                style: TextStyle(fontSize: 11),
              ),
              labelStyle: TextStyle(
                color: _verifiedOnly ? Colors.white : const Color(0xFF334155),
                fontWeight: _verifiedOnly ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: const Color(0xFF2563EB),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _verifiedOnly
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) => _onToggleVerifiedOnly(),
            ),
          ),
          // "All Industries" Chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              key: const Key('industryFilterChip_all'),
              selected: isAllSelected,
              label: const Text(
                'All Industries',
                style: TextStyle(fontSize: 11),
              ),
              labelStyle: TextStyle(
                color: isAllSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isAllSelected ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: const Color(0xFF0F172A),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isAllSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (_) => _onSelectIndustry(null),
            ),
          ),
          // Master Industries Chips
          ...industries.map((Industry ind) {
            final bool isSelected = _selectedIndustryId == ind.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                key: Key('industryFilterChip_${ind.id}'),
                selected: isSelected,
                label: Text(ind.name, style: const TextStyle(fontSize: 11)),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                backgroundColor: const Color(0xFFF1F5F9),
                selectedColor: const Color(0xFF2563EB),
                checkmarkColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (_) => _onSelectIndustry(ind.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIndustryChipsSkeleton() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) => Container(
          width: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// Smart "Recommended for You" section
  Widget _buildRecommendedSection() {
    // Hide recommendations when actively searching to keep focus on search results
    if (_catalogSearchController.text.trim().isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final AsyncValue<List<Product>> recommendedAsync = ref.watch(
      recommendedProductsProvider(_selectedIndustryId),
    );
    final AsyncValue<ProductCatalogResponse> catalogAsync = ref.watch(
      productCatalogProvider,
    );

    return recommendedAsync.maybeWhen(
      data: (List<Product> products) {
        // Exclude products already displayed in the main catalog to avoid repetition
        final Set<int> visibleCatalogIds =
            catalogAsync.value?.items.map((Product p) => p.id).toSet() ??
            <int>{};

        final List<Product> distinctRecommended = products
            .where((Product p) => !visibleCatalogIds.contains(p.id))
            .toList();

        final List<Product> displayProducts = distinctRecommended.isNotEmpty
            ? distinctRecommended
            : products;

        if (displayProducts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Section Header with Flexible/Expanded to prevent overflow
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Recommended for You',
                          key: Key('recommendedSectionTitle'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        key: const Key('refreshRecommendationsButton'),
                        onTap: () => ref.refresh(
                          recommendedProductsProvider(_selectedIndustryId),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Refresh',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedIndustryId != null
                        ? 'Top relevant offerings in the selected industry'
                        : 'Personalized based on your registered industry & business sector',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 155,
                    child: ListView.separated(
                      key: const Key('recommendedProductsList'),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayProducts.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final Product prod = displayProducts[index];
                        return _buildRecommendedMiniCard(prod);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildRecommendedMiniCard(Product prod) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('recommendedProductCard_${prod.id}'),
          onTap: () => _showProductDetailsModal(prod),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Thumbnail Image
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: prod.imageUrl != null &&
                          prod.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          prod.imageUrl!,
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
                                  size: 20,
                                ),
                              ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    prod.category,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                // Product Name
                Text(
                  prod.name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                // Company
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        prod.companyName ?? 'Connexa Supplier',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (prod.isOwnerVerified) ...<Widget>[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.verified_rounded,
                        size: 10,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                // Display Price
                Text(
                  prod.displayPrice.isNotEmpty
                      ? prod.displayPrice
                      : 'Details →',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Global Discovery Product Card
  Widget _buildCatalogProductCard(Product product) {
    final String company = product.companyName ??
        (product.isOwnerVerified ? 'Verified Supplier' : 'Business Supplier');
    final String industry = product.industryName ?? product.category;
    final int? currentMemberId = ref.watch(authProvider).profile?.memberId;
    final bool isOwn =
        product.isOwner ||
        (currentMemberId != null && product.memberId == currentMemberId);

    return Container(
      key: Key('productCard_${product.id}'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header: Image + Name + Industry Pill + Company
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Product Thumbnail
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.trim().isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) => const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 24,
                                  ),
                            )
                          : const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Industry Tag + "You" badge if owner
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFDBEAFE),
                                    ),
                                  ),
                                  child: Text(
                                    industry,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isOwn) ...<Widget>[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Product Name
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Supplier Business Name with Verified Checkmark
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.business_rounded,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  company,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (product.isOwnerVerified) ...<Widget>[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  key: Key('productVerifiedBadgeIcon'),
                                  size: 13,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description snippet
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Pricing and Location row
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    // Price highlight
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        product.displayPrice,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (product.moq != null && product.moq!.trim().isNotEmpty)
                      Text(
                        'MOQ: ${product.moq}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (product.location != null &&
                        product.location!.trim().isNotEmpty)
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
                            product.location!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: 6),

                // Footer metrics & Action
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.viewCount} views',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.inquiryCount} inquiries',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showProductDetailsModal(product),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          isOwn ? 'Manage →' : 'View Details →',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
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

  /// Empty State for Catalog Discovery
  Widget _buildCatalogEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No products match your criteria',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try selecting another industry or clearing your search filters to browse products across the entire network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              key: const Key('clearCatalogFiltersButton'),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Clear All Filters',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: _clearCatalogFilters,
            ),
          ],
        ),
      ),
    );
  }

  /// Server-side Pagination controls
  Widget _buildPaginationBar(ProductCatalogResponse catalog) {
    final bool canPrev = catalog.page > 1;
    final bool canNext = catalog.page < catalog.totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          key: const Key('catalogPrevPageButton'),
          icon: const Icon(Icons.chevron_left_rounded),
          color: canPrev ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          onPressed: canPrev
              ? () => ref
                    .read(productCatalogProvider.notifier)
                    .loadPage(catalog.page - 1)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Page ${catalog.page} of ${catalog.totalPages}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          key: const Key('catalogNextPageButton'),
          icon: const Icon(Icons.chevron_right_rounded),
          color: canNext ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          onPressed: canNext
              ? () => ref
                    .read(productCatalogProvider.notifier)
                    .loadPage(catalog.page + 1)
              : null,
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 2: PERSONAL SHOWCASE MANAGEMENT ("MY PRODUCTS")
  // ===========================================================================

  Widget _buildMyShowcaseView() {
    final AsyncValue<List<Product>> productsAsync = ref.watch(
      myProductsProvider,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(myProductsProvider.notifier).refresh(),
      child: productsAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading your products...'),
        ),
        error: (Object err, _) => Center(
          child: AppErrorState(
            title: 'Failed to load products',
            description: err.toString(),
            onRetry: () => ref.read(myProductsProvider.notifier).refresh(),
          ),
        ),
        data: (List<Product> products) {
          if (products.isEmpty) {
            return _buildZeroProductsEmptyState();
          }

          final List<Product> filtered = _filterMyProducts(products);

          // Collect unique categories for filter chips
          final Set<String> categories = <String>{'All'};
          for (final Product p in products) {
            if (p.category.trim().isNotEmpty) {
              categories.add(p.category.trim());
            }
          }

          final int publishedCount = products
              .where((Product p) => p.isActive)
              .length;
          final int draftCount = products.length - publishedCount;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // Search input if expanded or query present
              if (_isMySearchExpanded || _mySearchController.text.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TextField(
                      key: const Key('productSearchInput'),
                      controller: _mySearchController,
                      autofocus: _isMySearchExpanded,
                      decoration: InputDecoration(
                        hintText: 'Search my products...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _mySearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() => _mySearchController.clear());
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),

              // Summary Metrics Row
              SliverToBoxAdapter(
                child: _buildSummaryMetrics(
                  total: products.length,
                  published: publishedCount,
                  drafts: draftCount,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Category Filter Chips
              SliverToBoxAdapter(
                child: _buildCategoryChips(categories.toList()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Status Filter Chips
              SliverToBoxAdapter(child: _buildStatusChips()),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Products Count & Add Action bar
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'My Showcase (${filtered.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        IconButton(
                          key: const Key('productsSearchButton'),
                          icon: Icon(
                            _isMySearchExpanded
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _isMySearchExpanded = !_isMySearchExpanded;
                              if (!_isMySearchExpanded) {
                                _mySearchController.clear();
                              }
                            });
                          },
                        ),
                        TextButton.icon(
                          key: const Key('productsListAddButton'),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'Add Product',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _showAddEditProductModal(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),

              // List or Filter Empty State
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildFilteredEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final Product product = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildMyProductItemCard(product),
                    );
                  }, childCount: filtered.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }

  /// 3 Summary Metric Cards (Total, Published, Draft / Inactive)
  Widget _buildSummaryMetrics({
    required int total,
    required int published,
    required int drafts,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildMetricCard(
            label: 'Total Products',
            value: '$total',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildMetricCard(
            label: 'Published',
            value: '$published',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildMetricCard(
            label: 'Draft / Inactive',
            value: '$drafts',
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFD97706),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: color, size: 18),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
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

  /// Horizontal scrolling Category filter chips for personal showcase
  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final String cat = categories[index];
          final bool isSelected = _mySelectedCategory == cat;

          return FilterChip(
            selected: isSelected,
            label: Text(cat, style: const TextStyle(fontSize: 11)),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFF2563EB),
            checkmarkColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            onSelected: (bool selected) {
              setState(() {
                _mySelectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  /// Status filter chips (All, Published, Draft/Inactive) for personal showcase
  Widget _buildStatusChips() {
    const List<String> statuses = <String>[
      'All',
      'Published',
      'Draft / Inactive',
    ];

    return Row(
      children: statuses.map((String status) {
        final bool isSelected = _mySelectedStatus == status;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            selected: isSelected,
            label: Text(status, style: const TextStyle(fontSize: 11)),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            backgroundColor: const Color(0xFFF8FAFC),
            selectedColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            onSelected: (bool selected) {
              setState(() {
                _mySelectedStatus = status;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  /// Personal Showcase Product Card with Owner Actions (Edit, Delete, View)
  Widget _buildMyProductItemCard(Product product) {
    return Container(
      key: Key('productCard_${product.id}'),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header Row: Thumbnail + Title/Category + Action Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Thumbnail
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.trim().isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) => const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 24,
                                  ),
                            )
                          : const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Title and Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.subCategory != null &&
                                    product.subCategory!.isNotEmpty
                                ? '${product.category} • ${product.subCategory}'
                                : product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status Pill + 3-Dot Menu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.isActive ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: product.isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          key: Key('productMenu_${product.id}'),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 130),
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
                                PopupMenuItem<String>(
                                  key: Key('productMenuView_${product.id}'),
                                  value: 'view',
                                  child: Row(
                                    children: const <Widget>[
                                      Icon(Icons.visibility_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'View Details',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  key: Key('productMenuEdit_${product.id}'),
                                  value: 'edit',
                                  child: Row(
                                    children: const <Widget>[
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Edit Product',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  key: Key('productMenuDelete_${product.id}'),
                                  value: 'delete',
                                  child: Row(
                                    children: const <Widget>[
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Product',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Specifications pills if present (Price, MOQ)
                if (product.specifications.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: product.specifications.entries.map((
                      MapEntry<String, String> e,
                    ) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Tags
                if (product.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: product.tags.take(3).map((String tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: 6),

                // Footer metrics (Views, Inquiries, Quick Action)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.viewCount} views',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.inquiryCount} inquiries',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showProductDetailsModal(product),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'View Details →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
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

  /// Empty State when user has 0 products
  Widget _buildZeroProductsEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No products added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your first product to showcase it to businesses on Connexa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              key: const Key('productsEmptyStateAddButton'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                '+ Add Product',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => _showAddEditProductModal(),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State when active filters yield 0 products in personal showcase
  Widget _buildFilteredEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF94A3B8),
              size: 44,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No matching products found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search query or filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                setState(() {
                  _mySearchController.clear();
                  _mySelectedCategory = 'All';
                  _mySelectedStatus = 'All';
                  _isMySearchExpanded = false;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
