import 'package:flutter/foundation.dart';

@immutable
class PostAttachment {
  const PostAttachment({
    required this.id,
    required this.mediaUrl,
    this.mediaType,
    this.displayOrder = 0,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) {
    return PostAttachment(
      id: json['id'] as int? ?? 0,
      mediaUrl: json['mediaUrl'] as String? ?? '',
      mediaType: json['mediaType'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  final int id;
  final String mediaUrl;
  final String? mediaType;
  final int displayOrder;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'mediaUrl': mediaUrl,
        if (mediaType != null) 'mediaType': mediaType,
        'displayOrder': displayOrder,
      };
}

@immutable
class PostSummary {
  const PostSummary({
    required this.id,
    required this.memberId,
    required this.authorName,
    this.businessName,
    this.authorAvatarUrl,
    this.isVerifiedBusiness = false,
    required this.content,
    this.industryId,
    this.industryName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    this.isAuthor = false,
    this.isEdited = false,
    required this.createdAtUtc,
    this.attachments = const <PostAttachment>[],
  });

  factory PostSummary.fromJson(Map<String, dynamic> json) {
    return PostSummary(
      id: json['id'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? 'Industrial Member',
      businessName: json['businessName'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      isVerifiedBusiness: json['isVerifiedBusiness'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      industryId: json['industryId'] as int?,
      industryName: json['industryName'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      isAuthor: json['isAuthor'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  PostAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PostAttachment>[],
    );
  }

  final int id;
  final int memberId;
  final String authorName;
  final String? businessName;
  final String? authorAvatarUrl;
  final bool isVerifiedBusiness;
  final String content;
  final int? industryId;
  final String? industryName;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final bool isAuthor;
  final bool isEdited;
  final DateTime createdAtUtc;
  final List<PostAttachment> attachments;

  String get displayName => (businessName != null && businessName!.isNotEmpty)
      ? businessName!
      : authorName;

  PostSummary copyWith({
    int? id,
    int? memberId,
    String? authorName,
    String? businessName,
    String? authorAvatarUrl,
    bool? isVerifiedBusiness,
    String? content,
    int? industryId,
    String? industryName,
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
    bool? isAuthor,
    bool? isEdited,
    DateTime? createdAtUtc,
    List<PostAttachment>? attachments,
  }) {
    return PostSummary(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      authorName: authorName ?? this.authorName,
      businessName: businessName ?? this.businessName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isVerifiedBusiness: isVerifiedBusiness ?? this.isVerifiedBusiness,
      content: content ?? this.content,
      industryId: industryId ?? this.industryId,
      industryName: industryName ?? this.industryName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser:
          isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isAuthor: isAuthor ?? this.isAuthor,
      isEdited: isEdited ?? this.isEdited,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'memberId': memberId,
        'authorName': authorName,
        if (businessName != null) 'businessName': businessName,
        if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
        'isVerifiedBusiness': isVerifiedBusiness,
        'content': content,
        if (industryId != null) 'industryId': industryId,
        if (industryName != null) 'industryName': industryName,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'isLikedByCurrentUser': isLikedByCurrentUser,
        'isAuthor': isAuthor,
        'isEdited': isEdited,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'attachments': attachments.map((PostAttachment a) => a.toJson()).toList(),
      };
}

@immutable
class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.memberId,
    required this.authorName,
    this.businessName,
    this.authorAvatarUrl,
    this.isVerifiedBusiness = false,
    required this.content,
    this.isEdited = false,
    this.isAuthor = false,
    required this.createdAtUtc,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as int? ?? 0,
      postId: json['postId'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? 'Industrial Member',
      businessName: json['businessName'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      isVerifiedBusiness: json['isVerifiedBusiness'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      isEdited: json['isEdited'] as bool? ?? false,
      isAuthor: json['isAuthor'] as bool? ?? false,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final int id;
  final int postId;
  final int memberId;
  final String authorName;
  final String? businessName;
  final String? authorAvatarUrl;
  final bool isVerifiedBusiness;
  final String content;
  final bool isEdited;
  final bool isAuthor;
  final DateTime createdAtUtc;

  String get displayName => (businessName != null && businessName!.isNotEmpty)
      ? businessName!
      : authorName;

  PostComment copyWith({
    int? id,
    int? postId,
    int? memberId,
    String? authorName,
    String? businessName,
    String? authorAvatarUrl,
    bool? isVerifiedBusiness,
    String? content,
    bool? isEdited,
    bool? isAuthor,
    DateTime? createdAtUtc,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      memberId: memberId ?? this.memberId,
      authorName: authorName ?? this.authorName,
      businessName: businessName ?? this.businessName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isVerifiedBusiness: isVerifiedBusiness ?? this.isVerifiedBusiness,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      isAuthor: isAuthor ?? this.isAuthor,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'postId': postId,
        'memberId': memberId,
        'authorName': authorName,
        if (businessName != null) 'businessName': businessName,
        if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
        'isVerifiedBusiness': isVerifiedBusiness,
        'content': content,
        'isEdited': isEdited,
        'isAuthor': isAuthor,
        'createdAtUtc': createdAtUtc.toIso8601String(),
      };
}

@immutable
class CreatePostRequest {
  const CreatePostRequest({
    required this.content,
    this.industryId,
    this.attachmentUrls,
  });

  final String content;
  final int? industryId;
  final List<String>? attachmentUrls;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
        'industryId': ?industryId,
        if (attachmentUrls != null) 'attachmentUrls': attachmentUrls,
      };
}

@immutable
class UpdatePostRequest {
  const UpdatePostRequest({
    required this.content,
    this.industryId,
  });

  final String content;
  final int? industryId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
        'industryId': ?industryId,
      };
}

@immutable
class CreateCommentRequest {
  const CreateCommentRequest({
    required this.content,
  });

  final String content;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

@immutable
class UpdateCommentRequest {
  const UpdateCommentRequest({
    required this.content,
  });

  final String content;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

@immutable
class ReportContentRequest {
  const ReportContentRequest({
    required this.reason,
    this.details,
  });

  final String reason;
  final String? details;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reason': reason,
        'details': ?details,
      };
}

@immutable
class ToggleLikeResult {
  const ToggleLikeResult({
    required this.postId,
    required this.isLiked,
    required this.totalLikes,
  });

  factory ToggleLikeResult.fromJson(Map<String, dynamic> json) {
    return ToggleLikeResult(
      postId: json['postId'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      totalLikes: json['totalLikes'] as int? ?? 0,
    );
  }

  final int postId;
  final bool isLiked;
  final int totalLikes;
}

@immutable
class PagedFeedResult {
  const PagedFeedResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.hasNextPage,
  });

  factory PagedFeedResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['items'] as List<dynamic>?;
    final List<PostSummary> items = rawItems != null
        ? rawItems
            .map((dynamic e) => PostSummary.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PostSummary>[];

    return PagedFeedResult(
      items: items,
      totalCount: json['totalCount'] as int? ?? items.length,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }

  final List<PostSummary> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final bool hasNextPage;
}

