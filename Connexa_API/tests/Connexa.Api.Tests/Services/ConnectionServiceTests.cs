using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Connections;
using Connexa.Api.Services.Directory;

namespace Connexa.Api.Tests.Services;

public class ConnectionServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ConnectionService _connectionService;
    private readonly DirectoryService _directoryService;

    public ConnectionServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaConnTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _connectionService = new ConnectionService(_dbContext, NullLogger<ConnectionService>.Instance);
        _directoryService = new DirectoryService(_dbContext, NullLogger<DirectoryService>.Instance);

        SeedSampleData();
    }

    private void SeedSampleData()
    {
        var industry = new Industry { Id = 1, Name = "Manufacturing", Code = "MFG" };
        var group = new BusinessGroup { Id = 1, IndustryId = 1, Name = "Textiles", Code = "TXT" };
        var subGroup = new SubGroup { Id = 1, BusinessGroupId = 1, Name = "Weaving", Code = "WEA" };
        var category = new Category { Id = 1, SubGroupId = 1, Name = "Cotton Weaving", Code = "CW" };

        _dbContext.Industries.Add(industry);
        _dbContext.BusinessGroups.Add(group);
        _dbContext.SubGroups.Add(subGroup);
        _dbContext.Categories.Add(category);

        // Member 1
        var member1 = new Member
        {
            Id = 1,
            FullName = "Aarav Patel",
            Email = "aarav.patel@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543210",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 1,
                MemberId = 1,
                CompanyName = "Patel Textiles Ltd",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1,
                BusinessCapabilities = "Weaving, Spinning"
            }
        };

        // Member 2
        var member2 = new Member
        {
            Id = 2,
            FullName = "Bhavna Shah",
            Email = "bhavna.shah@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543211",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 2,
                MemberId = 2,
                CompanyName = "Shah Garments",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1,
                BusinessCapabilities = "Garment Manufacturing"
            }
        };

        // Member 3
        var member3 = new Member
        {
            Id = 3,
            FullName = "Chirag Mehta",
            Email = "chirag.mehta@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543212",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 3,
                MemberId = 3,
                CompanyName = "Mehta Exports",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1,
                BusinessCapabilities = "Export, Logistics"
            }
        };

        _dbContext.Members.AddRange(member1, member2, member3);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task SendRequest_SelfRequest_ReturnsError()
    {
        var result = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(1));

        Assert.False(result.Success);
        Assert.Contains("yourself", result.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Null(result.Connection);
    }

    [Fact]
    public async Task SendRequest_NonExistentRecipient_ReturnsError()
    {
        var result = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(999));

        Assert.False(result.Success);
        Assert.Contains("not found", result.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendRequest_ValidRecipient_CreatesPendingRequest()
    {
        var result = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2, "Let's connect"));

        Assert.True(result.Success);
        Assert.NotNull(result.Connection);
        Assert.Equal("Pending", result.Connection!.Status);
        Assert.Equal(1, result.Connection.RequesterMemberId);
        Assert.Equal(2, result.Connection.RecipientMemberId);
        Assert.Equal("Let's connect", result.Connection.Note);

        var inDb = await _dbContext.MemberConnections.FirstOrDefaultAsync(c => c.RequesterMemberId == 1 && c.RecipientMemberId == 2);
        Assert.NotNull(inDb);
        Assert.Equal(ConnectionStatusEnum.Pending, inDb!.Status);
    }

    [Fact]
    public async Task SendRequest_DuplicateActivePending_ReturnsError()
    {
        // First request
        await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));

        // Attempt duplicate request from same requester
        var duplicate = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));

        Assert.False(duplicate.Success);
        Assert.Contains("already pending", duplicate.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendRequest_AlreadyConnected_ReturnsError()
    {
        // Pre-create accepted connection
        _dbContext.MemberConnections.Add(new MemberConnection
        {
            RequesterMemberId = 1,
            RecipientMemberId = 2,
            Status = ConnectionStatusEnum.Accepted,
            CreatedAtUtc = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();

        var result = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));

        Assert.False(result.Success);
        Assert.Contains("already connected", result.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendRequest_Reactivates_CancelledOrRejectedRequest()
    {
        var oldConn = new MemberConnection
        {
            RequesterMemberId = 1,
            RecipientMemberId = 2,
            Status = ConnectionStatusEnum.Cancelled,
            CreatedAtUtc = DateTime.UtcNow.AddDays(-5)
        };
        _dbContext.MemberConnections.Add(oldConn);
        await _dbContext.SaveChangesAsync();

        var result = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2, "Reconnecting"));

        Assert.True(result.Success);
        Assert.Equal("Pending", result.Connection!.Status);
        Assert.Equal("Reconnecting", result.Connection.Note);

        var updated = await _dbContext.MemberConnections.FirstOrDefaultAsync(c => c.Id == oldConn.Id);
        Assert.NotNull(updated);
        Assert.Equal(ConnectionStatusEnum.Pending, updated!.Status);
    }

    [Fact]
    public async Task AcceptRequest_RecipientCanAccept_TransitionsToAccepted()
    {
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var requestId = sendResult.Connection!.Id;

        var acceptResult = await _connectionService.AcceptRequestAsync(2, requestId);

        Assert.True(acceptResult.Success);
        Assert.Equal("Accepted", acceptResult.Connection!.Status);
        Assert.NotNull(acceptResult.Connection.RespondedAtUtc);

        var inDb = await _dbContext.MemberConnections.FindAsync(requestId);
        Assert.Equal(ConnectionStatusEnum.Accepted, inDb!.Status);
    }

    [Fact]
    public async Task AcceptRequest_NonRecipient_ReturnsUnauthorizedError()
    {
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var requestId = sendResult.Connection!.Id;

        // Requester (Member 1) or third party (Member 3) tries to accept
        var acceptResult = await _connectionService.AcceptRequestAsync(1, requestId);

        Assert.False(acceptResult.Success);
        Assert.Contains("not authorized", acceptResult.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task RejectRequest_RecipientCanReject_TransitionsToRejected()
    {
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var requestId = sendResult.Connection!.Id;

        var rejectResult = await _connectionService.RejectRequestAsync(2, requestId);

        Assert.True(rejectResult.Success);
        Assert.Equal("Rejected", rejectResult.Connection!.Status);

        var inDb = await _dbContext.MemberConnections.FindAsync(requestId);
        Assert.Equal(ConnectionStatusEnum.Rejected, inDb!.Status);
    }

    [Fact]
    public async Task CancelRequest_RequesterCanCancel_TransitionsToCancelled()
    {
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var requestId = sendResult.Connection!.Id;

        var cancelResult = await _connectionService.CancelRequestAsync(1, requestId);

        Assert.True(cancelResult.Success);
        Assert.Equal("Cancelled", cancelResult.Connection!.Status);

        var inDb = await _dbContext.MemberConnections.FindAsync(requestId);
        Assert.Equal(ConnectionStatusEnum.Cancelled, inDb!.Status);
    }

    [Fact]
    public async Task CancelRequest_NonRequester_ReturnsUnauthorizedError()
    {
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var requestId = sendResult.Connection!.Id;

        // Recipient tries to cancel
        var cancelResult = await _connectionService.CancelRequestAsync(2, requestId);

        Assert.False(cancelResult.Success);
        Assert.Contains("not authorized", cancelResult.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task RemoveConnection_OnlyAcceptedConnectionsCanBeRemoved()
    {
        // 1. Pending connection cannot be removed with RemoveConnection
        var sendResult = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        var removePending = await _connectionService.RemoveConnectionAsync(1, 2);
        Assert.False(removePending.Success);

        // 2. Accept connection
        await _connectionService.AcceptRequestAsync(2, sendResult.Connection!.Id);

        // 3. Remove accepted connection
        var removeResult = await _connectionService.RemoveConnectionAsync(1, 2);
        Assert.True(removeResult.Success);

        var remaining = await _dbContext.MemberConnections.FirstOrDefaultAsync(c =>
            (c.RequesterMemberId == 1 && c.RecipientMemberId == 2) ||
            (c.RequesterMemberId == 2 && c.RecipientMemberId == 1));
        Assert.Null(remaining);
    }

    [Fact]
    public async Task GetMyConnections_ReturnsOnlyAcceptedConnections()
    {
        // Member 1 -> Member 2 accepted
        var req1 = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        await _connectionService.AcceptRequestAsync(2, req1.Connection!.Id);

        // Member 1 -> Member 3 pending
        await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(3));

        var connections = await _connectionService.GetMyConnectionsAsync(1);

        Assert.Equal(1, connections.TotalCount);
        Assert.Single(connections.Items);
        Assert.Equal(2, connections.Items[0].MemberId);
        Assert.Equal("Shah Garments", connections.Items[0].CompanyName);
        Assert.Equal("Connected", connections.Items[0].ConnectionStatus);
    }

    [Fact]
    public async Task GetReceivedAndSentRequests_ReturnsAccuratePendingLists()
    {
        await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2, "Hello Bhavna"));
        await _connectionService.SendRequestAsync(3, new CreateConnectionRequestDto(2, "Hello from Chirag"));

        var receivedForMember2 = await _connectionService.GetReceivedRequestsAsync(2);
        Assert.Equal(2, receivedForMember2.TotalCount);

        var sentForMember1 = await _connectionService.GetSentRequestsAsync(1);
        Assert.Equal(1, sentForMember1.TotalCount);
        Assert.Equal(2, sentForMember1.Items[0].MemberId);
    }

    [Fact]
    public async Task DirectoryService_ResolvesDynamicConnectionStatusCorrectly()
    {
        // Member 1 connects to Member 2 (Accepted)
        var req = await _connectionService.SendRequestAsync(1, new CreateConnectionRequestDto(2));
        await _connectionService.AcceptRequestAsync(2, req.Connection!.Id);

        // Member 3 sends request to Member 1 (Pending)
        await _connectionService.SendRequestAsync(3, new CreateConnectionRequestDto(1));

        // When Member 1 searches directory:
        var dirResponse = await _directoryService.SearchBusinessesAsync(new BusinessDirectoryFilterDto(), 1);

        var selfItem = dirResponse.Items.First(i => i.MemberId == 1);
        var connectedItem = dirResponse.Items.First(i => i.MemberId == 2);
        var pendingReceivedItem = dirResponse.Items.First(i => i.MemberId == 3);

        Assert.Equal("Self", selfItem.ConnectionStatus);
        Assert.Equal("Connected", connectedItem.ConnectionStatus);
        Assert.Equal("PendingReceived", pendingReceivedItem.ConnectionStatus);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }
}
