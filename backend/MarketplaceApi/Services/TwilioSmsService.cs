using Microsoft.Extensions.Options;
using Twilio;
using Twilio.Rest.Verify.V2.Service;
using MarketplaceApi.Models;

namespace MarketplaceApi.Services;

public class TwilioSmsService : ISmsService
{
    private readonly TwilioSettings _settings;
    private readonly ILogger<TwilioSmsService> _logger;

    public TwilioSmsService(IOptions<TwilioSettings> settings, ILogger<TwilioSmsService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
        TwilioClient.Init(_settings.AccountSid, _settings.AuthToken);
    }

    public async Task<bool> SendVerificationCodeAsync(string phoneNumber)
    {
        try
        {
            // Ensure phone is in global E.164 format. 
            // In Algeria for instance, if it starts with '0', replace with +213.
            var formattedPhone = FormatPhoneNumber(phoneNumber);

            var verification = await VerificationResource.CreateAsync(
                to: formattedPhone,
                channel: "sms",
                pathServiceSid: _settings.VerificationServiceSid
            );

            _logger.LogInformation($"Twilio status: {verification.Status}");
            return verification.Status == "pending" || verification.Status == "approved";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending Twilio verification code.");
            throw;
        }
    }

    public async Task<bool> VerifyCodeAsync(string phoneNumber, string code)
    {
        try
        {
            var formattedPhone = FormatPhoneNumber(phoneNumber);

            var verificationCheck = await VerificationCheckResource.CreateAsync(
                to: formattedPhone,
                code: code,
                pathServiceSid: _settings.VerificationServiceSid
            );

            _logger.LogInformation($"Twilio Verify status: {verificationCheck.Status}");
            return verificationCheck.Status == "approved";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking Twilio verification code.");
            return false;
        }
    }

    private string FormatPhoneNumber(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return phone;
        
        // Remove spaces
        phone = phone.Replace(" ", "");

        // Assuming Algerian numbers that start with '0', to make it international +213...
        // If it already contains '+', we assume it's correctly formatted.
        if (!phone.StartsWith("+"))
        {
            if (phone.StartsWith("0"))
            {
                phone = "+213" + phone.Substring(1);
            }
            else
            {
                // Fallback, prepend +
                phone = "+" + phone;
            }
        }
        
        return phone;
    }
}
