import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/connections/services/connection_service.dart';
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/services/product_service.dart';

/// Provider for live Dashboard Statistics from real backend data.
final FutureProvider<DashboardStats> dashboardStatsProvider =
    FutureProvider<DashboardStats>((Ref ref) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getDashboardStats();
    });

/// Async notifier managing authenticated member's products.
final AsyncNotifierProvider<MyProductsNotifier, List<Product>>
myProductsProvider = AsyncNotifierProvider<MyProductsNotifier, List<Product>>(
  MyProductsNotifier.new,
);

class MyProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final ProductService service = ref.watch(productServiceProvider);
    return service.getMyProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<Product>>.loading();
    state = await AsyncValue.guard(() async {
      final ProductService service = ref.read(productServiceProvider);
      final List<Product> products = await service.getMyProducts();
      // Also refresh dashboard stats
      ref.invalidate(dashboardStatsProvider);
      return products;
    });
  }

  Future<Product> addProduct(CreateProductRequest request) async {
    final ProductService service = ref.read(productServiceProvider);
    final Product newProduct = await service.createProduct(request);
    await refresh();
    return newProduct;
  }

  Future<Product> editProduct(int id, UpdateProductRequest request) async {
    final ProductService service = ref.read(productServiceProvider);
    final Product updated = await service.updateProduct(id, request);
    await refresh();
    return updated;
  }

  Future<bool> removeProduct(int id) async {
    final ProductService service = ref.read(productServiceProvider);
    final bool success = await service.deleteProduct(id);
    if (success) {
      await refresh();
    }
    return success;
  }
}

/// Provider for recent product inquiries received by member.
final FutureProvider<List<ProductInquiry>> recentInquiriesProvider =
    FutureProvider<List<ProductInquiry>>((Ref ref) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getReceivedInquiries();
    });

/// Provider for inquiries sent by the authenticated member.
final FutureProvider<List<ProductInquiry>> sentInquiriesProvider =
    FutureProvider<List<ProductInquiry>>((Ref ref) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getSentInquiries();
    });

/// Family provider for fetching inquiry details by ID with access control.
final FutureProviderFamily<ProductInquiry?, int> inquiryDetailsProvider =
    FutureProvider.family<ProductInquiry?, int>((Ref ref, int inquiryId) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getInquiryById(inquiryId);
    });

/// Family provider for fetching product details by ID.
final FutureProviderFamily<Product?, int> productDetailsProvider =
    FutureProvider.family<Product?, int>((Ref ref, int productId) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getProductById(productId);
    });

/// Family provider for fetching related products for a given product ID.
final FutureProviderFamily<List<Product>, int> relatedProductsProvider =
    FutureProvider.family<List<Product>, int>((Ref ref, int productId) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getRelatedProducts(productId, limit: 6);
    });

/// Family provider for fetching personalized or industry-filtered product recommendations.
final FutureProviderFamily<List<Product>, int?> recommendedProductsProvider =
    FutureProvider.family<List<Product>, int?>((Ref ref, int? industryId) async {
      final ProductService service = ref.watch(productServiceProvider);
      return service.getRecommendedProducts(industryId: industryId, limit: 8);
    });

/// Async notifier managing network-wide product discovery catalog and server-side filtering.
final AsyncNotifierProvider<ProductCatalogNotifier, ProductCatalogResponse>
productCatalogProvider =
    AsyncNotifierProvider<ProductCatalogNotifier, ProductCatalogResponse>(
      ProductCatalogNotifier.new,
    );

class ProductCatalogNotifier extends AsyncNotifier<ProductCatalogResponse> {
  ProductFilter _filter = const ProductFilter();

  ProductFilter get currentFilter => _filter;

  @override
  Future<ProductCatalogResponse> build() async {
    final ProductService service = ref.watch(productServiceProvider);
    return service.getCatalogProducts(_filter);
  }

  Future<void> setIndustry(int? industryId) async {
    _filter = _filter.copyWith(
      industryId: industryId,
      clearIndustry: industryId == null || industryId <= 0,
      page: 1,
    );
    await refresh();
  }

  Future<void> setCategory(String category) async {
    _filter = _filter.copyWith(
      category: category,
      clearCategory: category == 'All' || category.trim().isEmpty,
      page: 1,
    );
    await refresh();
  }

  Future<void> setSearch(String search) async {
    _filter = _filter.copyWith(
      search: search.trim(),
      page: 1,
    );
    await refresh();
  }

  Future<void> setSortBy(String sortBy) async {
    _filter = _filter.copyWith(
      sortBy: sortBy,
      page: 1,
    );
    await refresh();
  }

  Future<void> toggleVerifiedOnly() async {
    final bool current = _filter.verifiedOnly ?? false;
    final bool next = !current;
    _filter = _filter.copyWith(
      verifiedOnly: next,
      clearVerifiedOnly: !next,
      page: 1,
    );
    await refresh();
  }

  Future<void> setVerifiedOnly(bool? verifiedOnly) async {
    _filter = _filter.copyWith(
      verifiedOnly: verifiedOnly,
      clearVerifiedOnly: verifiedOnly == null || !verifiedOnly,
      page: 1,
    );
    await refresh();
  }

  Future<void> clearFilters() async {
    _filter = const ProductFilter();
    await refresh();
  }

  Future<void> loadPage(int page) async {
    if (page == _filter.page) return;
    _filter = _filter.copyWith(page: page);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue<ProductCatalogResponse>.loading();
    state = await AsyncValue.guard(() async {
      final ProductService service = ref.read(productServiceProvider);
      return service.getCatalogProducts(_filter);
    });
  }
}

/// Provider for network-wide product catalog exploration (compatible list extraction).
final Provider<List<Product>> catalogProductsProvider =
    Provider<List<Product>>((Ref ref) {
      final AsyncValue<ProductCatalogResponse> catalog = ref.watch(
        productCatalogProvider,
      );
      return catalog.value?.items ?? const <Product>[];
    });


/// Async notifier managing recommended companies and real-time connection state transitions.
final AsyncNotifierProvider<
  RecommendedCompaniesNotifier,
  List<RecommendedCompany>
>
recommendedCompaniesProvider =
    AsyncNotifierProvider<
      RecommendedCompaniesNotifier,
      List<RecommendedCompany>
    >(RecommendedCompaniesNotifier.new);

class RecommendedCompaniesNotifier
    extends AsyncNotifier<List<RecommendedCompany>> {
  @override
  Future<List<RecommendedCompany>> build() async {
    final ProductService service = ref.watch(productServiceProvider);
    return service.getRecommendedCompanies();
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<RecommendedCompany>>.loading();
    state = await AsyncValue.guard(() async {
      final ProductService service = ref.read(productServiceProvider);
      return service.getRecommendedCompanies();
    });
  }

  Future<bool> sendConnectionRequest(int recipientMemberId) async {
    final ConnectionService connectionService = ref.read(
      connectionServiceProvider,
    );
    try {
      await connectionService.sendRequest(recipientMemberId: recipientMemberId);
      // Optimistically update connection status
      final List<RecommendedCompany>? current = state.value;
      if (current != null) {
        state = AsyncValue<List<RecommendedCompany>>.data(
          current.map((RecommendedCompany c) {
            if (c.memberId == recipientMemberId) {
              return c.copyWith(connectionStatus: 'Request Sent');
            }
            return c;
          }).toList(),
        );
      }
      // Invalidate stats
      ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
