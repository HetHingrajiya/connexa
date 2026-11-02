import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/products/models/product_models.dart';

final Provider<ProductService> productServiceProvider =
    Provider<ProductService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return ProductService(dio);
    });

class ProductService {
  const ProductService(this._dio);

  final Dio _dio;

  Future<List<Product>> getMyProducts({CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/my',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) => Product.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <Product>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load products (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Product?> getProductById(int id, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/$id',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return Product.fromJson(data['data'] as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to load product details.');
    }
  }

  Future<Product> createProduct(
    CreateProductRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/products',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return Product.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to create product.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Create product failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Product> updateProduct(
    int id,
    UpdateProductRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/products/$id',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return Product.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to update product.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Update product failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<bool> deleteProduct(int id, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '/api/v1/products/$id',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Delete product failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<ProductInquiry> sendInquiry(
    int productId,
    CreateProductInquiryRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/products/$productId/inquiries',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ProductInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to send product inquiry.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Send inquiry failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<ProductInquiry>> getReceivedInquiries({
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/inquiries/received',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) =>
                  ProductInquiry.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <ProductInquiry>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load inquiries (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<ProductInquiry>> getSentInquiries({
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/inquiries/sent',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) =>
                  ProductInquiry.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <ProductInquiry>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load sent inquiries (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<ProductInquiry?> getInquiryById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/inquiries/$id',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ProductInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return null;
      }
      throw Exception('Failed to load inquiry details.');
    }
  }

  Future<ProductInquiry> respondToInquiry(
    int inquiryId,
    RespondToInquiryRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/products/inquiries/$inquiryId/respond',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ProductInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to send response.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Response submission failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves paginated and filtered product discovery records across the network.
  Future<ProductCatalogResponse> getCatalogProducts(
    ProductFilter filter, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products',
        queryParameters: filter.toQueryParams(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ProductCatalogResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      } else if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        final List<Product> list = (data['data'] as List<dynamic>)
            .map(
              (dynamic item) => Product.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        return ProductCatalogResponse(
          items: list,
          totalCount: list.length,
          page: 1,
          pageSize: list.length,
          totalPages: 1,
        );
      }

      throw Exception(
        data['message']?.toString() ??
            'Failed to load product discovery catalogue.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Catalog request failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<Product>> getAllProducts({
    String? search,
    String? category,
    int? memberId,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products',
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (category != null &&
              category.trim().isNotEmpty &&
              category != 'All')
            'category': category.trim(),
          if (memberId != null && memberId > 0) 'memberId': memberId,
          'limit': limit,
          'pageSize': limit,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        if (data['data'] is List) {
          return (data['data'] as List<dynamic>)
              .map(
                (dynamic item) =>
                    Product.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (data['data'] is Map<String, dynamic> &&
            data['data']['items'] is List) {
          return (data['data']['items'] as List<dynamic>)
              .map(
                (dynamic item) =>
                    Product.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      }

      return <Product>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load products (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }


  Future<DashboardStats> getDashboardStats({CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/dashboard/stats',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return DashboardStats.fromJson(data['data'] as Map<String, dynamic>);
      }

      return const DashboardStats();
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load stats (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<RecommendedCompany>> getRecommendedCompanies({
    int limit = 5,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/dashboard/recommended-companies',
        queryParameters: <String, dynamic>{'limit': limit},
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) =>
                  RecommendedCompany.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <RecommendedCompany>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load recommended companies (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<void> recordProfileView(
    int memberId, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post(
        '/api/v1/members/$memberId/view',
        cancelToken: cancelToken,
      );
    } catch (_) {
      // Fire-and-forget telemetry, silent catch
    }
  }

  Future<List<Product>> getRelatedProducts(
    int productId, {
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/$productId/related',
        queryParameters: <String, dynamic>{'limit': limit},
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) =>
                  Product.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <Product>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load related products (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<Product>> getRecommendedProducts({
    int? industryId,
    String? category,
    int? excludeProductId,
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/products/recommended',
        queryParameters: <String, dynamic>{
          if (industryId != null && industryId > 0) 'industryId': industryId,
          if (category != null && category.trim().isNotEmpty && category != 'All')
            'category': category.trim(),
          if (excludeProductId != null && excludeProductId > 0)
            'excludeProductId': excludeProductId,
          'limit': limit,
          'pageSize': limit,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map(
              (dynamic item) =>
                  Product.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return <Product>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load recommended products (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }
}
