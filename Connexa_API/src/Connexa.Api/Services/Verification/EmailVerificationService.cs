using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Email;

namespace Connexa.Api.Services.Verification;

public class EmailVerificationService : IEmailVerificationService
{
    private const string EmailPurpose = "RegistrationVerification_Email";

    private readonly ConnexaDbContext _dbContext;
    private readonly IEmailProvider _emailProvider;
    private readonly IOtpCryptographyService _crypto;
    private readonly OtpSecurityOptions _options;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<EmailVerificationService> _logger;

    public EmailVerificationService(
        ConnexaDbContext dbContext,
        IEmailProvider emailProvider,
        IOtpCryptographyService crypto,
        IOptions<OtpSecurityOptions> options,
        IWebHostEnvironment environment,
        ILogger<EmailVerificationService> logger)
    {
        _dbContext = dbContext;
        _emailProvider = emailProvider;
        _crypto = crypto;
        _options = options.Value;
        _environment = environment;
        _logger = logger;
    }

    public async Task<(bool Success, SendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null)
        {
            return (false, null, "Request body cannot be null.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.RegistrationFlowId))
        {
            return (false, null, "RegistrationFlowId is required to correlate the verification session.", 400);
        }

        string normalizedEmail;
        try
        {
            normalizedEmail = _crypto.NormalizeEmail(request.Email);
        }
        catch (ArgumentException ex)
        {
            return (false, null, ex.Message, 400);
        }

        var maskedEmail = _crypto.MaskEmail(normalizedEmail);
        var now = DateTime.UtcNow;

        // 1. IP rate limiting (requests per 10 minutes)
        if (!string.IsNullOrWhiteSpace(clientIp))
        {
            var tenMinutesAgo = now.AddMinutes(-10);
            var ipRequestCount = await _dbContext.OtpChallenges
                .CountAsync(c => c.RequestIpAddress == clientIp && c.CreatedAtUtc >= tenMinutesAgo, cancellationToken);

            if (ipRequestCount >= _options.MaxRequestsPerTenMinutesPerIp)
            {
                _logger.LogWarning("[EmailVerification] Rate limit exceeded for IP {IpAddress}.", clientIp);
                return (false, null, "Too many verification requests from this network. Please try again later.", 429);
            }
        }

        // 2. Email rate limiting (challenges created in the last hour)
        var oneHourAgo = now.AddHours(-1);
        var emailChallengeCount = await _dbContext.OtpChallenges
            .CountAsync(c => c.Email == normalizedEmail && c.CreatedAtUtc >= oneHourAgo, cancellationToken);

        if (emailChallengeCount >= _options.MaxChallengesPerHourPerEmail)
        {
            _logger.LogWarning("[EmailVerification] Hourly limit exceeded for destination {MaskedEmail}.", maskedEmail);
            return (false, null, "Hourly verification request limit exceeded for this email address. Please try again later.", 429);
        }

        // 3. Resend cooldown check against any active pending challenge for this email
        var activePendingChallenge = await _dbContext.OtpChallenges
            .Where(c => c.Email == normalizedEmail && c.Purpose == EmailPurpose && c.Status == OtpChallengeStatus.Pending && c.ExpiresAtUtc > now)
            .OrderByDescending(c => c.CreatedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

        if (activePendingChallenge != null)
        {
            var lastActivityTime = activePendingChallenge.LastResentAtUtc ?? activePendingChallenge.CreatedAtUtc;
            var elapsedSeconds = (now - lastActivityTime).TotalSeconds;
            if (elapsedSeconds < _options.ResendCooldownSeconds)
            {
                var remaining = (int)Math.Ceiling(_options.ResendCooldownSeconds - elapsedSeconds);
                _logger.LogInformation("[EmailVerification] Cooldown active for {MaskedEmail}. Remaining: {Remaining}s", maskedEmail, remaining);
                return (false, null, $"Please wait {remaining} seconds before requesting a new verification code.", 429);
            }
        }

        // 4. Supersede prior active pending challenges for this email & flow
        var existingPendingChallenges = await _dbContext.OtpChallenges
            .Where(c => c.Email == normalizedEmail && c.Purpose == EmailPurpose && c.Status == OtpChallengeStatus.Pending)
            .ToListAsync(cancellationToken);

        foreach (var challenge in existingPendingChallenges)
        {
            challenge.Status = OtpChallengeStatus.Superseded;
        }

        // 5. Generate secure random 6-digit OTP, salt, and keyed HMAC
        var otpCode = _crypto.GenerateOtpCode();
        var salt = _crypto.GenerateSalt();
        var otpHash = _crypto.HashEmailOtp(otpCode, salt, normalizedEmail);

        // In Production, plaintext OTP is NEVER stored in database.
        var plaintextStorage = _environment.IsDevelopment() ? otpCode : string.Empty;

        var newChallenge = new OtpChallenge
        {
            Email = normalizedEmail,
            PhoneNumber = null,
            OtpCode = plaintextStorage,
            OtpHashingSalt = salt,
            OtpHash = otpHash,
            Purpose = EmailPurpose,
            RegistrationFlowId = request.RegistrationFlowId.Trim(),
            CreatedAtUtc = now,
            ExpiresAtUtc = now.AddSeconds(_options.OtpLifetimeSeconds),
            MaxAttempts = _options.MaxAttempts,
            Status = OtpChallengeStatus.Pending,
            RequestIpAddress = clientIp
        };

        _dbContext.OtpChallenges.Add(newChallenge);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // 6. Dispatch via configured Email provider
        var dispatchResult = await _emailProvider.SendOtpEmailAsync(
            normalizedEmail,
            otpCode,
            request.RegistrationFlowId,
            cancellationToken);

        if (!dispatchResult.Accepted)
        {
            _logger.LogError("[EmailVerification] Provider dispatch failed for {MaskedEmail}: {Error}",
                maskedEmail, dispatchResult.ErrorMessage);

            // Mark challenge expired/failed so a failed dispatch does not leave a usable challenge
            newChallenge.Status = OtpChallengeStatus.Expired;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return (false, null, dispatchResult.ErrorMessage ?? "Unable to deliver verification code via email. Please check your email and retry.", 502);
        }

        // Update provider message ID
        newChallenge.ProviderMessageId = dispatchResult.ProviderMessageId;
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[EmailVerification] OTP challenge {ChallengeId} dispatched successfully to {MaskedEmail} (Provider: {Provider}).",
            newChallenge.Id, maskedEmail, _emailProvider.ProviderName);

        var isLive = !dispatchResult.IsSimulated;
        var message = isLive
            ? "Verification code dispatched via email."
            : "Development mode: Gmail SMTP is unconfigured. Simulated email OTP was created.";

        var responseDto = new SendEmailOtpResponseDto(
            ChallengeId: newChallenge.Id,
            MaskedEmail: maskedEmail,
            ExpiresAtUtc: newChallenge.ExpiresAtUtc,
            CooldownSeconds: _options.ResendCooldownSeconds,
            Accepted: true,
            Status: "Pending",
            Message: message,
            IsLiveDelivery: isLive
        );

        return (true, responseDto, null, 200);
    }

    public async Task<(bool Success, ResendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null || request.ChallengeId <= 0)
        {
            return (false, null, "Valid ChallengeId is required.", 400);
        }

        var challenge = await _dbContext.OtpChallenges
            .FirstOrDefaultAsync(c => c.Id == request.ChallengeId &&
                                      c.Purpose == EmailPurpose &&
                                      c.RegistrationFlowId == request.RegistrationFlowId.Trim(), cancellationToken);

        if (challenge == null || string.IsNullOrWhiteSpace(challenge.Email))
        {
            return (false, null, "Verification challenge not found or session mismatch.", 404);
        }

        var maskedEmail = _crypto.MaskEmail(challenge.Email);
        var now = DateTime.UtcNow;

        if (challenge.Status == OtpChallengeStatus.Verified)
        {
            return (false, null, "Email address has already been verified.", 400);
        }

        if (challenge.Status != OtpChallengeStatus.Pending)
        {
            return (false, null, $"Challenge is no longer active ({challenge.Status}). Please request a new verification code.", 400);
        }

        if (now > challenge.ExpiresAtUtc)
        {
            challenge.Status = OtpChallengeStatus.Expired;
            await _dbContext.SaveChangesAsync(cancellationToken);
            return (false, null, "Verification challenge has expired. Please request a new verification code.", 400);
        }

        if (challenge.ResendCount >= _options.MaxResends)
        {
            _logger.LogWarning("[EmailVerification] Max resends reached for challenge {ChallengeId} ({MaskedEmail}).", challenge.Id, maskedEmail);
            return (false, null, "Maximum resend attempts reached for this session. Please initiate a new verification request.", 429);
        }

        // Cooldown verification
        var lastActivityTime = challenge.LastResentAtUtc ?? challenge.CreatedAtUtc;
        var elapsedSeconds = (now - lastActivityTime).TotalSeconds;
        if (elapsedSeconds < _options.ResendCooldownSeconds)
        {
            var remaining = (int)Math.Ceiling(_options.ResendCooldownSeconds - elapsedSeconds);
            return (false, null, $"Please wait {remaining} seconds before resending.", 429);
        }

        // Generate fresh OTP code, salt, and hash
        var newOtpCode = _crypto.GenerateOtpCode();
        var newSalt = _crypto.GenerateSalt();
        var newHash = _crypto.HashEmailOtp(newOtpCode, newSalt, challenge.Email);

        challenge.OtpCode = _environment.IsDevelopment() ? newOtpCode : string.Empty;
        challenge.OtpHashingSalt = newSalt;
        challenge.OtpHash = newHash;
        challenge.ExpiresAtUtc = now.AddSeconds(_options.OtpLifetimeSeconds);
        challenge.AttemptCount = 0; // Reset attempts for the new code
        challenge.ResendCount += 1;
        challenge.LastResentAtUtc = now;

        await _dbContext.SaveChangesAsync(cancellationToken);

        // Dispatch through provider
        var dispatchResult = await _emailProvider.SendOtpEmailAsync(
            challenge.Email,
            newOtpCode,
            challenge.RegistrationFlowId,
            cancellationToken);

        if (!dispatchResult.Accepted)
        {
            _logger.LogError("[EmailVerification] Resend dispatch failed for challenge {ChallengeId}: {Error}",
                challenge.Id, dispatchResult.ErrorMessage);
            return (false, null, dispatchResult.ErrorMessage ?? "Failed to dispatch resend OTP via email.", 502);
        }

        challenge.ProviderMessageId = dispatchResult.ProviderMessageId;
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[EmailVerification] Resend OTP successfully dispatched for challenge {ChallengeId} to {MaskedEmail}.",
            challenge.Id, maskedEmail);

        var isLive = !dispatchResult.IsSimulated;
        var message = isLive
            ? "Verification code resent via email."
            : "Development mode: Gmail SMTP is unconfigured. Resend OTP code updated in SQL Server.";

        var responseDto = new ResendEmailOtpResponseDto(
            ChallengeId: challenge.Id,
            MaskedEmail: maskedEmail,
            ExpiresAtUtc: challenge.ExpiresAtUtc,
            CooldownSeconds: _options.ResendCooldownSeconds,
            Accepted: true,
            Status: "Pending",
            Message: message,
            IsLiveDelivery: isLive
        );

        return (true, responseDto, null, 200);
    }

    public async Task<(bool Success, VerifyEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null || request.ChallengeId <= 0)
        {
            return (false, null, "Valid ChallengeId is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.OtpCode))
        {
            return (false, null, "Verification code is required.", 400);
        }

        var challenge = await _dbContext.OtpChallenges
            .FirstOrDefaultAsync(c => c.Id == request.ChallengeId &&
                                      c.Purpose == EmailPurpose &&
                                      c.RegistrationFlowId == request.RegistrationFlowId.Trim(), cancellationToken);

        if (challenge == null || string.IsNullOrWhiteSpace(challenge.Email))
        {
            return (false, null, "Verification challenge not found or session mismatch.", 404);
        }

        var maskedEmail = _crypto.MaskEmail(challenge.Email);
        var now = DateTime.UtcNow;

        if (challenge.Status == OtpChallengeStatus.Verified)
        {
            return (false, null, "This challenge has already been verified.", 400);
        }

        if (challenge.Status != OtpChallengeStatus.Pending)
        {
            return (false, null, $"Verification challenge is invalid ({challenge.Status}). Please request a new code.", 400);
        }

        if (now > challenge.ExpiresAtUtc)
        {
            challenge.Status = OtpChallengeStatus.Expired;
            await _dbContext.SaveChangesAsync(cancellationToken);
            _logger.LogInformation("[EmailVerification] Expired attempt on challenge {ChallengeId}.", challenge.Id);
            return (false, null, "Verification code has expired. Please request a new code.", 400);
        }

        if (challenge.AttemptCount >= challenge.MaxAttempts)
        {
            challenge.Status = OtpChallengeStatus.MaxAttemptsExceeded;
            await _dbContext.SaveChangesAsync(cancellationToken);
            _logger.LogWarning("[EmailVerification] Max attempts exceeded for challenge {ChallengeId}.", challenge.Id);
            return (false, null, "Maximum verification attempts exceeded. Please request a new code.", 400);
        }

        // Increment attempt count atomically
        challenge.AttemptCount += 1;

        // Perform code match: in Development allows direct code check if set; otherwise strictly constant-time HMAC check
        var trimmedInput = request.OtpCode.Trim();
        var isDevDirectMatch = _environment.IsDevelopment() &&
                               !string.IsNullOrEmpty(challenge.OtpCode) &&
                               challenge.OtpCode == trimmedInput;

        var isValid = isDevDirectMatch ||
                      _crypto.VerifyEmailOtp(trimmedInput, challenge.OtpHashingSalt, challenge.Email, challenge.OtpHash);

        if (!isValid)
        {
            var attemptsRemaining = Math.Max(0, challenge.MaxAttempts - challenge.AttemptCount);
            if (attemptsRemaining == 0)
            {
                challenge.Status = OtpChallengeStatus.MaxAttemptsExceeded;
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogWarning("[EmailVerification] Invalid OTP code attempt on challenge {ChallengeId}. Remaining: {Remaining}",
                challenge.Id, attemptsRemaining);

            var errorMsg = attemptsRemaining > 0
                ? $"Incorrect verification code. Attempts remaining: {attemptsRemaining}."
                : "Maximum verification attempts exceeded. Please request a new code.";

            return (false, null, errorMsg, 400);
        }

        // Verification successful — transition state atomically
        challenge.Status = OtpChallengeStatus.Verified;
        challenge.VerifiedAtUtc = now;
        challenge.VerificationGrantToken = _crypto.GenerateVerificationGrant();
        challenge.VerificationGrantExpiresAtUtc = now.AddMinutes(_options.VerificationGrantLifetimeMinutes);

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[EmailVerification] Challenge {ChallengeId} verified successfully for {MaskedEmail}. Grant issued.",
            challenge.Id, maskedEmail);

        var responseDto = new VerifyEmailOtpResponseDto(
            Verified: true,
            MaskedEmail: maskedEmail,
            VerificationGrant: challenge.VerificationGrantToken,
            VerificationGrantExpiresAtUtc: challenge.VerificationGrantExpiresAtUtc.Value,
            Message: "Email address successfully verified."
        );

        return (true, responseDto, null, 200);
    }
}
