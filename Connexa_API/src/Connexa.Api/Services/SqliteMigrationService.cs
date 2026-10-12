using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.Entities;

namespace Connexa.Api.Services;

public class SqliteMigrationService : ISqliteMigrationService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SqliteMigrationService> _logger;

    public SqliteMigrationService(
        ConnexaDbContext dbContext,
        IConfiguration configuration,
        ILogger<SqliteMigrationService> logger)
    {
        _dbContext = dbContext;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<MigrationResult> MigrateFromSqliteAsync(string? sqliteDbPath = null, CancellationToken cancellationToken = default)
    {
        var targetSqlitePath = sqliteDbPath 
            ?? _configuration["SqliteSourcePath"] 
            ?? @"E:\Connexa_API\data\connexa.db";

        _logger.LogInformation("Starting SQLite-to-SQL Server data migration from source: {Path}", targetSqlitePath);

        if (!File.Exists(targetSqlitePath))
        {
            var msg = $"Source SQLite database file not found at: {targetSqlitePath}";
            _logger.LogError("{Message}", msg);
            return new MigrationResult(false, 0, 0, 0, 0, msg, new[] { msg });
        }

        try
        {
            // Read all records from SQLite
            var connectionString = new SqliteConnectionStringBuilder
            {
                DataSource = targetSqlitePath,
                Mode = SqliteOpenMode.ReadOnly
            }.ToString();

            using var sqliteConn = new SqliteConnection(connectionString);
            await sqliteConn.OpenAsync(cancellationToken);

            var rawIndustries = new List<Industry>();
            var rawGroups = new List<BusinessGroup>();
            var rawSubGroups = new List<SubGroup>();
            var rawCategories = new List<Category>();

            // 1. Read industries
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, name, code, description, created_at FROM industries";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    rawIndustries.Add(new Industry
                    {
                        Id = reader.GetString(0),
                        Name = reader.GetString(1),
                        Code = reader.IsDBNull(2) ? null : reader.GetString(2),
                        Description = reader.IsDBNull(3) ? null : reader.GetString(3),
                        CreatedAt = reader.IsDBNull(4) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(4))
                    });
                }
            }

            // 2. Read business_groups
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, industry_id, name, code, description, created_at FROM business_groups";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    rawGroups.Add(new BusinessGroup
                    {
                        Id = reader.GetString(0),
                        IndustryId = reader.GetString(1),
                        Name = reader.GetString(2),
                        Code = reader.IsDBNull(3) ? null : reader.GetString(3),
                        Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                        CreatedAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5))
                    });
                }
            }

            // 3. Read sub_groups
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, business_group_id, name, code, description, created_at FROM sub_groups";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    rawSubGroups.Add(new SubGroup
                    {
                        Id = reader.GetString(0),
                        BusinessGroupId = reader.GetString(1),
                        Name = reader.GetString(2),
                        Code = reader.IsDBNull(3) ? null : reader.GetString(3),
                        Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                        CreatedAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5))
                    });
                }
            }

            // 4. Read categories
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, sub_group_id, name, code, description, created_at FROM categories";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    rawCategories.Add(new Category
                    {
                        Id = reader.GetString(0),
                        SubGroupId = reader.GetString(1),
                        Name = reader.GetString(2),
                        Code = reader.IsDBNull(3) ? null : reader.GetString(3),
                        Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                        CreatedAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5))
                    });
                }
            }

            _logger.LogInformation(
                "Parsed from SQLite: {IndCount} industries, {BgCount} business groups, {SgCount} sub groups, {CatCount} categories.",
                rawIndustries.Count, rawGroups.Count, rawSubGroups.Count, rawCategories.Count);

            // Insert into SQL Server in strict hierarchical order
            foreach (var ind in rawIndustries)
            {
                if (!await _dbContext.Industries.AnyAsync(i => i.Id == ind.Id, cancellationToken))
                {
                    _dbContext.Industries.Add(ind);
                }
            }
            await _dbContext.SaveChangesAsync(cancellationToken);

            foreach (var bg in rawGroups)
            {
                if (!await _dbContext.BusinessGroups.AnyAsync(g => g.Id == bg.Id, cancellationToken))
                {
                    _dbContext.BusinessGroups.Add(bg);
                }
            }
            await _dbContext.SaveChangesAsync(cancellationToken);

            foreach (var sg in rawSubGroups)
            {
                if (!await _dbContext.SubGroups.AnyAsync(s => s.Id == sg.Id, cancellationToken))
                {
                    _dbContext.SubGroups.Add(sg);
                }
            }
            await _dbContext.SaveChangesAsync(cancellationToken);

            foreach (var cat in rawCategories)
            {
                if (!await _dbContext.Categories.AnyAsync(c => c.Id == cat.Id, cancellationToken))
                {
                    _dbContext.Categories.Add(cat);
                }
            }
            await _dbContext.SaveChangesAsync(cancellationToken);

            // Validation
            return await ValidateDataIntegrityAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Data migration failed: {Message}", ex.Message);
            return new MigrationResult(false, 0, 0, 0, 0, $"Migration failed: {ex.Message}", new[] { ex.ToString() });
        }
    }

    public async Task<MigrationResult> ValidateDataIntegrityAsync(CancellationToken cancellationToken = default)
    {
        var indCount = await _dbContext.Industries.CountAsync(cancellationToken);
        var bgCount = await _dbContext.BusinessGroups.CountAsync(cancellationToken);
        var sgCount = await _dbContext.SubGroups.CountAsync(cancellationToken);
        var catCount = await _dbContext.Categories.CountAsync(cancellationToken);

        var errors = new List<string>();

        // Verify orphan business groups
        var orphanBgs = await _dbContext.BusinessGroups
            .Where(bg => !_dbContext.Industries.Any(i => i.Id == bg.IndustryId))
            .CountAsync(cancellationToken);
        if (orphanBgs > 0) errors.Add($"Found {orphanBgs} orphaned business groups with invalid industryId.");

        // Verify orphan sub groups
        var orphanSgs = await _dbContext.SubGroups
            .Where(sg => !_dbContext.BusinessGroups.Any(bg => bg.Id == sg.BusinessGroupId))
            .CountAsync(cancellationToken);
        if (orphanSgs > 0) errors.Add($"Found {orphanSgs} orphaned sub groups with invalid businessGroupId.");

        // Verify orphan categories
        var orphanCats = await _dbContext.Categories
            .Where(c => !_dbContext.SubGroups.Any(sg => sg.Id == c.SubGroupId))
            .CountAsync(cancellationToken);
        if (orphanCats > 0) errors.Add($"Found {orphanCats} orphaned categories with invalid subGroupId.");

        var isSuccess = errors.Count == 0 && indCount >= 4 && bgCount >= 5 && sgCount >= 9 && catCount >= 25;
        var msg = isSuccess
            ? $"Data integrity verified: {indCount} Industries, {bgCount} Business Groups, {sgCount} SubGroups, {catCount} Categories."
            : $"Data validation issues encountered: {string.Join(", ", errors)}";

        _logger.LogInformation("{Message}", msg);
        return new MigrationResult(isSuccess, indCount, bgCount, sgCount, catCount, msg, errors.Count > 0 ? errors : null);
    }
}