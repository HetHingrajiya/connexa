using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace Connexa.Api.Services.Feed;

public class BusinessFeedService : IBusinessFeedService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notifications;

    public BusinessFeedService(ConnexaDbContext db, INotificationService notifications)
    {
        _db = db;
        _notifications = notifications;
    }

    public async Task<PagedFeedResponse<PostSummaryDto>> GetFeedAsync(int currentMemberId, FeedQueryDto query, CancellationToken ct = default)
    {
        var q = _db.BusinessPosts
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(p => p.Industry)
            .Include(p => p.Attachments)
            .Include(p => p.Likes.Where(l => l.MemberId == currentMemberId))
            .Where(p => !p.IsDeleted)
            .AsNoTracking()
            .AsQueryable();

        if (query.IndustryId.HasValue && query.IndustryId.Value > 0)
        {
            q = q.Where(p => p.IndustryId == query.IndustryId.Value);
        }

        if (query.MemberId.HasValue && query.MemberId.Value > 0)
        {
            q = q.Where(p => p.MemberId == query.MemberId.Value);
        }

        var totalCount = await q.CountAsync(ct);

        var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
        var pageSize = query.PageSize < 1 ? 10 : (query.PageSize > 50 ? 50 : query.PageSize);

        var posts = await q
            .OrderByDescending(p => p.CreatedAtUtc)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var dtos = posts.Select(p => MapToSummaryDto(p, currentMemberId)).ToList();

        var hasNextPage = (pageNumber * pageSize) < totalCount;

        return new PagedFeedResponse<PostSummaryDto>(
            Items: dtos,
            TotalCount: totalCount,
            PageNumber: pageNumber,
            PageSize: pageSize,
            HasNextPage: hasNextPage
        );
    }

    public async Task<PostSummaryDto?> GetPostByIdAsync(int postId, int currentMemberId, CancellationToken ct = default)
    {
        var post = await _db.BusinessPosts
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(p => p.Industry)
            .Include(p => p.Attachments)
            .Include(p => p.Likes.Where(l => l.MemberId == currentMemberId))
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);

        if (post == null)
            return null;

        return MapToSummaryDto(post, currentMemberId);
    }

    public async Task<PostSummaryDto> CreatePostAsync(int currentMemberId, CreatePostDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new ArgumentException("Post content cannot be empty.");

        var post = new BusinessPost
        {
            MemberId = currentMemberId,
            Content = dto.Content.Trim(),
            IndustryId = dto.IndustryId,
            CreatedAtUtc = DateTime.UtcNow,
            LikeCount = 0,
            CommentCount = 0,
            IsDeleted = false,
            IsEdited = false
        };

        if (dto.AttachmentUrls != null && dto.AttachmentUrls.Any())
        {
            int order = 0;
            foreach (var url in dto.AttachmentUrls)
            {
                if (!string.IsNullOrWhiteSpace(url))
                {
                    post.Attachments.Add(new BusinessPostAttachment
                    {
                        MediaUrl = url.Trim(),
                        MediaType = "image",
                        DisplayOrder = order++,
                        CreatedAtUtc = DateTime.UtcNow
                    });
                }
            }
        }

        _db.BusinessPosts.Add(post);
        await _db.SaveChangesAsync(ct);

        return (await GetPostByIdAsync(post.Id, currentMemberId, ct))!;
    }

    public async Task<PostSummaryDto> UpdatePostAsync(int postId, int currentMemberId, UpdatePostDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new ArgumentException("Post content cannot be empty.");

        var post = await _db.BusinessPosts
            .FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct)
            ?? throw new KeyNotFoundException("Post not found.");

        if (post.MemberId != currentMemberId)
            throw new UnauthorizedAccessException("You are not authorized to edit this post.");

        post.Content = dto.Content.Trim();
        post.IndustryId = dto.IndustryId;
        post.IsEdited = true;
        post.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return (await GetPostByIdAsync(post.Id, currentMemberId, ct))!;
    }

    public async Task<bool> DeletePostAsync(int postId, int currentMemberId, CancellationToken ct = default)
    {
        var post = await _db.BusinessPosts
            .FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);

        if (post == null)
            return false;

        if (post.MemberId != currentMemberId)
            throw new UnauthorizedAccessException("You are not authorized to delete this post.");

        post.IsDeleted = true;
        post.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<ToggleLikeResponseDto> ToggleLikeAsync(int postId, int currentMemberId, CancellationToken ct = default)
    {
        var post = await _db.BusinessPosts
            .Include(p => p.Member)
            .FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct)
            ?? throw new KeyNotFoundException("Post not found.");

        var existingLike = await _db.BusinessPostLikes
            .FirstOrDefaultAsync(l => l.PostId == postId && l.MemberId == currentMemberId, ct);

        bool isLiked;
        if (existingLike != null)
        {
            _db.BusinessPostLikes.Remove(existingLike);
            post.LikeCount = Math.Max(0, post.LikeCount - 1);
            isLiked = false;
        }
        else
        {
            var newLike = new BusinessPostLike
            {
                PostId = postId,
                MemberId = currentMemberId,
                LikedAtUtc = DateTime.UtcNow
            };
            _db.BusinessPostLikes.Add(newLike);
            post.LikeCount += 1;
            isLiked = true;

            if (post.MemberId != currentMemberId)
            {
                try
                {
                    var liker = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == currentMemberId, ct);
                    var likerName = liker?.BusinessProfile?.CompanyName ?? liker?.FullName ?? "A member";

                    await _notifications.CreateNotificationAsync(
                        recipientMemberId: post.MemberId,
                        eventType: NotificationEventType.PostLiked,
                        title: "New Like on Your Post",
                        message: $"{likerName} liked your post.",
                        referenceType: "feed_post",
                        referenceId: post.Id,
                        actorMemberId: currentMemberId
                    );
                }
                catch
                {
                    // Non-critical notification failure
                }
            }
        }

        await _db.SaveChangesAsync(ct);

        return new ToggleLikeResponseDto(
            PostId: post.Id,
            IsLiked: isLiked,
            TotalLikes: post.LikeCount
        );
    }

    public async Task<List<PostCommentDto>> GetPostCommentsAsync(int postId, int currentMemberId, CancellationToken ct = default)
    {
        var comments = await _db.BusinessPostComments
            .Include(c => c.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Where(c => c.PostId == postId && !c.IsDeleted)
            .OrderBy(c => c.CreatedAtUtc)
            .AsNoTracking()
            .ToListAsync(ct);

        return comments.Select(c => new PostCommentDto(
            Id: c.Id,
            PostId: c.PostId,
            MemberId: c.MemberId,
            AuthorName: c.Member.FullName,
            BusinessName: c.Member.BusinessProfile?.CompanyName,
            AuthorAvatarUrl: c.Member.BusinessProfile?.LogoUrl,
            IsVerifiedBusiness: c.Member.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Content: c.Content,
            IsEdited: c.IsEdited,
            IsAuthor: c.MemberId == currentMemberId,
            CreatedAtUtc: c.CreatedAtUtc
        )).ToList();
    }

    public async Task<PostCommentDto> AddCommentAsync(int postId, int currentMemberId, CreateCommentDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new ArgumentException("Comment cannot be empty.");

        var post = await _db.BusinessPosts
            .Include(p => p.Member)
            .FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct)
            ?? throw new KeyNotFoundException("Post not found.");

        var comment = new BusinessPostComment
        {
            PostId = postId,
            MemberId = currentMemberId,
            Content = dto.Content.Trim(),
            CreatedAtUtc = DateTime.UtcNow,
            IsEdited = false,
            IsDeleted = false
        };

        _db.BusinessPostComments.Add(comment);
        post.CommentCount += 1;

        if (post.MemberId != currentMemberId)
        {
            try
            {
                var commenter = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == currentMemberId, ct);
                var commenterName = commenter?.BusinessProfile?.CompanyName ?? commenter?.FullName ?? "A member";

                await _notifications.CreateNotificationAsync(
                    recipientMemberId: post.MemberId,
                    eventType: NotificationEventType.PostCommented,
                    title: "New Comment on Your Post",
                    message: $"{commenterName} commented on your post: \"{(dto.Content.Length > 40 ? dto.Content[..40] + "..." : dto.Content)}\"",
                    referenceType: "feed_post",
                    referenceId: post.Id,
                    actorMemberId: currentMemberId
                );
            }
            catch
            {
                // Non-critical notification failure
            }
        }

        await _db.SaveChangesAsync(ct);

        var commenterMember = await _db.Members
            .Include(m => m.BusinessProfile)
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == currentMemberId, ct);

        return new PostCommentDto(
            Id: comment.Id,
            PostId: comment.PostId,
            MemberId: comment.MemberId,
            AuthorName: commenterMember?.FullName ?? string.Empty,
            BusinessName: commenterMember?.BusinessProfile?.CompanyName,
            AuthorAvatarUrl: commenterMember?.BusinessProfile?.LogoUrl,
            IsVerifiedBusiness: commenterMember?.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Content: comment.Content,
            IsEdited: comment.IsEdited,
            IsAuthor: true,
            CreatedAtUtc: comment.CreatedAtUtc
        );
    }

    public async Task<PostCommentDto> UpdateCommentAsync(int commentId, int currentMemberId, UpdateCommentDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Content))
            throw new ArgumentException("Comment cannot be empty.");

        var comment = await _db.BusinessPostComments
            .Include(c => c.Member)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(c => c.Id == commentId && !c.IsDeleted, ct)
            ?? throw new KeyNotFoundException("Comment not found.");

        if (comment.MemberId != currentMemberId)
            throw new UnauthorizedAccessException("You are not authorized to edit this comment.");

        comment.Content = dto.Content.Trim();
        comment.IsEdited = true;
        comment.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return new PostCommentDto(
            Id: comment.Id,
            PostId: comment.PostId,
            MemberId: comment.MemberId,
            AuthorName: comment.Member.FullName,
            BusinessName: comment.Member.BusinessProfile?.CompanyName,
            AuthorAvatarUrl: comment.Member.BusinessProfile?.LogoUrl,
            IsVerifiedBusiness: comment.Member.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Content: comment.Content,
            IsEdited: comment.IsEdited,
            IsAuthor: true,
            CreatedAtUtc: comment.CreatedAtUtc
        );
    }

    public async Task<bool> DeleteCommentAsync(int commentId, int currentMemberId, CancellationToken ct = default)
    {
        var comment = await _db.BusinessPostComments
            .Include(c => c.Post)
            .FirstOrDefaultAsync(c => c.Id == commentId && !c.IsDeleted, ct);

        if (comment == null)
            return false;

        // Author of comment OR author of post can delete comment
        if (comment.MemberId != currentMemberId && comment.Post.MemberId != currentMemberId)
            throw new UnauthorizedAccessException("You are not authorized to delete this comment.");

        comment.IsDeleted = true;
        comment.UpdatedAtUtc = DateTime.UtcNow;

        if (comment.Post != null)
        {
            comment.Post.CommentCount = Math.Max(0, comment.Post.CommentCount - 1);
        }

        await _db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<bool> ReportContentAsync(int currentMemberId, int? postId, int? commentId, ReportContentDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reason))
            throw new ArgumentException("Report reason cannot be empty.");

        if (!postId.HasValue && !commentId.HasValue)
            throw new ArgumentException("Either postId or commentId must be provided.");

        var report = new BusinessPostReport
        {
            ReporterMemberId = currentMemberId,
            PostId = postId,
            CommentId = commentId,
            Reason = dto.Reason.Trim(),
            Details = dto.Details?.Trim(),
            Status = PostReportStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.BusinessPostReports.Add(report);
        await _db.SaveChangesAsync(ct);

        return true;
    }

    private static PostSummaryDto MapToSummaryDto(BusinessPost post, int currentMemberId)
    {
        var isLiked = post.Likes.Any(l => l.MemberId == currentMemberId);

        return new PostSummaryDto(
            Id: post.Id,
            MemberId: post.MemberId,
            AuthorName: post.Member.FullName,
            BusinessName: post.Member.BusinessProfile?.CompanyName,
            AuthorAvatarUrl: post.Member.BusinessProfile?.LogoUrl,
            IsVerifiedBusiness: post.Member.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Content: post.Content,
            IndustryId: post.IndustryId,
            IndustryName: post.Industry?.Name,
            LikeCount: post.LikeCount,
            CommentCount: post.CommentCount,
            IsLikedByCurrentUser: isLiked,
            IsAuthor: post.MemberId == currentMemberId,
            IsEdited: post.IsEdited,
            CreatedAtUtc: post.CreatedAtUtc,
            Attachments: post.Attachments
                .OrderBy(a => a.DisplayOrder)
                .Select(a => new PostAttachmentDto(a.Id, a.MediaUrl, a.MediaType, a.DisplayOrder))
                .ToList()
        );
    }
}

