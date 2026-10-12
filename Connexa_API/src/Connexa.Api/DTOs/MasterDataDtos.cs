namespace Connexa.Api.DTOs;

public record IndustryDto(
    string Id,
    string Name,
    string? Code,
    string? Description
);

public record BusinessGroupDto(
    string Id,
    string IndustryId,
    string Name,
    string? Code,
    string? Description
);

public record SubGroupDto(
    string Id,
    string BusinessGroupId,
    string Name,
    string? Code,
    string? Description
);

public record CategoryDto(
    string Id,
    string SubGroupId,
    string Name,
    string? Code,
    string? Description
);

public record ParentRefDto(
    string Id,
    string Name,
    string? IndustryId = null,
    string? BusinessGroupId = null
);

public class ApiResponse<T>
{
    public bool Success { get; set; } = true;
    public ParentRefDto? Parent { get; set; }
    public int Count { get; set; }
    public T Data { get; set; } = default!;
    public string? Message { get; set; }

    public static ApiResponse<T> Ok(T data, int count, ParentRefDto? parent = null) =>
        new() { Success = true, Data = data, Count = count, Parent = parent };

    public static ApiResponse<T> Fail(string message) =>
        new() { Success = false, Message = message };
}

public class ErrorResponseDto
{
    public bool Success { get; set; } = false;
    public string Message { get; set; } = string.Empty;
    public string? Error { get; set; }
}

public record HealthResponseDto(
    string Status,
    string Service,
    string? Version,
    string Timestamp
);