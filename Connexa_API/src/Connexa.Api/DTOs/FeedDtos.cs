using Connexa.Api.Entities;

namespace Connexa.Api.DTOs;

public record CreatePostDto(
    string Content,
    int? IndustryId = null,
    List<string>? AttachmentUrls = null
);

public record UpdatePostDto(
    string Content,
    int? IndustryId = null
);

public record PostAttachmentDto(
    int Id,
    string MediaUrl,
    string? MediaType,
    int DisplayOrder
);

public record PostSummaryDto(
    int Id,
    int MemberId,
    string AuthorName,
    string? BusinessName,
    string? AuthorAvatarUrl,
    bool IsVerifiedBusiness,
    string Content,
    int? IndustryId,
    string? IndustryName,
    int LikeCount,
    int CommentCount,
    bool IsLikedByCurrentUser,
    bool IsAuthor,
    bool IsEdited,
    DateTime CreatedAtUtc,
    List<PostAttachmentDto> Attachments
);

public record PostCommentDto(
    int Id,
    int PostId,
    int MemberId,
    string AuthorName,
    string? BusinessName,
    string? AuthorAvatarUrl,
    bool IsVerifiedBusiness,
    string Content,
    bool IsEdited,
    bool IsAuthor,
    DateTime CreatedAtUtc
);

public record CreateCommentDto(
    string Content
);

public record UpdateCommentDto(
    string Content
);

public record ReportContentDto(
    string Reason,
    string? Details = null
);

public record FeedQueryDto(
    int? IndustryId = null,
    int? MemberId = null,
    int PageNumber = 1,
    int PageSize = 10
);

public record PagedFeedResponse<T>(
    List<T> Items,
    int TotalCount,
    int PageNumber,
    int PageSize,
    bool HasNextPage
);

public record ToggleLikeResponseDto(
    int PostId,
    bool IsLiked,
    int TotalLikes
);

