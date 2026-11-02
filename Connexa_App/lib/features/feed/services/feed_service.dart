import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/feed/models/feed_models.dart';

final Provider<FeedService> feedServiceProvider = Provider<FeedService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return FeedService(dio);
});

class FeedService {
  FeedService(this._dio);

  final Dio _dio;

  Future<PagedFeedResult> getFeed({
    int? industryId,
    int? memberId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/feed',
        queryParameters: <String, dynamic>{
          if (industryId != null && industryId > 0) 'industryId': industryId,
          'memberId': ?memberId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PagedFeedResult.fromJson(data['data'] as Map<String, dynamic>);
      }

      return const PagedFeedResult(
        items: <PostSummary>[],
        totalCount: 0,
        pageNumber: 1,
        pageSize: 10,
        hasNextPage: false,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostSummary> getPostById(int id) async {
    try {
      final Response<dynamic> response = await _dio.get('/api/v1/feed/$id');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PostSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Post not found.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostSummary> createPost(CreatePostRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/feed',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PostSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to publish post.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostSummary> updatePost(int id, UpdatePostRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/feed/$id',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PostSummary.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to update post.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      final Response<dynamic> response = await _dio.delete('/api/v1/feed/$id');
      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ToggleLikeResult> toggleLike(int id) async {
    try {
      final Response<dynamic> response = await _dio.post('/api/v1/feed/$id/like');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return ToggleLikeResult.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to toggle like.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PostComment>> getComments(int postId) async {
    try {
      final Response<dynamic> response = await _dio.get('/api/v1/feed/$postId/comments');
      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((dynamic e) => PostComment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <PostComment>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostComment> addComment(int postId, CreateCommentRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/feed/$postId/comments',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PostComment.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to add comment.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostComment> updateComment(int commentId, UpdateCommentRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/feed/comments/$commentId',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] != null) {
        return PostComment.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AuthException('Failed to update comment.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final Response<dynamic> response =
          await _dio.delete('/api/v1/feed/comments/$commentId');
      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> reportContent({
    int? postId,
    int? commentId,
    required ReportContentRequest request,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/feed/report',
        queryParameters: <String, dynamic>{
          'postId': ?postId,
          'commentId': ?commentId,
        },
        data: request.toJson(),
      );

      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AuthException _handleError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> map =
          e.response!.data as Map<String, dynamic>;
      final String message = map['message'] as String? ??
          map['error'] as String? ??
          'An error occurred';
      return AuthException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
    return AuthException(
      e.message ?? 'Network connection error',
      statusCode: e.response?.statusCode,
    );
  }
}

