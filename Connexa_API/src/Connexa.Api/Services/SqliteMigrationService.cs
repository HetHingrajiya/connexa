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
            var industryMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, name, code, description, created_at FROM industries";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    var rawId = reader.GetString(0);
                    var name = reader.GetString(1);
                    var code = reader.IsDBNull(2) ? null : reader.GetString(2);
                    var desc = reader.IsDBNull(3) ? null : reader.GetString(3);
                    var createdAt = reader.IsDBNull(4) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(4));

                    var existing = await _dbContext.Industries.FirstOrDefaultAsync(i => i.Name == name, cancellationToken);
                    if (existing == null)
                    {
                        existing = new Industry { Name = name, Code = code, Description = desc, CreatedAt = createdAt };
                        _dbContext.Industries.Add(existing);
                        await _dbContext.SaveChangesAsync(cancellationToken);
                    }
                    industryMap[rawId] = existing.Id;
                }
            }

            // 2. Read business_groups
            var groupMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, industry_id, name, code, description, created_at FROM business_groups";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    var rawId = reader.GetString(0);
                    var rawIndId = reader.GetString(1);
                    var name = reader.GetString(2);
                    var code = reader.IsDBNull(3) ? null : reader.GetString(3);
                    var desc = reader.IsDBNull(4) ? null : reader.GetString(4);
                    var createdAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5));

                    if (industryMap.TryGetValue(rawIndId, out var mappedIndId))
                    {
                        var existing = await _dbContext.BusinessGroups.FirstOrDefaultAsync(g => g.IndustryId == mappedIndId && g.Name == name, cancellationToken);
                        if (existing == null)
                        {
                            existing = new BusinessGroup { IndustryId = mappedIndId, Name = name, Code = code, Description = desc, CreatedAt = createdAt };
                            _dbContext.BusinessGroups.Add(existing);
                            await _dbContext.SaveChangesAsync(cancellationToken);
                        }
                        groupMap[rawId] = existing.Id;
                    }
                }
            }

            // 3. Read sub_groups
            var subGroupMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, business_group_id, name, code, description, created_at FROM sub_groups";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    var rawId = reader.GetString(0);
                    var rawBgId = reader.GetString(1);
                    var name = reader.GetString(2);
                    var code = reader.IsDBNull(3) ? null : reader.GetString(3);
                    var desc = reader.IsDBNull(4) ? null : reader.GetString(4);
                    var createdAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5));

                    if (groupMap.TryGetValue(rawBgId, out var mappedBgId))
                    {
                        var existing = await _dbContext.SubGroups.FirstOrDefaultAsync(sg => sg.BusinessGroupId == mappedBgId && sg.Name == name, cancellationToken);
                        if (existing == null)
                        {
                            existing = new SubGroup { BusinessGroupId = mappedBgId, Name = name, Code = code, Description = desc, CreatedAt = createdAt };
                            _dbContext.SubGroups.Add(existing);
                            await _dbContext.SaveChangesAsync(cancellationToken);
                        }
                        subGroupMap[rawId] = existing.Id;
                    }
                }
            }

            // 4. Read categories
            using (var cmd = sqliteConn.CreateCommand())
            {
                cmd.CommandText = "SELECT id, sub_group_id, name, code, description, created_at FROM categories";
                using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    var rawSgId = reader.GetString(1);
                    var name = reader.GetString(2);
                    var code = reader.IsDBNull(3) ? null : reader.GetString(3);
                    var desc = reader.IsDBNull(4) ? null : reader.GetString(4);
                    var createdAt = reader.IsDBNull(5) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(5));

                    if (subGroupMap.TryGetValue(rawSgId, out var mappedSgId))
                    {
                        var existing = await _dbContext.Categories.FirstOrDefaultAsync(c => c.SubGroupId == mappedSgId && c.Name == name, cancellationToken);
                        if (existing == null)
                        {
                            existing = new Category { SubGroupId = mappedSgId, Name = name, Code = code, Description = desc, CreatedAt = createdAt };
                            _dbContext.Categories.Add(existing);
                            await _dbContext.SaveChangesAsync(cancellationToken);
                        }
                    }
                }
            }

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