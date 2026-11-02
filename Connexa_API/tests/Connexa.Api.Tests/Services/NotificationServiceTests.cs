using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Connexa.Api.Services.Notifications.Fcm;

namespace Connexa.Api.Tests.Services;

public class NotificationServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly NotificationService _notificationService;

    public NotificationServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaNotifTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var member1 = new Member
        {
            Id = 1,
            FullName = "Aarav Patel",
            Email = "aarav@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543210",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 1,
                MemberId = 1,
                CompanyName = "Patel Textiles Ltd"
            }
        };

        var member2 = new Member
        {
            Id = 2,
            FullName = "Priya Sharma",
            Email = "priya@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543211",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 2,
                MemberId = 2,
                CompanyName = "Sharma Spinning Mills Ltd"
            }
        };

        var member3 = new Member
        {
            Id = 3,
            FullName = "Kunal Verma",
            Email = "kunal@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543212",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true
        };

        _dbContext.Members.AddRange(member1, member2, member3);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateNotificationAsync_CreatesSuccessfully_AndMapsFields()
    {
        var result = await _notificationService.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ConnectionRequestReceived,
            title: "New Connection Request",
            message: "Priya Sharma sent you a connection request.",
            referenceType: "connection",
            referenceId: 101
        );

        Assert.NotNull(result);
        Assert.Equal(1, result.RecipientMemberId);
        Assert.Equal(2, result.ActorMemberId);
        Assert.Equal("Priya Sharma", result.ActorName);
        Assert.Equal("Sharma Spinning Mills Ltd", result.ActorCompanyName);
        Assert.Equal("ConnectionRequestReceived", result.EventType);
        Assert.Equal("New Connection Request", result.Title);
        Assert.False(result.IsRead);
        Assert.Null(result.ReadAtUtc);
        Assert.Equal("connection", result.ReferenceType);
        Assert.Equal(101, result.ReferenceId);
    }

    [Fact]
    public async Task CreateNotificationAsync_PreventsSelfNotification()
    {
        var result = await _notificationService.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 1, // Same as recipient
            eventType: NotificationEventType.ConnectionRequestReceived,
            title: "Self action",
            message: "Should not create."
        );

        Assert.Null(result);
        Assert.Equal(0, await _dbContext.Notifications.CountAsync());
    }

    [Fact]
    public async Task CreateNotificationAsync_PreventsDuplicateNotifications_OnRetries()
    {
        // First creation
        var first = await _notificationService.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ProductInquiryReceived,
            title: "New Product Inquiry",
            message: "Inquiry for Cotton Yarn",
            referenceType: "inquiry",
            referenceId: 501
        );

        Assert.NotNull(first);
        Assert.Equal(1, await _dbContext.Notifications.CountAsync());

        // Retried creation with identical reference and event
        var retry = await _notificationService.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ProductInquiryReceived,
            title: "New Product Inquiry",
            message: "Inquiry for Cotton Yarn",
            referenceType: "inquiry",
            referenceId: 501
        );

        Assert.NotNull(retry);
        Assert.Equal(first.Id, retry.Id);
        // Count must still be 1
        Assert.Equal(1, await _dbContext.Notifications.CountAsync());
    }

    [Fact]
    public async Task GetNotificationsAsync_EnforcesOwnership_OnlyReturnsRecipientNotifications()
    {
        // Notification for Member 1
        await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.ConnectionRequestReceived, "For Member 1", "Msg 1");

        // Notification for Member 2
        await _notificationService.CreateNotificationAsync(2, 1, NotificationEventType.ProductInquiryReceived, "For Member 2", "Msg 2");

        // Member 1 queries notifications
        var result1 = await _notificationService.GetNotificationsAsync(1);
        Assert.Equal(1, result1.TotalCount);
        Assert.All(result1.Items, n => Assert.Equal(1, n.RecipientMemberId));
        Assert.Equal("For Member 1", result1.Items.First().Title);

        // Member 2 queries notifications
        var result2 = await _notificationService.GetNotificationsAsync(2);
        Assert.Equal(1, result2.TotalCount);
        Assert.All(result2.Items, n => Assert.Equal(2, n.RecipientMemberId));
        Assert.Equal("For Member 2", result2.Items.First().Title);

        // Member 3 queries notifications (none)
        var result3 = await _notificationService.GetNotificationsAsync(3);
        Assert.Equal(0, result3.TotalCount);
        Assert.Empty(result3.Items);
    }

    [Fact]
    public async Task GetNotificationsAsync_FiltersUnreadOnly_AndPaginates()
    {
        // Add 5 notifications for Member 1
        for (int i = 1; i <= 5; i++)
        {
            await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.SystemAnnouncement, $"Notif {i}", $"Msg {i}");
        }

        // Mark 2 as read
        var firstTwo = await _dbContext.Notifications.Where(n => n.RecipientMemberId == 1).Take(2).ToListAsync();
        foreach (var n in firstTwo) { n.IsRead = true; }
        await _dbContext.SaveChangesAsync();

        // Query all page 1 size 3
        var allPaged = await _notificationService.GetNotificationsAsync(1, page: 1, pageSize: 3);
        Assert.Equal(5, allPaged.TotalCount);
        Assert.Equal(3, allPaged.UnreadCount);
        Assert.Equal(3, allPaged.Items.Count);
        Assert.Equal(2, allPaged.TotalPages);

        // Query unread only
        var unreadOnly = await _notificationService.GetNotificationsAsync(1, unreadOnly: true);
        Assert.Equal(3, unreadOnly.TotalCount);
        Assert.All(unreadOnly.Items, n => Assert.False(n.IsRead));
    }

    [Fact]
    public async Task MarkAsReadAsync_SpecificNotifications_MarksOnlySpecified()
    {
        var n1 = await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.ConnectionRequestReceived, "N1", "M1");
        var n2 = await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.ConnectionRequestReceived, "N2", "M2");

        var markedCount = await _notificationService.MarkAsReadAsync(1, new MarkNotificationsReadRequestDto(
            NotificationIds: new List<int> { n1!.Id }
        ));

        Assert.Equal(1, markedCount);

        var refreshedN1 = await _dbContext.Notifications.FindAsync(n1.Id);
        var refreshedN2 = await _dbContext.Notifications.FindAsync(n2!.Id);

        Assert.True(refreshedN1!.IsRead);
        Assert.NotNull(refreshedN1.ReadAtUtc);
        Assert.False(refreshedN2!.IsRead);
        Assert.Null(refreshedN2.ReadAtUtc);
    }

    [Fact]
    public async Task MarkAsReadAsync_MarkAll_MarksAllAsRead()
    {
        await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.ConnectionRequestReceived, "N1", "M1");
        await _notificationService.CreateNotificationAsync(1, 2, NotificationEventType.ProductInquiryReceived, "N2", "M2");

        var unreadBefore = await _notificationService.GetUnreadCountAsync(1);
        Assert.Equal(2, unreadBefore);

        var marked = await _notificationService.MarkAsReadAsync(1, new MarkNotificationsReadRequestDto(MarkAll: true));
        Assert.Equal(2, marked);

        var unreadAfter = await _notificationService.GetUnreadCountAsync(1);
        Assert.Equal(0, unreadAfter);
    }

    [Fact]
    public async Task RegisterAndUnregisterDeviceToken_ManagesTokensCorrectly()
    {
        // Register token
        var regSuccess = await _notificationService.RegisterDeviceTokenAsync(1, new RegisterDeviceTokenDto(
            Token: "fcm_token_sample_12345",
            Platform: "android"
        ));
        Assert.True(regSuccess);

        var savedToken = await _dbContext.DeviceTokens.FirstOrDefaultAsync(t => t.MemberId == 1);
        Assert.NotNull(savedToken);
        Assert.Equal("fcm_token_sample_12345", savedToken.Token);
        Assert.Equal("android", savedToken.Platform);

        // Re-register same token (idempotent upsert)
        var regSame = await _notificationService.RegisterDeviceTokenAsync(1, new RegisterDeviceTokenDto(
            Token: "fcm_token_sample_12345",
            Platform: "android"
        ));
        Assert.True(regSame);
        Assert.Equal(1, await _dbContext.DeviceTokens.CountAsync());

        // Unregister token
        var unreg = await _notificationService.UnregisterDeviceTokenAsync(1, "fcm_token_sample_12345");
        Assert.True(unreg);
        Assert.Equal(0, await _dbContext.DeviceTokens.CountAsync());
    }

    [Fact]
    public async Task CreateNotificationAsync_WithFcmPushService_DispatchesPushSuccessfully()
    {
        var fcmService = new TestFcmPushService();
        var serviceWithFcm = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance, fcmService);

        var result = await serviceWithFcm.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ConnectionRequestReceived,
            title: "New Connection Request",
            message: "Priya Sharma sent you a connection request.",
            referenceType: "Connection",
            referenceId: 101);

        Assert.NotNull(result);
        Assert.Equal(1, fcmService.CallsCount);
        Assert.NotNull(fcmService.LastNotification);
        Assert.Equal("New Connection Request", fcmService.LastNotification.Title);
        Assert.Equal("Connection", fcmService.LastNotification.ReferenceType);
        Assert.Equal(101, fcmService.LastNotification.ReferenceId);
    }

    [Fact]
    public async Task CreateNotificationAsync_WhenFcmPushThrows_StillPersistsNotificationSuccessfully()
    {
        var fcmService = new TestFcmPushService { ShouldThrow = true };
        var serviceWithFcm = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance, fcmService);

        // When FCM push fails, it should NOT throw and in-app notification MUST be saved
        var result = await serviceWithFcm.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ProductInquiryReceived,
            title: "New Inquiry",
            message: "Priya Sharma inquired about Cotton Yarn.",
            referenceType: "Inquiry",
            referenceId: 202);

        Assert.NotNull(result);
        Assert.Equal(1, fcmService.CallsCount);

        // Verify persisted in database
        var persisted = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.Id == result.Id);
        Assert.NotNull(persisted);
        Assert.Equal("New Inquiry", persisted.Title);
    }

    [Fact]
    public async Task CreateNotificationAsync_WhenRetried_PreventsDuplicatePush()
    {
        var fcmService = new TestFcmPushService();
        var serviceWithFcm = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance, fcmService);

        // First attempt
        var first = await serviceWithFcm.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ConnectionRequestAccepted,
            title: "Connection Accepted",
            message: "Priya Sharma accepted your connection request.",
            referenceType: "Connection",
            referenceId: 303);

        Assert.NotNull(first);
        Assert.Equal(1, fcmService.CallsCount);

        // Retry with same event and reference
        var retry = await serviceWithFcm.CreateNotificationAsync(
            recipientMemberId: 1,
            actorMemberId: 2,
            eventType: NotificationEventType.ConnectionRequestAccepted,
            title: "Connection Accepted",
            message: "Priya Sharma accepted your connection request.",
            referenceType: "Connection",
            referenceId: 303);

        Assert.NotNull(retry);
        Assert.Equal(first.Id, retry.Id);
        // Push should NOT have been dispatched a second time
        Assert.Equal(1, fcmService.CallsCount);
    }

    [Fact]
    public async Task FcmPushService_Unconfigured_ReturnsGracefullyWithoutThrowing()
    {
        var testDbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaFcmUnconfigured_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        var services = new ServiceCollection();
        services.AddScoped(_ => new ConnexaDbContext(testDbOptions));
        var provider = services.BuildServiceProvider();
        var scopeFactory = provider.GetRequiredService<IServiceScopeFactory>();

        var config = new ConfigurationBuilder().Build();
        var fcmService = new FcmPushService(scopeFactory, config, NullLogger<FcmPushService>.Instance);

        var notif = new Notification
        {
            Id = 999,
            RecipientMemberId = 1,
            Title = "Test Push",
            Message = "Test Body",
            CreatedAtUtc = DateTime.UtcNow
        };

        var result = await fcmService.SendNotificationAsync(notif);

        Assert.False(result.IsConfigured);
        Assert.Equal(0, result.SentCount);
        Assert.Equal(0, result.FailureCount);
        Assert.NotNull(result.ErrorMessage);
    }

    [Fact]
    public async Task FcmPushService_WithCredentialsPath_InitializesConfiguredService()
    {
        var testDbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaFcmConfigured_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        var services = new ServiceCollection();
        services.AddScoped(_ => new ConnexaDbContext(testDbOptions));
        var provider = services.BuildServiceProvider();
        var scopeFactory = provider.GetRequiredService<IServiceScopeFactory>();

        var inMemorySettings = new Dictionary<string, string?>
        {
            { "Firebase:CredentialsPath", "connexa-firebase-adminsdk.json" }
        };
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        var fcmService = new FcmPushService(scopeFactory, config, NullLogger<FcmPushService>.Instance);

        var notif = new Notification
        {
            Id = 1000,
            RecipientMemberId = 1,
            Title = "Real FCM Init Test",
            Message = "Verifying FirebaseApp initialization",
            CreatedAtUtc = DateTime.UtcNow
        };

        var result = await fcmService.SendNotificationAsync(notif);

        // When credentials exist, IsConfigured is true and FirebaseApp is initialized
        Assert.True(result.IsConfigured);
        Assert.Equal(0, result.SentCount);
        Assert.Equal(0, result.FailureCount);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

class TestFcmPushService : IFcmPushService
{
    public int CallsCount { get; private set; }
    public Notification? LastNotification { get; private set; }
    public bool ShouldThrow { get; set; }

    public Task<PushDeliveryResult> SendNotificationAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        CallsCount++;
        LastNotification = notification;
        if (ShouldThrow)
        {
            throw new InvalidOperationException("Simulated FCM network failure");
        }
        return Task.FromResult(new PushDeliveryResult(true, 1, 0, 0));
    }
}
