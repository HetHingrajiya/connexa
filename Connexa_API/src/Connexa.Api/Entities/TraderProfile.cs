namespace Connexa.Api.Entities;

public class TraderProfile
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string TradingName { get; set; } = string.Empty;
    public string Capabilities { get; set; } = string.Empty;
    public string ProductsSupplied { get; set; } = string.Empty;
    public string ServiceCoverage { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public Member Member { get; set; } = null!;
}
