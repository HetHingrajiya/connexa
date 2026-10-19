namespace Connexa.Api.Services;

public record MigrationResult(
    bool Success,
    int IndustriesCount,
    int BusinessGroupsCount,
    int SubGroupsCount,
    int CategoriesCount,
    string Message,
    IReadOnlyList<string>? Errors = null
);

public interface ISqliteMigrationService
{
    Task<MigrationResult> MigrateFromSqliteAsync(string? sqliteDbPath = null, CancellationToken cancellationToken = default);
    Task<MigrationResult> ValidateDataIntegrityAsync(CancellationToken cancellationToken = default);
}