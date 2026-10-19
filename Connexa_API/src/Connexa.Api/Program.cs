using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.Middleware;
using Connexa.Api.Services;
using Connexa.Api.Services.Auth;
using Connexa.Api.Services.Directory;
using Connexa.Api.Services.Email;
using Connexa.Api.Services.Registration;
using Connexa.Api.Services.Verification;
using Connexa.Api.Services.WhatsApp;

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

// Bind Options
builder.Services.Configure<WhatsAppOptions>(builder.Configuration.GetSection(WhatsAppOptions.SectionName));
builder.Services.Configure<EmailOptions>(builder.Configuration.GetSection(EmailOptions.SectionName));
builder.Services.Configure<OtpSecurityOptions>(builder.Configuration.GetSection(OtpSecurityOptions.SectionName));
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));

// Register HttpClient for WhatsApp Cloud API
builder.Services.AddHttpClient<MetaCloudApiWhatsAppProvider>();

// Register Cryptography & Providers
builder.Services.AddSingleton<IOtpCryptographyService, OtpCryptographyService>();
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();

builder.Services.AddScoped<MetaCloudApiWhatsAppProvider>();
builder.Services.AddScoped<DevelopmentWhatsAppProvider>();
builder.Services.AddScoped<IWhatsAppProvider>(sp =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<WhatsAppOptions>>().Value;
    if (options.Provider.Equals("MetaCloudApi", StringComparison.OrdinalIgnoreCase) || options.MetaCloudApi.IsConfigured)
    {
        return sp.GetRequiredService<MetaCloudApiWhatsAppProvider>();
    }
    return sp.GetRequiredService<DevelopmentWhatsAppProvider>();
});

// Register Email Providers (Gmail SMTP / Development simulated fallback)
builder.Services.AddScoped<GmailSmtpEmailProvider>();
builder.Services.AddScoped<DevelopmentEmailProvider>();
builder.Services.AddScoped<IEmailProvider>(sp =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<EmailOptions>>().Value;
    if (options.IsConfigured)
    {
        return sp.GetRequiredService<GmailSmtpEmailProvider>();
    }
    return sp.GetRequiredService<DevelopmentEmailProvider>();
});

// Register Domain & Auth Services
builder.Services.AddScoped<IPhoneVerificationService, PhoneVerificationService>();
builder.Services.AddScoped<IEmailVerificationService, EmailVerificationService>();
builder.Services.AddScoped<IRegistrationVerificationPolicyService, RegistrationVerificationPolicyService>();
builder.Services.AddScoped<IMasterDataService, MasterDataService>();
builder.Services.AddScoped<ISqliteMigrationService, SqliteMigrationService>();
builder.Services.AddScoped<IRegistrationService, RegistrationService>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IDirectoryService, DirectoryService>();

// Configure JWT Bearer Authentication
var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var signingKey = jwtSection["SigningKey"] ?? "ConnexaEnterpriseSecureJwtSecretKey2026!MustBe32BytesOrLonger#";
var issuer = jwtSection["Issuer"] ?? "Connexa.Api";
var audience = jwtSection["Audience"] ?? "Connexa.App";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = issuer,
        ValidateAudience = true,
        ValidAudience = audience,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromSeconds(30)
    };
    options.Events = new JwtBearerEvents
    {
        OnChallenge = context =>
        {
            context.HandleResponse();
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            context.Response.ContentType = "application/json";
            return context.Response.WriteAsync("{\"success\":false,\"message\":\"Unauthorized. Valid Bearer access token required.\"}");
        },
        OnForbidden = context =>
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            context.Response.ContentType = "application/json";
            return context.Response.WriteAsync("{\"success\":false,\"message\":\"Forbidden. You do not have permission to access this resource.\"}");
        }
    };
});

builder.Services.AddAuthorization();

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
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Connexa API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

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

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

// Expose Program class for WebApplicationFactory in integration tests
public partial class Program { }