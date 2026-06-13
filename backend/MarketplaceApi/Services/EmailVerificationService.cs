using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;

namespace MarketplaceApi.Services;

public interface IEmailVerificationService
{
    string GenerateToken();
    string BuildVerificationLink(string token, string email);
}

public class EmailVerificationService : IEmailVerificationService
{
    private readonly EmailSettings _settings;

    public EmailVerificationService(IOptions<EmailSettings> settings)
    {
        _settings = settings.Value;
    }

    public string GenerateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(48);
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }

    public string BuildVerificationLink(string token, string email)
    {
        var baseUrl = _settings.BaseUrl.TrimEnd('/');
        var encodedToken = Uri.EscapeDataString(token);
        var encodedEmail = Uri.EscapeDataString(email);
        return $"{baseUrl}/verify-email?token={encodedToken}&email={encodedEmail}";
    }
}
