import 'package:flutter_test/flutter_test.dart';
import 'package:connexa/features/feed/models/feed_models.dart';

void main() {
  group('PostAttachment Model Tests', () {
    test('fromJson and toJson roundtrip', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 101,
        'mediaUrl': 'https://example.com/machine.jpg',
        'mediaType': 'image',
        'displayOrder': 0,
      };

      final PostAttachment attachment = PostAttachment.fromJson(json);

      expect(attachment.id, 101);
      expect(attachment.mediaUrl, 'https://example.com/machine.jpg');
      expect(attachment.mediaType, 'image');
      expect(attachment.displayOrder, 0);

      final Map<String, dynamic> outJson = attachment.toJson();
      expect(outJson['id'], 101);
      expect(outJson['mediaUrl'], 'https://example.com/machine.jpg');
    });
  });

  group('PostSummary Model Tests', () {
    test('fromJson parses full post correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 1,
        'memberId': 401,
        'authorName': 'Rajesh Sharma',
        'businessName': 'Apex Machinery Works',
        'authorAvatarUrl': 'https://example.com/logo.png',
        'isVerifiedBusiness': true,
        'content': 'Successfully commissioned a 500-ton hydraulic forging press.',
        'industryId': 1,
        'industryName': 'Industrial Machinery',
        'likeCount': 15,
        'commentCount': 3,
        'isLikedByCurrentUser': true,
        'isAuthor': true,
        'isEdited': false,
        'createdAtUtc': '2026-11-02T19:00:00Z',
        'attachments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'mediaUrl': 'https://example.com/press.jpg',
            'mediaType': 'image',
            'displayOrder': 0,
          }
        ],
      };

      final PostSummary post = PostSummary.fromJson(json);

      expect(post.id, 1);
      expect(post.memberId, 401);
      expect(post.authorName, 'Rajesh Sharma');
      expect(post.businessName, 'Apex Machinery Works');
      expect(post.displayName, 'Apex Machinery Works');
      expect(post.isVerifiedBusiness, isTrue);
      expect(post.content, contains('500-ton hydraulic'));
      expect(post.likeCount, 15);
      expect(post.commentCount, 3);
      expect(post.isLikedByCurrentUser, isTrue);
      expect(post.isAuthor, isTrue);
      expect(post.attachments.length, 1);
      expect(post.attachments.first.mediaUrl, 'https://example.com/press.jpg');
    });

    test('displayName falls back to authorName if businessName is absent', () {
      final PostSummary post = PostSummary(
        id: 2,
        memberId: 402,
        authorName: 'Suresh Patel',
        businessName: null,
        content: 'Testing equipment',
        createdAtUtc: DateTime.now().toUtc(),
      );

      expect(post.displayName, 'Suresh Patel');
    });

    test('copyWith updates fields correctly', () {
      final PostSummary original = PostSummary(
        id: 3,
        memberId: 403,
        authorName: 'Mahesh Shah',
        content: 'Original content',
        likeCount: 5,
        isLikedByCurrentUser: false,
        createdAtUtc: DateTime.now().toUtc(),
      );

      final PostSummary updated = original.copyWith(
        likeCount: 6,
        isLikedByCurrentUser: true,
      );

      expect(updated.likeCount, 6);
      expect(updated.isLikedByCurrentUser, isTrue);
      expect(updated.content, 'Original content');
    });
  });

  group('PostComment Model Tests', () {
    test('fromJson and toJson verify correct mapping', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 50,
        'postId': 1,
        'memberId': 402,
        'authorName': 'Vikas Mehta',
        'businessName': 'Gujarat Forgings Ltd',
        'authorAvatarUrl': null,
        'isVerifiedBusiness': true,
        'content': 'Impressive facility! What is the cycle time?',
        'isEdited': false,
        'isAuthor': true,
        'createdAtUtc': '2026-11-02T19:30:00Z',
      };

      final PostComment comment = PostComment.fromJson(json);

      expect(comment.id, 50);
      expect(comment.postId, 1);
      expect(comment.authorName, 'Vikas Mehta');
      expect(comment.displayName, 'Gujarat Forgings Ltd');
      expect(comment.isVerifiedBusiness, isTrue);
      expect(comment.isAuthor, isTrue);
      expect(comment.content, contains('cycle time'));
    });
  });

  group('Feed Request & Response Tests', () {
    test('CreatePostRequest serializes properly', () {
      const CreatePostRequest req = CreatePostRequest(
        content: 'New machinery showcase',
        industryId: 1,
        attachmentUrls: <String>['https://example.com/pic1.jpg'],
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['content'], 'New machinery showcase');
      expect(json['industryId'], 1);
      expect(json['attachmentUrls'], isNotEmpty);
    });

    test('ToggleLikeResult parses response', () {
      final ToggleLikeResult res = ToggleLikeResult.fromJson(<String, dynamic>{
        'postId': 12,
        'isLiked': true,
        'totalLikes': 42,
      });

      expect(res.postId, 12);
      expect(res.isLiked, isTrue);
      expect(res.totalLikes, 42);
    });

    test('PagedFeedResult parses list and pagination metadata', () {
      final PagedFeedResult res = PagedFeedResult.fromJson(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'memberId': 100,
            'authorName': 'Test Author',
            'content': 'Test Feed Item',
            'createdAtUtc': '2026-11-02T19:00:00Z',
          }
        ],
        'totalCount': 10,
        'pageNumber': 1,
        'pageSize': 1,
        'hasNextPage': true,
      });

      expect(res.totalCount, 10);
      expect(res.pageNumber, 1);
      expect(res.hasNextPage, isTrue);
      expect(res.items.length, 1);
      expect(res.items.first.content, 'Test Feed Item');
    });
  });
}

