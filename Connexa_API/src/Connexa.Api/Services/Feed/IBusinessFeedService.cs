using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Feed;

public interface IBusinessFeedService
{
    Task<PagedFeedResponse<PostSummaryDto>> GetFeedAsync(int currentMemberId, FeedQueryDto query, CancellationToken ct = default);
    Task<PostSummaryDto?> GetPostByIdAsync(int postId, int currentMemberId, CancellationToken ct = default);
    Task<PostSummaryDto> CreatePostAsync(int currentMemberId, CreatePostDto dto, CancellationToken ct = default);
    Task<PostSummaryDto> UpdatePostAsync(int postId, int currentMemberId, UpdatePostDto dto, CancellationToken ct = default);
    Task<bool> DeletePostAsync(int postId, int currentMemberId, CancellationToken ct = default);
    Task<ToggleLikeResponseDto> ToggleLikeAsync(int postId, int currentMemberId, CancellationToken ct = default);
    Task<List<PostCommentDto>> GetPostCommentsAsync(int postId, int currentMemberId, CancellationToken ct = default);
    Task<PostCommentDto> AddCommentAsync(int postId, int currentMemberId, CreateCommentDto dto, CancellationToken ct = default);
    Task<PostCommentDto> UpdateCommentAsync(int commentId, int currentMemberId, UpdateCommentDto dto, CancellationToken ct = default);
    Task<bool> DeleteCommentAsync(int commentId, int currentMemberId, CancellationToken ct = default);
    Task<bool> ReportContentAsync(int currentMemberId, int? postId, int? commentId, ReportContentDto dto, CancellationToken ct = default);
}

