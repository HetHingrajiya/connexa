using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Verification;
using Microsoft.Extensions.Options;

namespace Connexa.Api.Services.Auth;

public class AuthService : IAuthService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IEmailVerificationService _emailVerificationService;
    private readonly IPhoneVerificationService _phoneVerificationService;
    private readonly JwtOptions _jwtOptions;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        ConnexaDbContext dbContext,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IEmailVerificationService emailVerificationService,
        IPhoneVerificationService phoneVerificationService,
        IOptions<JwtOptions> jwtOptions,
        ILogger<AuthService> logger)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _emailVerificationService = emailVerificationService;
        _phoneVerificationService = phoneVerificationService;
        _jwtOptions = jwtOptions.Value;
        _logger = logger;
    }

    public async Task<AuthResult<AuthResponseDto>> SetupPasswordAsync(
        SetupPasswordRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        // 1. Validate password policy
        var (isValid, errorMessage) = _passwordHasher.ValidatePasswordPolicy(request.Password);
        if (!isValid)
        {
            return new AuthResult<AuthResponseDto>(false, null, errorMessage, 400);
        }

        if (!string.Equals(request.Password, request.ConfirmPassword, StringComparison.Ordinal))
        {
            return new AuthResult<AuthResponseDto>(false, null, "Password confirmation does not match.", 400);
        }

        // 2. Validate Authorization
        Member? member = null;

        if (!string.IsNullOrWhiteSpace(request.CredentialSetupToken))
        {
            // Flow A: Authorization via CredentialSetupToken (from completed registration)
            var token = request.CredentialSetupToken.Trim();
            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.CredentialSetupToken == token, cancellationToken);

            if (member == null ||
                member.CredentialSetupTokenExpiresAtUtc == null ||
                member.CredentialSetupTokenExpiresAtUtc <= DateTime.UtcNow)
            {
                return new AuthResult<AuthResponseDto>(false, null, "Invalid or expired credential setup authorization. Please verify your contact details to continue.", 400);
            }
        }
        else if (!string.IsNullOrWhiteSpace(request.VerificationGrant) && !string.IsNullOrWhiteSpace(request.Destination))
        {
            // Flow B: Authorization via verified OTP challenge grant
            var grant = request.VerificationGrant.Trim();
            var destination = request.Destination.Trim().ToLowerInvariant();

            var challenge = await _dbContext.OtpChallenges
                .FirstOrDefaultAsync(c => c.VerificationGrantToken == grant, cancellationToken);

            if (challenge == null ||
                challenge.Status != OtpChallengeStatus.Verified ||
                challenge.VerificationGrantExpiresAtUtc == null ||
                challenge.VerificationGrantExpiresAtUtc <= DateTime.UtcNow)
            {
                return new AuthResult<AuthResponseDto>(false, null, "Invalid or expired verification grant.", 400);
            }

            // Match member by verified email or phone
            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.Email == destination || m.PhoneNumber == destination, cancellationToken);

            if (member == null)
            {
                // Try normalizing phone if destination is digits
                var normalizedPhone = destination.StartsWith("+") ? destination : "+91" + destination;
                member = await _dbContext.Members
                    .FirstOrDefaultAsync(m => m.PhoneNumber == normalizedPhone, cancellationToken);
            }

            if (member == null)
            {
                return new AuthResult<AuthResponseDto>(false, null, "No member account found matching verified destination.", 404);
            }

            // Consume OTP grant
            challenge.Status = OtpChallengeStatus.Superseded;
            challenge.VerificationGrantExpiresAtUtc = null;
        }
        else
        {
            return new AuthResult<AuthResponseDto>(false, null, "Server-validated credential setup authorization is required.", 400);
        }

        // 3. Hash and store password
        var (hash, salt) = _passwordHasher.HashPassword(request.Password);

        member.PasswordHash = hash;
        member.PasswordSalt = salt;
        member.CredentialSetupToken = null;
        member.CredentialSetupTokenExpiresAtUtc = null;
        member.FailedLoginAttempts = 0;
        member.LockoutEndUtc = null;
        member.UpdatedAtUtc = DateTime.UtcNow;

        // 4. Issue initial tokens
        var accessToken = _tokenService.GenerateAccessToken(member);
        var (plainRefreshToken, refreshTokenEntity) = _tokenService.GenerateRefreshToken(member.Id, clientIp);

        _dbContext.RefreshTokens.Add(refreshTokenEntity);

        var strategy = _dbContext.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        });

        _logger.LogInformation("[Auth] Password setup completed successfully for Member ID {MemberId}.", member.Id);

        var response = new AuthResponseDto(
            AccessToken: accessToken,
            RefreshToken: plainRefreshToken,
            TokenType: "Bearer",
            ExpiresIn: _jwtOptions.AccessTokenExpirationMinutes * 60,
            Member: new AuthenticatedMemberDto(
                MemberId: member.Id,
                FullName: member.FullName,
                Email: member.Email,
                PhoneNumber: member.PhoneNumber,
                Role: "Member",
                PrimaryProfileType: member.PrimaryProfileType.ToString()
            )
        );

        return new AuthResult<AuthResponseDto>(true, response, null, 200);
    }

    public async Task<AuthResult<AuthResponseDto>> LoginAsync(
        LoginRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Identifier) || string.IsNullOrWhiteSpace(request.Password))
        {
            return new AuthResult<AuthResponseDto>(false, null, "Email/phone and password are required.", 400);
        }

        var identifier = request.Identifier.Trim();

        // 1. Locate member by Email or Normalized Phone Number
        Member? member = null;
        if (identifier.Contains('@'))
        {
            var normalizedEmail = identifier.ToLowerInvariant();
            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.Email == normalizedEmail, cancellationToken);
        }
        else
        {
            var rawDigits = new string(identifier.Where(char.IsDigit).ToArray());
            var normalizedPhone = identifier.StartsWith("+")
                ? identifier
                : (rawDigits.Length == 10 ? "+91" + rawDigits : "+" + rawDigits);

            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.PhoneNumber == normalizedPhone || m.PhoneNumber == identifier, cancellationToken);
        }

        if (member == null)
        {
            // Do not leak whether user exists
            return new AuthResult<AuthResponseDto>(false, null, "Invalid email/phone number or password.", 401);
        }

        if (!member.IsActive)
        {
            return new AuthResult<AuthResponseDto>(false, null, "This account is inactive. Please contact support.", 401);
        }

        // 2. Check Lockout Status
        if (member.LockoutEndUtc != null && member.LockoutEndUtc > DateTime.UtcNow)
        {
            var remainingMinutes = (int)Math.Ceiling((member.LockoutEndUtc.Value - DateTime.UtcNow).TotalMinutes);
            _logger.LogWarning("[Security] Login attempt on locked account Member ID {MemberId} from IP {ClientIp}.", member.Id, clientIp);
            return new AuthResult<AuthResponseDto>(false, null, $"Account is temporarily locked due to multiple failed login attempts. Please retry in {remainingMinutes} minute(s).", 429);
        }

        // 3. Check if password has been configured
        if (string.IsNullOrEmpty(member.PasswordHash) || string.IsNullOrEmpty(member.PasswordSalt))
        {
            return new AuthResult<AuthResponseDto>(false, null, "Password has not been set for this account. Please complete credential setup first.", 400);
        }

        // 4. Verify password
        bool passwordMatches = _passwordHasher.VerifyPassword(request.Password, member.PasswordHash, member.PasswordSalt);

        if (!passwordMatches)
        {
            member.FailedLoginAttempts++;
            if (member.FailedLoginAttempts >= 5)
            {
                member.LockoutEndUtc = DateTime.UtcNow.AddMinutes(15);
                _logger.LogWarning("[Security] Account locked for Member ID {MemberId} after 5 failed login attempts from IP {ClientIp}.", member.Id, clientIp);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            return new AuthResult<AuthResponseDto>(false, null, "Invalid email/phone number or password.", 401);
        }

        // 5. Successful login: reset failed attempts
        member.FailedLoginAttempts = 0;
        member.LockoutEndUtc = null;

        var accessToken = _tokenService.GenerateAccessToken(member);
        var (plainRefreshToken, refreshTokenEntity) = _tokenService.GenerateRefreshToken(member.Id, clientIp);

        _dbContext.RefreshTokens.Add(refreshTokenEntity);
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Auth] Successful login for Member ID {MemberId}.", member.Id);

        var response = new AuthResponseDto(
            AccessToken: accessToken,
            RefreshToken: plainRefreshToken,
            TokenType: "Bearer",
            ExpiresIn: _jwtOptions.AccessTokenExpirationMinutes * 60,
            Member: new AuthenticatedMemberDto(
                MemberId: member.Id,
                FullName: member.FullName,
                Email: member.Email,
                PhoneNumber: member.PhoneNumber,
                Role: "Member",
                PrimaryProfileType: member.PrimaryProfileType.ToString()
            )
        );

        return new AuthResult<AuthResponseDto>(true, response, null, 200);
    }

    public async Task<AuthResult<AuthResponseDto>> RefreshTokenAsync(
        RefreshTokenRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return new AuthResult<AuthResponseDto>(false, null, "Refresh token is required.", 400);
        }

        string tokenHash = _tokenService.HashRefreshToken(request.RefreshToken);

        var storedToken = await _dbContext.RefreshTokens
            .Include(rt => rt.Member)
            .FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash, cancellationToken);

        if (storedToken == null)
        {
            return new AuthResult<AuthResponseDto>(false, null, "Invalid refresh token.", 401);
        }

        // 1. Replay Detection: Check if token has already been revoked
        if (storedToken.IsRevoked)
        {
            // Compromise detected: immediately revoke all active tokens for this member
            var activeTokens = await _dbContext.RefreshTokens
                .Where(rt => rt.MemberId == storedToken.MemberId && rt.RevokedAtUtc == null)
                .ToListAsync(cancellationToken);

            foreach (var token in activeTokens)
            {
                token.RevokedAtUtc = DateTime.UtcNow;
                token.RevokedByIp = clientIp;
                token.ReasonRevoked = "Cascade revocation due to replay attack detection";
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogWarning("[Security] Refresh token replay attack detected for Member ID {MemberId}. All active sessions revoked.", storedToken.MemberId);
            return new AuthResult<AuthResponseDto>(false, null, "Token has been revoked.", 401);
        }

        // 2. Check token expiration
        if (storedToken.IsExpired)
        {
            return new AuthResult<AuthResponseDto>(false, null, "Refresh token has expired. Please sign in again.", 401);
        }

        if (!storedToken.Member.IsActive)
        {
            return new AuthResult<AuthResponseDto>(false, null, "Account is inactive.", 401);
        }

        // 3. Rotate refresh token
        var (newPlainRefreshToken, newRefreshTokenEntity) = _tokenService.GenerateRefreshToken(storedToken.MemberId, clientIp);

        storedToken.RevokedAtUtc = DateTime.UtcNow;
        storedToken.RevokedByIp = clientIp;
        storedToken.ReplacedByTokenHash = newRefreshTokenEntity.TokenHash;
        storedToken.ReasonRevoked = "Rotated";

        _dbContext.RefreshTokens.Add(newRefreshTokenEntity);

        var newAccessToken = _tokenService.GenerateAccessToken(storedToken.Member);
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Auth] Refresh token rotated successfully for Member ID {MemberId}.", storedToken.MemberId);

        var response = new AuthResponseDto(
            AccessToken: newAccessToken,
            RefreshToken: newPlainRefreshToken,
            TokenType: "Bearer",
            ExpiresIn: _jwtOptions.AccessTokenExpirationMinutes * 60,
            Member: new AuthenticatedMemberDto(
                MemberId: storedToken.Member.Id,
                FullName: storedToken.Member.FullName,
                Email: storedToken.Member.Email,
                PhoneNumber: storedToken.Member.PhoneNumber,
                Role: "Member",
                PrimaryProfileType: storedToken.Member.PrimaryProfileType.ToString()
            )
        );

        return new AuthResult<AuthResponseDto>(true, response, null, 200);
    }

    public async Task<AuthResult<bool>> LogoutAsync(
        LogoutRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            try
            {
                string tokenHash = _tokenService.HashRefreshToken(request.RefreshToken);
                var storedToken = await _dbContext.RefreshTokens
                    .FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash, cancellationToken);

                if (storedToken != null && storedToken.RevokedAtUtc == null)
                {
                    storedToken.RevokedAtUtc = DateTime.UtcNow;
                    storedToken.RevokedByIp = clientIp;
                    storedToken.ReasonRevoked = "User logged out";
                    await _dbContext.SaveChangesAsync(cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Auth] Error revoking refresh token on logout.");
            }
        }

        return new AuthResult<bool>(true, true, null, 200);
    }

    public async Task<AuthResult<MemberProfileResponseDto>> GetMemberProfileAsync(
        int memberId,
        CancellationToken cancellationToken = default)
    {
        var member = await _dbContext.Members
            .AsNoTracking()
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.Industry)
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.BusinessGroup)
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.SubGroup)
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.Category)
            .Include(m => m.EmployeeProfile)
            .Include(m => m.ServiceEngineerProfile)
            .Include(m => m.TraderProfile)
            .Include(m => m.ContractorProfile)
                .ThenInclude(c => c!.Industry)
            .Include(m => m.ContractorProfile)
                .ThenInclude(c => c!.BusinessGroup)
            .Include(m => m.ContractorProfile)
                .ThenInclude(c => c!.SubGroup)
            .Include(m => m.ContractorProfile)
                .ThenInclude(c => c!.Category)
            .FirstOrDefaultAsync(m => m.Id == memberId, cancellationToken);

        if (member == null)
        {
            return new AuthResult<MemberProfileResponseDto>(false, null, "Member profile not found.", 404);
        }

        if (!member.IsActive)
        {
            return new AuthResult<MemberProfileResponseDto>(false, null, "Member account is inactive.", 401);
        }

        object? profileData = member.PrimaryProfileType switch
        {
            ProfileTypeEnum.BusinessCompany when member.BusinessProfile != null => new
            {
                member.BusinessProfile.CompanyName,
                BusinessCapabilities = member.BusinessProfile.BusinessCapabilities?.Split(new[] { ", " }, StringSplitOptions.RemoveEmptyEntries),
                member.BusinessProfile.BusinessDescription,
                member.BusinessProfile.IndustryId,
                Industry = member.BusinessProfile.Industry?.Name,
                member.BusinessProfile.BusinessGroupId,
                BusinessGroup = member.BusinessProfile.BusinessGroup?.Name,
                member.BusinessProfile.SubGroupId,
                SubGroup = member.BusinessProfile.SubGroup?.Name,
                member.BusinessProfile.CategoryId,
                Category = member.BusinessProfile.Category?.Name
            },
            ProfileTypeEnum.EmployeeJobSeeker when member.EmployeeProfile != null => new
            {
                member.EmployeeProfile.JobTitle,
                member.EmployeeProfile.Skills,
                member.EmployeeProfile.Experience,
                member.EmployeeProfile.PreferredJobType
            },
            ProfileTypeEnum.ServiceEngineer when member.ServiceEngineerProfile != null => new
            {
                member.ServiceEngineerProfile.Specialization,
                member.ServiceEngineerProfile.SupportedEquipment,
                member.ServiceEngineerProfile.YearsOfExperience,
                member.ServiceEngineerProfile.ServiceCoverage
            },
            ProfileTypeEnum.TraderSupplier when member.TraderProfile != null => new
            {
                member.TraderProfile.TradingName,
                Capabilities = member.TraderProfile.Capabilities?.Split(new[] { ", " }, StringSplitOptions.RemoveEmptyEntries),
                member.TraderProfile.ProductsSupplied,
                member.TraderProfile.ServiceCoverage
            },
            ProfileTypeEnum.ContractorJobWorker when member.ContractorProfile != null => new
            {
                member.ContractorProfile.WorkName,
                WorkCapabilities = member.ContractorProfile.WorkCapabilities?.Split(new[] { ", " }, StringSplitOptions.RemoveEmptyEntries),
                member.ContractorProfile.ProcessesSupported,
                member.ContractorProfile.WorkCoverage,
                member.ContractorProfile.IndustryId,
                Industry = member.ContractorProfile.Industry?.Name,
                member.ContractorProfile.BusinessGroupId,
                BusinessGroup = member.ContractorProfile.BusinessGroup?.Name,
                member.ContractorProfile.SubGroupId,
                SubGroup = member.ContractorProfile.SubGroup?.Name,
                member.ContractorProfile.CategoryId,
                Category = member.ContractorProfile.Category?.Name
            },
            _ => null
        };

        var response = new MemberProfileResponseDto(
            MemberId: member.Id,
            FullName: member.FullName,
            CountryCode: member.CountryCode,
            PhoneNumber: member.PhoneNumber,
            Email: member.Email,
            PrimaryProfileType: member.PrimaryProfileType.ToString(),
            VerifiedMethod: member.VerifiedMethod,
            VerifiedDestination: member.VerifiedDestination,
            Role: "Member",
            IsActive: member.IsActive,
            CreatedAtUtc: member.CreatedAtUtc,
            ProfileDetails: profileData
        );

        return new AuthResult<MemberProfileResponseDto>(true, response, null, 200);
    }

    public async Task<AuthResult<RequestSetupOtpResponseDto>> RequestSetupOtpAsync(
        RequestSetupOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Identifier))
        {
            return new AuthResult<RequestSetupOtpResponseDto>(false, null, "Email address or phone number is required.", 400);
        }

        var identifier = request.Identifier.Trim();
        var isEmail = identifier.Contains('@') || string.Equals(request.Channel, "Email", StringComparison.OrdinalIgnoreCase);
        var channel = isEmail ? "Email" : "WhatsApp";

        Member? member = null;
        if (isEmail)
        {
            var normalizedEmail = identifier.ToLowerInvariant();
            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.Email == normalizedEmail, cancellationToken);
        }
        else
        {
            var digitsOnly = new string(identifier.Where(char.IsDigit).ToArray());
            var normalizedPhone = identifier.StartsWith("+") ? identifier : "+91" + digitsOnly;
            member = await _dbContext.Members
                .FirstOrDefaultAsync(m => m.PhoneNumber == normalizedPhone || m.PhoneNumber == identifier, cancellationToken);
        }

        if (member == null || !member.IsActive)
        {
            return new AuthResult<RequestSetupOtpResponseDto>(
                false,
                null,
                "No registered member account was found with the provided details. Please verify your information or complete registration first.",
                404);
        }

        var flowId = $"setup_{Guid.NewGuid():N}";

        if (isEmail)
        {
            var sendResult = await _emailVerificationService.SendOtpAsync(
                new SendEmailOtpRequestDto(member.Email, flowId),
                clientIp,
                cancellationToken);

            if (!sendResult.Success || sendResult.Response == null)
            {
                return new AuthResult<RequestSetupOtpResponseDto>(false, null, sendResult.ErrorMessage ?? "Failed to send email verification code.", sendResult.StatusCode);
            }

            var responseDto = new RequestSetupOtpResponseDto(
                Success: true,
                ChallengeId: sendResult.Response.ChallengeId,
                Destination: member.Email,
                MaskedDestination: sendResult.Response.MaskedEmail,
                Channel: "Email",
                FlowId: flowId,
                Message: "A verification code has been dispatched to your registered email address."
            );

            return new AuthResult<RequestSetupOtpResponseDto>(true, responseDto, null, 200);
        }
        else
        {
            var sendResult = await _phoneVerificationService.SendOtpAsync(
                new SendOtpRequestDto(member.PhoneNumber, flowId),
                clientIp,
                cancellationToken);

            if (!sendResult.Success || sendResult.Response == null)
            {
                return new AuthResult<RequestSetupOtpResponseDto>(false, null, sendResult.ErrorMessage ?? "Failed to send WhatsApp verification code.", sendResult.StatusCode);
            }

            var responseDto = new RequestSetupOtpResponseDto(
                Success: true,
                ChallengeId: sendResult.Response.ChallengeId,
                Destination: member.PhoneNumber,
                MaskedDestination: sendResult.Response.MaskedPhoneNumber,
                Channel: "WhatsApp",
                FlowId: flowId,
                Message: "A verification code has been dispatched to your registered phone number via WhatsApp."
            );

            return new AuthResult<RequestSetupOtpResponseDto>(true, responseDto, null, 200);
        }
    }

    public async Task<AuthResult<VerifySetupOtpResponseDto>> VerifySetupOtpAsync(
        VerifySetupOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.OtpCode) || request.ChallengeId <= 0)
        {
            return new AuthResult<VerifySetupOtpResponseDto>(false, null, "Challenge ID and verification code are required.", 400);
        }

        var isEmail = string.Equals(request.Channel, "Email", StringComparison.OrdinalIgnoreCase);
        string verifiedDestination;

        if (isEmail)
        {
            var verifyResult = await _emailVerificationService.VerifyOtpAsync(
                new VerifyEmailOtpRequestDto(request.ChallengeId, request.FlowId, request.OtpCode),
                clientIp,
                cancellationToken);

            if (!verifyResult.Success || verifyResult.Response == null)
            {
                return new AuthResult<VerifySetupOtpResponseDto>(false, null, verifyResult.ErrorMessage ?? "Email verification failed.", verifyResult.StatusCode);
            }

            var challenge = await _dbContext.OtpChallenges.FindAsync(new object[] { request.ChallengeId }, cancellationToken);
            if (challenge == null || string.IsNullOrWhiteSpace(challenge.Email))
            {
                return new AuthResult<VerifySetupOtpResponseDto>(false, null, "Verification challenge not found.", 404);
            }

            verifiedDestination = challenge.Email;
        }
        else
        {
            var verifyResult = await _phoneVerificationService.VerifyOtpAsync(
                new VerifyOtpRequestDto(request.ChallengeId, request.FlowId, request.OtpCode),
                clientIp,
                cancellationToken);

            if (!verifyResult.Success || verifyResult.Response == null)
            {
                return new AuthResult<VerifySetupOtpResponseDto>(false, null, verifyResult.ErrorMessage ?? "Phone verification failed.", verifyResult.StatusCode);
            }

            var challenge = await _dbContext.OtpChallenges.FindAsync(new object[] { request.ChallengeId }, cancellationToken);
            if (challenge == null || string.IsNullOrWhiteSpace(challenge.PhoneNumber))
            {
                return new AuthResult<VerifySetupOtpResponseDto>(false, null, "Verification challenge not found.", 404);
            }

            verifiedDestination = challenge.PhoneNumber;
        }

        // Find member by verified destination
        var member = await _dbContext.Members
            .FirstOrDefaultAsync(m => m.Email == verifiedDestination || m.PhoneNumber == verifiedDestination, cancellationToken);

        if (member == null)
        {
            return new AuthResult<VerifySetupOtpResponseDto>(false, null, "No member account matching the verified destination was found.", 404);
        }

        // Issue fresh cryptographically secure CredentialSetupToken (30 min lifetime)
        var setupToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(30);

        member.CredentialSetupToken = setupToken;
        member.CredentialSetupTokenExpiresAtUtc = expiresAtUtc;
        member.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Auth] Issued fresh CredentialSetupToken for Member ID {MemberId} after OTP verification.", member.Id);

        var responseDto = new VerifySetupOtpResponseDto(
            Success: true,
            CredentialSetupToken: setupToken,
            ExpiresAtUtc: expiresAtUtc,
            Destination: verifiedDestination,
            Message: "Verification successful. You may now create your password."
        );

        return new AuthResult<VerifySetupOtpResponseDto>(true, responseDto, null, 200);
    }

    public async Task<AuthResult<MemberProfileResponseDto>> UpdateMemberProfileAsync(
        int authenticatedMemberId,
        UpdateMemberProfileRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return new AuthResult<MemberProfileResponseDto>(false, null, "Full name is required.", 400);
        }

        var member = await _dbContext.Members
            .Include(m => m.BusinessProfile)
            .Include(m => m.EmployeeProfile)
            .Include(m => m.ServiceEngineerProfile)
            .Include(m => m.TraderProfile)
            .Include(m => m.ContractorProfile)
            .FirstOrDefaultAsync(m => m.Id == authenticatedMemberId, cancellationToken);

        if (member == null)
        {
            return new AuthResult<MemberProfileResponseDto>(false, null, "Member profile not found.", 404);
        }

        if (!member.IsActive)
        {
            return new AuthResult<MemberProfileResponseDto>(false, null, "Member account is inactive.", 401);
        }

        // Apply FullName update
        member.FullName = request.FullName.Trim();
        member.UpdatedAtUtc = DateTime.UtcNow;

        // Apply profile-type specific updates
        switch (member.PrimaryProfileType)
        {
            case ProfileTypeEnum.BusinessCompany:
                if (request.BusinessDetails == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Business details are required for Business / Company profile.", 400);
                }

                if (string.IsNullOrWhiteSpace(request.BusinessDetails.CompanyName))
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Company name is required.", 400);
                }

                // Validate 4-tier hierarchy
                var bCategory = await _dbContext.Categories
                    .Include(c => c.SubGroup)
                        .ThenInclude(sg => sg.BusinessGroup)
                    .FirstOrDefaultAsync(c => c.Id == request.BusinessDetails.CategoryId, cancellationToken);

                if (bCategory == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Category does not exist.", 400);
                }

                if (bCategory.SubGroupId != request.BusinessDetails.SubGroupId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Category does not belong to the chosen SubGroup.", 400);
                }

                if (bCategory.SubGroup.BusinessGroupId != request.BusinessDetails.BusinessGroupId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected SubGroup does not belong to the chosen Business Group.", 400);
                }

                if (bCategory.SubGroup.BusinessGroup.IndustryId != request.BusinessDetails.IndustryId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Business Group does not belong to the chosen Industry.", 400);
                }

                if (member.BusinessProfile == null)
                {
                    member.BusinessProfile = new BusinessProfile
                    {
                        MemberId = member.Id
                    };
                    _dbContext.BusinessProfiles.Add(member.BusinessProfile);
                }

                member.BusinessProfile.CompanyName = request.BusinessDetails.CompanyName.Trim();
                member.BusinessProfile.BusinessCapabilities = request.BusinessDetails.BusinessCapabilities != null && request.BusinessDetails.BusinessCapabilities.Count > 0
                    ? string.Join(", ", request.BusinessDetails.BusinessCapabilities.Select(c => c.Trim()).Where(c => !string.IsNullOrEmpty(c)))
                    : string.Empty;
                member.BusinessProfile.BusinessDescription = request.BusinessDetails.BusinessDescription?.Trim() ?? string.Empty;
                member.BusinessProfile.IndustryId = request.BusinessDetails.IndustryId;
                member.BusinessProfile.BusinessGroupId = request.BusinessDetails.BusinessGroupId;
                member.BusinessProfile.SubGroupId = request.BusinessDetails.SubGroupId;
                member.BusinessProfile.CategoryId = request.BusinessDetails.CategoryId;
                break;

            case ProfileTypeEnum.EmployeeJobSeeker:
                if (request.EmployeeDetails == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Employee details are required.", 400);
                }

                if (string.IsNullOrWhiteSpace(request.EmployeeDetails.JobTitle))
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Job title is required.", 400);
                }

                if (member.EmployeeProfile == null)
                {
                    member.EmployeeProfile = new EmployeeProfile
                    {
                        MemberId = member.Id
                    };
                    _dbContext.EmployeeProfiles.Add(member.EmployeeProfile);
                }

                member.EmployeeProfile.JobTitle = request.EmployeeDetails.JobTitle.Trim();
                member.EmployeeProfile.Skills = request.EmployeeDetails.Skills?.Trim() ?? string.Empty;
                member.EmployeeProfile.Experience = request.EmployeeDetails.Experience?.Trim() ?? string.Empty;
                member.EmployeeProfile.PreferredJobType = request.EmployeeDetails.PreferredJobType?.Trim() ?? string.Empty;
                break;

            case ProfileTypeEnum.ServiceEngineer:
                if (request.ServiceEngineerDetails == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Service engineer details are required.", 400);
                }

                if (string.IsNullOrWhiteSpace(request.ServiceEngineerDetails.Specialization))
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Specialization is required.", 400);
                }

                if (member.ServiceEngineerProfile == null)
                {
                    member.ServiceEngineerProfile = new ServiceEngineerProfile
                    {
                        MemberId = member.Id
                    };
                    _dbContext.ServiceEngineerProfiles.Add(member.ServiceEngineerProfile);
                }

                member.ServiceEngineerProfile.Specialization = request.ServiceEngineerDetails.Specialization.Trim();
                member.ServiceEngineerProfile.SupportedEquipment = request.ServiceEngineerDetails.SupportedEquipment?.Trim() ?? string.Empty;
                member.ServiceEngineerProfile.YearsOfExperience = request.ServiceEngineerDetails.YearsOfExperience?.Trim() ?? string.Empty;
                member.ServiceEngineerProfile.ServiceCoverage = request.ServiceEngineerDetails.ServiceCoverage?.Trim() ?? string.Empty;
                break;

            case ProfileTypeEnum.TraderSupplier:
                if (request.TraderDetails == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Trader details are required.", 400);
                }

                if (string.IsNullOrWhiteSpace(request.TraderDetails.TradingName))
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Trading name is required.", 400);
                }

                if (member.TraderProfile == null)
                {
                    member.TraderProfile = new TraderProfile
                    {
                        MemberId = member.Id
                    };
                    _dbContext.TraderProfiles.Add(member.TraderProfile);
                }

                member.TraderProfile.TradingName = request.TraderDetails.TradingName.Trim();
                member.TraderProfile.Capabilities = request.TraderDetails.Capabilities != null && request.TraderDetails.Capabilities.Count > 0
                    ? string.Join(", ", request.TraderDetails.Capabilities.Select(c => c.Trim()).Where(c => !string.IsNullOrEmpty(c)))
                    : string.Empty;
                member.TraderProfile.ProductsSupplied = request.TraderDetails.ProductsSupplied?.Trim() ?? string.Empty;
                member.TraderProfile.ServiceCoverage = request.TraderDetails.ServiceCoverage?.Trim() ?? string.Empty;
                break;

            case ProfileTypeEnum.ContractorJobWorker:
                if (request.ContractorDetails == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Contractor details are required.", 400);
                }

                if (string.IsNullOrWhiteSpace(request.ContractorDetails.WorkName))
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Work name is required.", 400);
                }

                // Validate 4-tier hierarchy
                var cCategory = await _dbContext.Categories
                    .Include(c => c.SubGroup)
                        .ThenInclude(sg => sg.BusinessGroup)
                    .FirstOrDefaultAsync(c => c.Id == request.ContractorDetails.CategoryId, cancellationToken);

                if (cCategory == null)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Category does not exist.", 400);
                }

                if (cCategory.SubGroupId != request.ContractorDetails.SubGroupId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Category does not belong to the chosen SubGroup.", 400);
                }

                if (cCategory.SubGroup.BusinessGroupId != request.ContractorDetails.BusinessGroupId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected SubGroup does not belong to the chosen Business Group.", 400);
                }

                if (cCategory.SubGroup.BusinessGroup.IndustryId != request.ContractorDetails.IndustryId)
                {
                    return new AuthResult<MemberProfileResponseDto>(false, null, "Selected Business Group does not belong to the chosen Industry.", 400);
                }

                if (member.ContractorProfile == null)
                {
                    member.ContractorProfile = new ContractorProfile
                    {
                        MemberId = member.Id
                    };
                    _dbContext.ContractorProfiles.Add(member.ContractorProfile);
                }

                member.ContractorProfile.WorkName = request.ContractorDetails.WorkName.Trim();
                member.ContractorProfile.WorkCapabilities = request.ContractorDetails.WorkCapabilities != null && request.ContractorDetails.WorkCapabilities.Count > 0
                    ? string.Join(", ", request.ContractorDetails.WorkCapabilities.Select(c => c.Trim()).Where(c => !string.IsNullOrEmpty(c)))
                    : string.Empty;
                member.ContractorProfile.ProcessesSupported = request.ContractorDetails.ProcessesSupported?.Trim() ?? string.Empty;
                member.ContractorProfile.WorkCoverage = request.ContractorDetails.WorkCoverage?.Trim() ?? string.Empty;
                member.ContractorProfile.IndustryId = request.ContractorDetails.IndustryId;
                member.ContractorProfile.BusinessGroupId = request.ContractorDetails.BusinessGroupId;
                member.ContractorProfile.SubGroupId = request.ContractorDetails.SubGroupId;
                member.ContractorProfile.CategoryId = request.ContractorDetails.CategoryId;
                break;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("[Auth] Successfully updated profile for Member ID {MemberId}", authenticatedMemberId);

        return await GetMemberProfileAsync(authenticatedMemberId, cancellationToken);
    }
}
