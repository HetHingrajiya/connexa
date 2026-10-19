namespace Connexa.Api.Services.Email;

public record EmailDispatchResult(
    bool Accepted,
    bool IsSimulated,
    string? ProviderMessageId,
    string? ErrorMessage
);
