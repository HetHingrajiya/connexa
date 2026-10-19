namespace Connexa.Api.Configuration;

public class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Connexa.Api";
    public string Audience { get; set; } = "Connexa.App";
    public string SigningKey { get; set; } = "ConnexaEnterpriseSecureJwtSecretKey2026!MustBe32BytesOrLonger#";
    public int AccessTokenExpirationMinutes { get; set; } = 15;
    public int RefreshTokenExpirationDays { get; set; } = 7;
}
