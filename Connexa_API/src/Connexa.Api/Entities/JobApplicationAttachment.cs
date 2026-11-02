namespace Connexa.Api.Entities;

public class JobApplicationAttachment
{
    public int Id { get; set; }

    public int JobApplicationId { get; set; }
    public JobApplication JobApplication { get; set; } = null!;

    public string FileName { get; set; } = string.Empty;
    public string FilePath { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }

    public DateTime UploadedAtUtc { get; set; } = DateTime.UtcNow;
}

