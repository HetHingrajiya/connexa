using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.WhatsApp;

namespace Connexa.Api.Services.Verification;

public class PhoneVerificationService : IPhoneVerificationService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IWhatsAppProvider _whatsAppProvider;
    private readonly IOtpCryptographyService _crypto;
    private readonly OtpSecurityOptions _options;
    private readonly IWebHostEnvironment? _environment;
    private readonly ILogger<PhoneVerificationService> _logger;

    public PhoneVerificationService(
        ConnexaDbContext dbContext,
        IWhatsAppProvider whatsAppProvider,
        IOtpCryptographyService crypto,
        IOptions<OtpSecurityOptions> options,
        ILogger<PhoneVerificationService> logger,
        IWebHostEnvironment? environment = null)
    {
        _dbContext = dbContext;
        _whatsAppProvider = whatsAppProvider;
        _crypto = crypto;
        _options = options.Value;
        _logger = logger;
        _environment = environment;
    }

    public async Task<(bool Success, SendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendOtpRequestDto request,
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

        string normalizedPhone;
        try
        {
            normalizedPhone = _crypto.NormalizePhoneNumber(request.PhoneNumber);
        }
        catch (ArgumentException ex)
        {
            return (false, null, ex.Message, 400);
        }

        var maskedPhone = _crypto.MaskPhoneNumber(normalizedPhone);
        var now = DateTime.UtcNow;

        // 1. IP rate limiting (requests per 10 minutes)
        if (!string.IsNullOrWhiteSpace(clientIp))
        {
            var tenMinutesAgo = now.AddMinutes(-10);
            var ipRequestCount = await _dbContext.OtpChallenges
                .CountAsync(c => c.RequestIpAddress == clientIp && c.CreatedAtUtc >= tenMinutesAgo, cancellationToken);

            if (ipRequestCount >= _options.MaxRequestsPerTenMinutesPerIp)
            {
                _logger.LogWarning("[Verification] Rate limit exceeded for IP {IpAddress}.", clientIp);
                return (false, null, "Too many verification requests from this network. Please try again later.", 429);
            }
        }

        // 2. Phone rate limiting (challenges created in the last hour)
        var oneHourAgo = now.AddHours(-1);
        var phoneChallengeCount = await _dbContext.OtpChallenges
            .CountAsync(c => c.PhoneNumber == normalizedPhone && c.CreatedAtUtc >= oneHourAgo, cancellationToken);

        if (phoneChallengeCount >= _options.MaxChallengesPerHourPerPhone)
        {
            _logger.LogWarning("[Verification] Hourly limit exceeded for destination {MaskedPhone}.", maskedPhone);
            return (false, null, "Hourly verification request limit exceeded for this phone number. Please try again later.", 429);
        }

        // 3. Resend cooldown check against any active pending challenge for this phone
        var activePendingChallenge = await _dbContext.OtpChallenges
            .Where(c => c.PhoneNumber == normalizedPhone && c.Status == OtpChallengeStatus.Pending && c.ExpiresAtUtc > now)
            .OrderByDescending(c => c.CreatedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

        if (activePendingChallenge != null)
        {
            var lastActivityTime = activePendingChallenge.LastResentAtUtc ?? activePendingChallenge.CreatedAtUtc;
            var elapsedSeconds = (now - lastActivityTime).TotalSeconds;
            if (elapsedSeconds < _options.ResendCooldownSeconds)
            {
                var remaining = (int)Math.Ceiling(_options.ResendCooldownSeconds - elapsedSeconds);
                _logger.LogInformation("[Verification] Cooldown active for {MaskedPhone}. Remaining: {Remaining}s", maskedPhone, remaining);
                return (false, null, $"Please wait {remaining} seconds before requesting a new verification code.", 429);
            }
        }

        // 4. Supersede prior active pending challenges for this phone & flow
        var existingPendingChallenges = await _dbContext.OtpChallenges
            .Where(c => c.PhoneNumber == normalizedPhone && c.Status == OtpChallengeStatus.Pending)
            .ToListAsync(cancellationToken);

        foreach (var challenge in existingPendingChallenges)
        {
            challenge.Status = OtpChallengeStatus.Superseded;
        }

        // 5. Generate secure random 6-digit OTP, salt, and keyed HMAC
        var otpCode = _crypto.GenerateOtpCode();
        var salt = _crypto.GenerateSalt();
        var otpHash = _crypto.HashOtp(otpCode, salt, normalizedPhone);

        var newChallenge = new OtpChallenge
        {
            PhoneNumber = normalizedPhone,
            OtpCode = (_environment?.IsDevelopment() ?? true) ? otpCode : string.Empty,
            OtpHashingSalt = salt,
            OtpHash = otpHash,
            RegistrationFlowId = request.RegistrationFlowId.Trim(),
            CreatedAtUtc = now,
            ExpiresAtUtc = now.AddSeconds(_options.OtpLifetimeSeconds),
            MaxAttempts = _options.MaxAttempts,
            Status = OtpChallengeStatus.Pending,
            RequestIpAddress = clientIp
        };

        _dbContext.OtpChallenges.Add(newChallenge);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // 6. Dispatch via configured WhatsApp provider
        var dispatchResult = await _whatsAppProvider.SendOtpAsync(
            normalizedPhone,
            otpCode,
            request.RegistrationFlowId,
            cancellationToken);

        if (!dispatchResult.Accepted)
        {
            _logger.LogError("[Verification] Provider dispatch failed for {MaskedPhone}: {Error}",
                maskedPhone, dispatchResult.ErrorMessage);

            // Mark challenge expired/failed so it cannot be verified
            newChallenge.Status = OtpChallengeStatus.Expired;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return (false, null, dispatchResult.ErrorMessage ?? "Unable to deliver verification code via WhatsApp. Please verify your number and retry.", 502);
        }

        // Update provider message ID
        newChallenge.ProviderMessageId = dispatchResult.ProviderMessageId;
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Verification] OTP challenge {ChallengeId} dispatched successfully to {MaskedPhone} (Provider: {Provider}).",
            newChallenge.Id, maskedPhone, _whatsAppProvider.ProviderName);

        var isLive = !dispatchResult.IsSimulated;
        var message = isLive
            ? "Verification code dispatched via WhatsApp."
            : "Development mode: WhatsApp Gateway is unconfigured. No live WhatsApp message was sent. OTP is stored in SQL Server.";

        var responseDto = new SendOtpResponseDto(
            ChallengeId: newChallenge.Id,
            MaskedPhoneNumber: maskedPhone,
            ExpiresAtUtc: newChallenge.ExpiresAtUtc,
            CooldownSeconds: _options.ResendCooldownSeconds,
            Accepted: true,
            Status: "Pending",
            Message: message,
            IsLiveDelivery: isLive
        );

        return (true, responseDto, null, 200);
    }

    public async Task<(bool Success, ResendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null || request.ChallengeId <= 0)
        {
            return (false, null, "Valid ChallengeId is required.", 400);
        }

        var challenge = await _dbContext.OtpChallenges
            .FirstOrDefaultAsync(c => c.Id == request.ChallengeId &&
                                      c.PhoneNumber != null &&
                                      c.Purpose != "RegistrationVerification_Email" &&
                                      c.RegistrationFlowId == request.RegistrationFlowId.Trim(), cancellationToken);

        if (challenge == null || string.IsNullOrWhiteSpace(challenge.PhoneNumber))
        {
            return (false, null, "Verification challenge not found or session mismatch.", 404);
        }

        var maskedPhone = _crypto.MaskPhoneNumber(challenge.PhoneNumber);
        var now = DateTime.UtcNow;

        if (challenge.Status == OtpChallengeStatus.Verified)
        {
            return (false, null, "Phone number has already been verified.", 400);
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
            _logger.LogWarning("[Verification] Max resends reached for challenge {ChallengeId} ({MaskedPhone}).", challenge.Id, maskedPhone);
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
        var newHash = _crypto.HashOtp(newOtpCode, newSalt, challenge.PhoneNumber);

        challenge.OtpCode = (_environment?.IsDevelopment() ?? true) ? newOtpCode : string.Empty;
        challenge.OtpHashingSalt = newSalt;
        challenge.OtpHash = newHash;
        challenge.ExpiresAtUtc = now.AddSeconds(_options.OtpLifetimeSeconds);
        challenge.AttemptCount = 0; // Reset attempts for the new code
        challenge.ResendCount += 1;
        challenge.LastResentAtUtc = now;

        await _dbContext.SaveChangesAsync(cancellationToken);

        // Dispatch through provider
        var dispatchResult = await _whatsAppProvider.SendOtpAsync(
            challenge.PhoneNumber,
            newOtpCode,
            challenge.RegistrationFlowId,
            cancellationToken);

        if (!dispatchResult.Accepted)
        {
            _logger.LogError("[Verification] Resend dispatch failed for challenge {ChallengeId}: {Error}",
                challenge.Id, dispatchResult.ErrorMessage);
            return (false, null, dispatchResult.ErrorMessage ?? "Failed to dispatch resend OTP via WhatsApp.", 502);
        }

        challenge.ProviderMessageId = dispatchResult.ProviderMessageId;
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Verification] Resend OTP successfully dispatched for challenge {ChallengeId} to {MaskedPhone}.",
            challenge.Id, maskedPhone);

        var isLive = !dispatchResult.IsSimulated;
        var message = isLive
            ? "Verification code resent via WhatsApp."
            : "Development mode: WhatsApp Gateway is unconfigured. No live WhatsApp message was sent. OTP is stored in SQL Server.";

        var responseDto = new ResendOtpResponseDto(
            ChallengeId: challenge.Id,
            MaskedPhoneNumber: maskedPhone,
            ExpiresAtUtc: challenge.ExpiresAtUtc,
            CooldownSeconds: _options.ResendCooldownSeconds,
            Accepted: true,
            Status: "Pending",
            Message: message,
            IsLiveDelivery: isLive
        );

        return (true, responseDto, null, 200);
    }

    public async Task<(bool Success, VerifyOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyOtpRequestDto request,
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
                                      c.PhoneNumber != null &&
                                      c.Purpose != "RegistrationVerification_Email" &&
                                      c.RegistrationFlowId == request.RegistrationFlowId.Trim(), cancellationToken);

        if (challenge == null || string.IsNullOrWhiteSpace(challenge.PhoneNumber))
        {
            return (false, null, "Verification challenge not found or session mismatch.", 404);
        }

        var maskedPhone = _crypto.MaskPhoneNumber(challenge.PhoneNumber);
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
            _logger.LogInformation("[Verification] Expired attempt on challenge {ChallengeId}.", challenge.Id);
            return (false, null, "Verification code has expired. Please request a new code.", 400);
        }

        if (challenge.AttemptCount >= challenge.MaxAttempts)
        {
            challenge.Status = OtpChallengeStatus.MaxAttemptsExceeded;
            await _dbContext.SaveChangesAsync(cancellationToken);
            _logger.LogWarning("[Verification] Max attempts exceeded for challenge {ChallengeId}.", challenge.Id);
            return (false, null, "Maximum verification attempts exceeded. Please request a new code.", 400);
        }

        // Increment attempt count atomically
        challenge.AttemptCount += 1;

        // Perform direct code match (in Dev if set) or constant-time cryptographic hash verification
        var trimmedInput = request.OtpCode.Trim();
        var isDevDirectMatch = (_environment?.IsDevelopment() ?? true) &&
                               !string.IsNullOrEmpty(challenge.OtpCode) &&
                               challenge.OtpCode == trimmedInput;

        var isValid = isDevDirectMatch ||
                      _crypto.VerifyOtp(trimmedInput, challenge.OtpHashingSalt, challenge.PhoneNumber, challenge.OtpHash);

        if (!isValid)
        {
            var attemptsRemaining = Math.Max(0, challenge.MaxAttempts - challenge.AttemptCount);
            if (attemptsRemaining == 0)
            {
                challenge.Status = OtpChallengeStatus.MaxAttemptsExceeded;
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogWarning("[Verification] Invalid OTP code attempt on challenge {ChallengeId}. Remaining: {Remaining}",
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

        _logger.LogInformation("[Verification] Challenge {ChallengeId} verified successfully for {MaskedPhone}. Grant issued.",
            challenge.Id, maskedPhone);

        var responseDto = new VerifyOtpResponseDto(
            Verified: true,
            MaskedPhoneNumber: maskedPhone,
            VerificationGrant: challenge.VerificationGrantToken,
            VerificationGrantExpiresAtUtc: challenge.VerificationGrantExpiresAtUtc.Value,
            Message: "Phone number successfully verified."
        );

        return (true, responseDto, null, 200);
    }
}
