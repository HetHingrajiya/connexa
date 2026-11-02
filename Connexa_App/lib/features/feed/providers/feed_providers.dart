import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/feed/models/feed_models.dart';
import 'package:connexa/features/feed/services/feed_service.dart';

class FeedState {
  const FeedState({
    this.posts = const <PostSummary>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.selectedIndustryId,
    this.page = 1,
    this.totalCount = 0,
    this.hasMore = false,
    this.errorMessage,
  });

  final List<PostSummary> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final int? selectedIndustryId;
  final int page;
  final int totalCount;
  final bool hasMore;
  final String? errorMessage;

  FeedState copyWith({
    List<PostSummary>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    int? selectedIndustryId,
    bool clearIndustry = false,
    int? page,
    int? totalCount,
    bool? hasMore,
    String? errorMessage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedIndustryId:
          clearIndustry ? null : (selectedIndustryId ?? this.selectedIndustryId),
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(this._service) : super(const FeedState()) {
    loadFeed();
  }

  final FeedService _service;

  Future<void> loadFeed({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      page: 1,
    );

    try {
      final PagedFeedResult result = await _service.getFeed(
        industryId: state.selectedIndustryId,
        page: 1,
        pageSize: 10,
      );

      state = state.copyWith(
        posts: result.items,
        isLoading: false,
        totalCount: result.totalCount,
        hasMore: result.hasNextPage,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final int nextPage = state.page + 1;
      final PagedFeedResult result = await _service.getFeed(
        industryId: state.selectedIndustryId,
        page: nextPage,
        pageSize: 10,
      );

      state = state.copyWith(
        posts: <PostSummary>[...state.posts, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasNextPage,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setIndustryFilter(int? industryId) {
    if (state.selectedIndustryId == industryId) return;

    if (industryId == null || industryId == 0) {
      state = state.copyWith(clearIndustry: true);
    } else {
      state = state.copyWith(selectedIndustryId: industryId);
    }

    loadFeed(refresh: true);
  }

  Future<void> toggleLike(int postId) async {
    final int index = state.posts.indexWhere((PostSummary p) => p.id == postId);
    if (index == -1) return;

    final PostSummary original = state.posts[index];
    final bool newLiked = !original.isLikedByCurrentUser;
    final int newLikeCount = newLiked
        ? (original.likeCount + 1)
        : (original.likeCount > 0 ? original.likeCount - 1 : 0);

    // Optimistic UI update
    final List<PostSummary> updatedList = List<PostSummary>.from(state.posts);
    updatedList[index] = original.copyWith(
      isLikedByCurrentUser: newLiked,
      likeCount: newLikeCount,
    );
    state = state.copyWith(posts: updatedList);

    try {
      final ToggleLikeResult res = await _service.toggleLike(postId);
      // Synchronize with server response
      final int confirmedIndex =
          state.posts.indexWhere((PostSummary p) => p.id == postId);
      if (confirmedIndex != -1) {
        final List<PostSummary> confirmedList =
            List<PostSummary>.from(state.posts);
        confirmedList[confirmedIndex] =
            state.posts[confirmedIndex].copyWith(
          isLikedByCurrentUser: res.isLiked,
          likeCount: res.totalLikes,
        );
        state = state.copyWith(posts: confirmedList);
      }
    } catch (_) {
      // Revert on failure
      final int rollbackIndex =
          state.posts.indexWhere((PostSummary p) => p.id == postId);
      if (rollbackIndex != -1) {
        final List<PostSummary> rollbackList =
            List<PostSummary>.from(state.posts);
        rollbackList[rollbackIndex] = original;
        state = state.copyWith(posts: rollbackList);
      }
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final bool success = await _service.deletePost(postId);
      if (success) {
        state = state.copyWith(
          posts: state.posts.where((PostSummary p) => p.id != postId).toList(),
          totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void addOrUpdatePost(PostSummary post) {
    final int index = state.posts.indexWhere((PostSummary p) => p.id == post.id);
    if (index != -1) {
      final List<PostSummary> updated = List<PostSummary>.from(state.posts);
      updated[index] = post;
      state = state.copyWith(posts: updated);
    } else {
      state = state.copyWith(
        posts: <PostSummary>[post, ...state.posts],
        totalCount: state.totalCount + 1,
      );
    }
  }
}

final StateNotifierProvider<FeedNotifier, FeedState> feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((Ref ref) {
  final FeedService service = ref.watch(feedServiceProvider);
  return FeedNotifier(service);
});

final AutoDisposeFutureProviderFamily<PostSummary, int> postDetailsProvider =
    FutureProvider.autoDispose.family<PostSummary, int>((Ref ref, int id) async {
  final FeedService service = ref.watch(feedServiceProvider);
  return service.getPostById(id);
});

class PostCommentsState {
  const PostCommentsState({
    this.comments = const <PostComment>[],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<PostComment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  PostCommentsState copyWith({
    List<PostComment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return PostCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class PostCommentsNotifier extends StateNotifier<PostCommentsState> {
  PostCommentsNotifier(this._service, this._postId)
      : super(const PostCommentsState()) {
    loadComments();
  }

  final FeedService _service;
  final int _postId;

  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final List<PostComment> comments = await _service.getComments(_postId);
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<PostComment?> addComment(String content) async {
    if (content.trim().isEmpty) return null;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final PostComment created = await _service.addComment(
        _postId,
        CreateCommentRequest(content: content.trim()),
      );
      state = state.copyWith(
        comments: <PostComment>[...state.comments, created],
        isSubmitting: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final bool success = await _service.deleteComment(commentId);
      if (success) {
        state = state.copyWith(
          comments:
              state.comments.where((PostComment c) => c.id != commentId).toList(),
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final AutoDisposeStateNotifierProviderFamily<PostCommentsNotifier,
        PostCommentsState, int> postCommentsProvider =
    StateNotifierProvider.autoDispose
        .family<PostCommentsNotifier, PostCommentsState, int>(
            (Ref ref, int postId) {
  final FeedService service = ref.watch(feedServiceProvider);
  return PostCommentsNotifier(service, postId);
});

