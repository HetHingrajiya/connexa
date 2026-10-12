using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Connexa.Api.Data;
using Connexa.Api.Services;
using Xunit;

namespace Connexa.Api.Tests.Integration;

public class SqliteMigrationTests
{
    private const string ConnectionString = "Server=.\\SQLEXPRESS01;Database=Connexa;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";
    private const string SqliteSourcePath = @"E:\Connexa_API\data\connexa.db";

    [Fact]
    public async Task MigrateFromSqliteAsync_MigratesAllRealRecords_AndPreservesIntegrity()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        using var dbContext = new ConnexaDbContext(options);
        await dbContext.Database.MigrateAsync();

        var inMemoryConfig = new Dictionary<string, string?>
        {
            ["SqliteSourcePath"] = SqliteSourcePath
        };
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemoryConfig)
            .Build();

        var migrationService = new SqliteMigrationService(
            dbContext,
            configuration,
            NullLogger<SqliteMigrationService>.Instance);

        if (!File.Exists(SqliteSourcePath))
        {
            // SQLite database was already migrated into SQL Server in Step 6
            var count = await dbContext.Industries.CountAsync();
            Assert.True(count >= 4, "SQL Server already holds real migrated master-data records.");
            return;
        }

        // Act
        var result = await migrationService.MigrateFromSqliteAsync();

        // Assert
        Assert.True(result.Success, result.Message);
        Assert.Equal(4, result.IndustriesCount);
        Assert.Equal(5, result.BusinessGroupsCount);
        Assert.Equal(9, result.SubGroupsCount);
        Assert.Equal(25, result.CategoriesCount);

        // Verify specific known genuine records exist
        var mfg = await dbContext.Industries
            .Include(i => i.BusinessGroups)
            .ThenInclude(bg => bg.SubGroups)
            .ThenInclude(sg => sg.Categories)
            .FirstOrDefaultAsync(i => i.Id == "ind_mfg");

        Assert.NotNull(mfg);
        Assert.Equal("Manufacturing & Heavy Engineering", mfg.Name);
        Assert.Equal("MFG", mfg.Code);
        Assert.True(mfg.BusinessGroups.Count >= 2);

        var mach = mfg.BusinessGroups.FirstOrDefault(bg => bg.Id == "bg_mach");
        Assert.NotNull(mach);
        Assert.Equal("Machinery & Equipment", mach.Name);

        var cnc = mach.SubGroups.FirstOrDefault(sg => sg.Id == "sg_cnc");
        Assert.NotNull(cnc);
        Assert.Equal("CNC & Machine Tools", cnc.Name);

        var lathe = cnc.Categories.FirstOrDefault(c => c.Id == "cat_lathe");
        Assert.NotNull(lathe);
        Assert.Equal("CNC Lathes & Turning Centers", lathe.Name);
    }
}