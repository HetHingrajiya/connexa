using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Services;

public class OtpCryptographyServiceTests
{
    private readonly IOtpCryptographyService _crypto;

    public OtpCryptographyServiceTests()
    {
        var options = Options.Create(new OtpSecurityOptions
        {
            HmacSecretKey = "Test_Secret_Key_For_Unit_Tests_32_Bytes_Long_Minimum"
        });
        _crypto = new OtpCryptographyService(options);
    }

    [Fact]
    public void GenerateOtpCode_ShouldReturnSixDigitNumericString()
    {
        for (int i = 0; i < 50; i++)
        {
            var code = _crypto.GenerateOtpCode();
            Assert.NotNull(code);
            Assert.Equal(6, code.Length);
            Assert.True(int.TryParse(code, out var numericVal));
            Assert.InRange(numericVal, 100000, 999999);
        }
    }

    [Fact]
    public void GenerateSalt_ShouldReturnUniqueBase64Strings()
    {
        var salt1 = _crypto.GenerateSalt();
        var salt2 = _crypto.GenerateSalt();

        Assert.NotEmpty(salt1);
        Assert.NotEmpty(salt2);
        Assert.NotEqual(salt1, salt2);

        var bytes1 = Convert.FromBase64String(salt1);
        Assert.Equal(16, bytes1.Length);
    }

    [Fact]
    public void HashOtp_ShouldProduceConsistentHashForSameInputs()
    {
        var otp = "123456";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";

        var hash1 = _crypto.HashOtp(otp, salt, phone);
        var hash2 = _crypto.HashOtp(otp, salt, phone);

        Assert.Equal(hash1, hash2);
    }

    [Fact]
    public void HashOtp_ShouldProduceDifferentHashWhenAnyParameterChanges()
    {
        var otp = "123456";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";

        var hashBase = _crypto.HashOtp(otp, salt, phone);
        var hashDiffOtp = _crypto.HashOtp("654321", salt, phone);
        var hashDiffPhone = _crypto.HashOtp(otp, salt, "+919999999999");
        var hashDiffSalt = _crypto.HashOtp(otp, _crypto.GenerateSalt(), phone);

        Assert.NotEqual(hashBase, hashDiffOtp);
        Assert.NotEqual(hashBase, hashDiffPhone);
        Assert.NotEqual(hashBase, hashDiffSalt);
    }

    [Fact]
    public void VerifyOtp_ShouldReturnTrueForCorrectCode()
    {
        var otp = "874521";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";
        var hash = _crypto.HashOtp(otp, salt, phone);

        var result = _crypto.VerifyOtp(otp, salt, phone, hash);

        Assert.True(result);
    }

    [Fact]
    public void VerifyOtp_ShouldReturnFalseForIncorrectCode()
    {
        var otp = "874521";
        var wrongOtp = "123456";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";
        var hash = _crypto.HashOtp(otp, salt, phone);

        var result = _crypto.VerifyOtp(wrongOtp, salt, phone, hash);

        Assert.False(result);
    }

    [Fact]
    public void VerifyOtp_ShouldReturnFalseForDifferentPhoneDestination()
    {
        var otp = "874521";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";
        var diffPhone = "+919111111111";
        var hash = _crypto.HashOtp(otp, salt, phone);

        var result = _crypto.VerifyOtp(otp, salt, diffPhone, hash);

        Assert.False(result);
    }

    [Fact]
    public void GenerateVerificationGrant_ShouldReturnOpaqueToken()
    {
        var grant1 = _crypto.GenerateVerificationGrant();
        var grant2 = _crypto.GenerateVerificationGrant();

        Assert.NotEmpty(grant1);
        Assert.NotEmpty(grant2);
        Assert.Equal(64, grant1.Length); // 32 bytes hex = 64 chars
        Assert.NotEqual(grant1, grant2);
    }

    [Theory]
    [InlineData("9876543210", "+919876543210")]
    [InlineData("+91 98765 43210", "+919876543210")]
    [InlineData("+1 (555) 123-4567", "+15551234567")]
    [InlineData("0044 7911 123456", "+447911123456")]
    public void NormalizePhoneNumber_ShouldFormatToStandardE164(string input, string expected)
    {
        var normalized = _crypto.NormalizePhoneNumber(input);
        Assert.Equal(expected, normalized);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("12345")] // too short
    [InlineData("abcde")]
    public void NormalizePhoneNumber_InvalidInput_ShouldThrowArgumentException(string invalidInput)
    {
        Assert.Throws<ArgumentException>(() => _crypto.NormalizePhoneNumber(invalidInput));
    }

    [Fact]
    public void MaskPhoneNumber_ShouldMaskMiddleDigits()
    {
        var masked = _crypto.MaskPhoneNumber("+919876543210");
        Assert.Contains("+91", masked);
        Assert.Contains("210", masked);
        Assert.DoesNotContain("98765", masked);
    }

    [Theory]
    [InlineData("user@example.com", "user@example.com")]
    [InlineData("  USER@EXAMPLE.COM  ", "user@example.com")]
    [InlineData("john.doe+test@sub.domain.co.in", "john.doe+test@sub.domain.co.in")]
    public void NormalizeEmail_ShouldTrimAndLower(string input, string expected)
    {
        var normalized = _crypto.NormalizeEmail(input);
        Assert.Equal(expected, normalized);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("notanemail")]
    [InlineData("@nodomain.com")]
    [InlineData("user@")]
    public void NormalizeEmail_InvalidInput_ShouldThrowArgumentException(string invalidInput)
    {
        Assert.Throws<ArgumentException>(() => _crypto.NormalizeEmail(invalidInput));
    }

    [Theory]
    [InlineData("john.doe@example.com", "j•••e@example.com")]
    [InlineData("ab@domain.com", "a*@domain.com")]
    [InlineData("a@domain.com", "a*@domain.com")]
    public void MaskEmail_ShouldMaskLocalPart(string email, string expected)
    {
        var masked = _crypto.MaskEmail(email);
        Assert.Equal(expected, masked);
    }

    [Fact]
    public void HashEmailOtp_And_VerifyEmailOtp_ShouldVerifyCorrectly()
    {
        var otp = "654321";
        var salt = _crypto.GenerateSalt();
        var email = "partner@connexa.com";
        var hash = _crypto.HashEmailOtp(otp, salt, email);

        Assert.True(_crypto.VerifyEmailOtp(otp, salt, email, hash));
        Assert.False(_crypto.VerifyEmailOtp("999999", salt, email, hash));
        Assert.False(_crypto.VerifyEmailOtp(otp, salt, "other@connexa.com", hash));
    }

    [Fact]
    public void CrossChannel_PhoneOtpCannotVerifyEmailOtpAndViceVersa()
    {
        var otp = "123456";
        var salt = _crypto.GenerateSalt();
        var phone = "+919876543210";
        var email = "9876543210@gmail.com";

        var phoneHash = _crypto.HashOtp(otp, salt, phone);
        var emailHash = _crypto.HashEmailOtp(otp, salt, email);

        // Hashes must be completely distinct due to domain prefixing
        Assert.NotEqual(phoneHash, emailHash);

        // Verification must fail across channels
        Assert.False(_crypto.VerifyEmailOtp(otp, salt, email, phoneHash));
        Assert.False(_crypto.VerifyOtp(otp, salt, phone, emailHash));
    }
}
