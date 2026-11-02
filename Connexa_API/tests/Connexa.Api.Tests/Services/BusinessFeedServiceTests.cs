namespace Connexa.Api.Tests.Services;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Feed;
using Connexa.Api.Services.Notifications;

public class BusinessFeedServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly BusinessFeedService _service;
    private readonly NotificationService _notificationService;

    public BusinessFeedServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaFeedTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);
        _service = new BusinessFeedService(_dbContext, _notificationService);

        SeedData();
    }

    private void SeedData()
    {
        var industry1 = new Industry
        {
            Id = 1,
            Name = "Industrial Machinery",
            Description = "Heavy engineering and machinery"
        };
        var industry2 = new Industry
        {
            Id = 2,
            Name = "Textile & Garments",
            Description = "Textile machinery and processing"
        };
        _dbContext.Industries.AddRange(industry1, industry2);

        var member1 = new Member
        {
            Id = 401,
            FullName = "Apex Machinery Works",
            Email = "contact@apexmachinery.test",
            CountryCode = "+91",
            PhoneNumber = "9876540001",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 401,
                MemberId = 401,
                CompanyName = "Apex Machinery Works",
                City = "Rajkot",
                State = "Gujarat",
                IndustryId = 1,
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        var member2 = new Member
        {
            Id = 402,
            FullName = "Gujarat CNC Lathe Works",
            Email = "info@gujarattcnc.test",
            CountryCode = "+91",
            PhoneNumber = "9876540002",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 402,
                MemberId = 402,
                CompanyName = "Gujarat CNC Lathe Works",
                City = "Ahmedabad",
                State = "Gujarat",
                IndustryId = 1,
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        _dbContext.Members.AddRange(member1, member2);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreatePostAsync_ValidContent_CreatesPostSuccessfully()
    {
        var dto = new CreatePostDto(
            Content: "We have installed a brand new 5-axis CNC Milling station in Rajkot factory!",
            IndustryId: 1,
            AttachmentUrls: new List<string> { "https://example.com/cnc1.jpg", "https://example.com/cnc2.jpg" }
        );

        var post = await _service.CreatePostAsync(401, dto);

        Assert.NotNull(post);
        Assert.Equal(401, post.MemberId);
        Assert.Equal("Apex Machinery Works", post.AuthorName);
        Assert.True(post.IsAuthor);
        Assert.Equal(2, post.Attachments.Count);
        Assert.Equal(0, post.LikeCount);
        Assert.Equal(0, post.CommentCount);
    }

    [Fact]
    public async Task CreatePostAsync_EmptyContent_ThrowsArgumentException()
    {
        var dto = new CreatePostDto(Content: "   ");
        await Assert.ThrowsAsync<ArgumentException>(() => _service.CreatePostAsync(401, dto));
    }

    [Fact]
    public async Task GetFeedAsync_ReturnsChronologicalPosts()
    {
        await _service.CreatePostAsync(401, new CreatePostDto("Post 1 from Apex", 1));
        await Task.Delay(10);
        await _service.CreatePostAsync(402, new CreatePostDto("Post 2 from Gujarat CNC", 1));

        var feed = await _service.GetFeedAsync(401, new FeedQueryDto(PageNumber: 1, PageSize: 10));

        Assert.NotNull(feed);
        Assert.True(feed.TotalCount >= 2);
        Assert.Equal("Post 2 from Gujarat CNC", feed.Items[0].Content);
        Assert.Equal("Post 1 from Apex", feed.Items[1].Content);
    }

    [Fact]
    public async Task GetFeedAsync_IndustryFilter_FiltersByIndustry()
    {
        await _service.CreatePostAsync(401, new CreatePostDto("Machinery Post", 1));
        await _service.CreatePostAsync(402, new CreatePostDto("Textile Post", 2));

        var machineryFeed = await _service.GetFeedAsync(401, new FeedQueryDto(IndustryId: 1));
        var textileFeed = await _service.GetFeedAsync(401, new FeedQueryDto(IndustryId: 2));

        Assert.All(machineryFeed.Items, p => Assert.Equal(1, p.IndustryId));
        Assert.All(textileFeed.Items, p => Assert.Equal(2, p.IndustryId));
    }

    [Fact]
    public async Task UpdatePostAsync_OwnerCanUpdateContent()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Original Content", 1));

        var updated = await _service.UpdatePostAsync(post.Id, 401, new UpdatePostDto("Updated Content", 1));

        Assert.Equal("Updated Content", updated.Content);
        Assert.True(updated.IsEdited);
    }

    [Fact]
    public async Task UpdatePostAsync_NonOwner_ThrowsUnauthorizedAccessException()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Original Content", 1));

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            _service.UpdatePostAsync(post.Id, 402, new UpdatePostDto("Malicious edit", 1)));
    }

    [Fact]
    public async Task DeletePostAsync_OwnerCanSoftDelete()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Content to delete", 1));

        var success = await _service.DeletePostAsync(post.Id, 401);
        Assert.True(success);

        var retrieved = await _service.GetPostByIdAsync(post.Id, 401);
        Assert.Null(retrieved);
    }

    [Fact]
    public async Task ToggleLikeAsync_TogglesLikeAndCounterCorrectly()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Post for like test", 1));

        // Like by member 402
        var likeResult = await _service.ToggleLikeAsync(post.Id, 402);
        Assert.True(likeResult.IsLiked);
        Assert.Equal(1, likeResult.TotalLikes);

        var postAfterLike = await _service.GetPostByIdAsync(post.Id, 402);
        Assert.True(postAfterLike!.IsLikedByCurrentUser);

        // Second toggle removes like
        var unlikeResult = await _service.ToggleLikeAsync(post.Id, 402);
        Assert.False(unlikeResult.IsLiked);
        Assert.Equal(0, unlikeResult.TotalLikes);

        var postAfterUnlike = await _service.GetPostByIdAsync(post.Id, 402);
        Assert.False(postAfterUnlike!.IsLikedByCurrentUser);
    }

    [Fact]
    public async Task AddCommentAsync_ValidComment_IncrementsCountAndReturnsDto()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Machine showcase", 1));

        var comment = await _service.AddCommentAsync(post.Id, 402, new CreateCommentDto("Great capacity! What is the lead time?"));

        Assert.NotNull(comment);
        Assert.Equal("Gujarat CNC Lathe Works", comment.AuthorName);
        Assert.Equal("Great capacity! What is the lead time?", comment.Content);
        Assert.True(comment.IsAuthor);

        var comments = await _service.GetPostCommentsAsync(post.Id, 401);
        Assert.Single(comments);

        var postUpdated = await _service.GetPostByIdAsync(post.Id, 401);
        Assert.Equal(1, postUpdated!.CommentCount);
    }

    [Fact]
    public async Task UpdateCommentAsync_OwnerCanUpdate()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Machine showcase", 1));
        var comment = await _service.AddCommentAsync(post.Id, 402, new CreateCommentDto("Initial comment"));

        var updated = await _service.UpdateCommentAsync(comment.Id, 402, new UpdateCommentDto("Corrected comment text"));

        Assert.Equal("Corrected comment text", updated.Content);
        Assert.True(updated.IsEdited);
    }

    [Fact]
    public async Task DeleteCommentAsync_OwnerCanDeleteComment()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Machine showcase", 1));
        var comment = await _service.AddCommentAsync(post.Id, 402, new CreateCommentDto("Comment to delete"));

        var success = await _service.DeleteCommentAsync(comment.Id, 402);
        Assert.True(success);

        var comments = await _service.GetPostCommentsAsync(post.Id, 401);
        Assert.Empty(comments);

        var postUpdated = await _service.GetPostByIdAsync(post.Id, 401);
        Assert.Equal(0, postUpdated!.CommentCount);
    }

    [Fact]
    public async Task ReportContentAsync_ValidPostReport_CreatesReportSuccessfully()
    {
        var post = await _service.CreatePostAsync(401, new CreatePostDto("Suspicious claim", 1));

        var result = await _service.ReportContentAsync(402, post.Id, null, new ReportContentDto(
            Reason: "Misleading Specifications",
            Details: "The specs listed do not conform to ISO standard"
        ));

        Assert.True(result);

        var report = await _dbContext.BusinessPostReports.FirstOrDefaultAsync(r => r.PostId == post.Id);
        Assert.NotNull(report);
        Assert.Equal(402, report.ReporterMemberId);
        Assert.Equal("Misleading Specifications", report.Reason);
        Assert.Equal(PostReportStatus.Pending, report.Status);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

