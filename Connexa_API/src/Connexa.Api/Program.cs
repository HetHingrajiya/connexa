using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.Middleware;
using Connexa.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Configure Database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=LAPTOP-LIESC4N1\\SQLEXPRESS01;Database=Connexa;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

builder.Services.AddDbContext<ConnexaDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorNumbersToAdd: null);
    });
});

// Register Domain Services
builder.Services.AddScoped<IMasterDataService, MasterDataService>();
builder.Services.AddScoped<ISqliteMigrationService, SqliteMigrationService>();

// Configure Controllers and JSON Formatting
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
        options.JsonSerializerOptions.WriteIndented = false;
    });

// Configure CORS for Flutter Web, mobile emulators, and local development
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevelopmentCorsPolicy", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
        {
            if (string.IsNullOrWhiteSpace(origin)) return false;
            try
            {
                var uri = new Uri(origin);
                // Allow localhost and 127.0.0.1 on any port (Flutter Web / Desktop)
                if (uri.Host == "localhost" || uri.Host == "127.0.0.1") return true;
                // Allow local network IP addresses for physical device development
                if (uri.Host.StartsWith("192.168.") || uri.Host.StartsWith("10.0.") || uri.Host == "10.0.2.2") return true;
                return false;
            }
            catch
            {
                return false;
            }
        })
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials();
    });

    options.AddPolicy("ProductionCorsPolicy", policy =>
    {
        // Strict production origins configured from environment
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure Middleware Pipeline
app.UseMiddleware<GlobalExceptionMiddleware>();

// Request logging middleware
app.Use(async (context, next) =>
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    await next();
    sw.Stop();
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("[{Timestamp:O}] {Method} {Path} - {StatusCode} ({Elapsed}ms)",
        DateTime.UtcNow, context.Request.Method, context.Request.Path, context.Response.StatusCode, sw.ElapsedMilliseconds);
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors("DevelopmentCorsPolicy");
}
else
{
    app.UseCors("ProductionCorsPolicy");
}

app.UseAuthorization();
app.MapControllers();

app.Run();

// Expose Program class for WebApplicationFactory in integration tests
public partial class Program { }