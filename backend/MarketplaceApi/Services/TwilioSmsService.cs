using Microsoft.Extensions.Options;
using Twilio;
using Twilio.Exceptions;
using Twilio.Rest.Verify.V2.Service;
using MarketplaceApi.Models;

namespace MarketplaceApi.Services;

public class TwilioSmsService : ISmsService
{
    private readonly TwilioSettings _settings;
    private readonly ILogger<TwilioSmsService> _logger;
    private readonly bool _isConfigured;

    public TwilioSmsService(IOptions<TwilioSettings> settings, ILogger<TwilioSmsService> logger)
    {
        _settings = settings.Value;
        _logger = logger;

        // Validate credentials at startup
        if (string.IsNullOrWhiteSpace(_settings.AccountSid) ||
            string.IsNullOrWhiteSpace(_settings.AuthToken) ||
            string.IsNullOrWhiteSpace(_settings.VerificationServiceSid))
        {
            _logger.LogCritical(
                "Twilio credentials are missing or empty! " +
                "AccountSid={HasSid}, AuthToken={HasToken}, ServiceSid={HasService}. " +
                "SMS verification will NOT work. " +
                "Set Twilio:AccountSid, Twilio:AuthToken, and Twilio:VerificationServiceSid in appsettings.json.",
                !string.IsNullOrWhiteSpace(_settings.AccountSid),
                !string.IsNullOrWhiteSpace(_settings.AuthToken),
                !string.IsNullOrWhiteSpace(_settings.VerificationServiceSid));
            _isConfigured = false;
        }
        else
        {
            TwilioClient.Init(_settings.AccountSid, _settings.AuthToken);
            _isConfigured = true;
            _logger.LogInformation(
                "Twilio SMS service initialized. AccountSid={AccountSid}, ServiceSid={ServiceSid}",
                _settings.AccountSid[..Math.Min(8, _settings.AccountSid.Length)] + "...",
                _settings.VerificationServiceSid[..Math.Min(8, _settings.VerificationServiceSid.Length)] + "...");
        }
    }

    public async Task<bool> SendVerificationCodeAsync(string phoneNumber)
    {
        if (!_isConfigured)
        {
            throw new InvalidOperationException(
                "Le service SMS n'est pas configuré. Contactez l'administrateur.");
        }

        var formattedPhone = FormatPhoneNumber(phoneNumber);
        _logger.LogInformation("Sending verification code to {Phone}", MaskPhone(formattedPhone));

        try
        {
            var verification = await VerificationResource.CreateAsync(
                to: formattedPhone,
                channel: "sms",
                pathServiceSid: _settings.VerificationServiceSid
            );

            _logger.LogInformation("Twilio send status: {Status} for {Phone}",
                verification.Status, MaskPhone(formattedPhone));
            return verification.Status == "pending" || verification.Status == "approved";
        }
        catch (ApiException ex)
        {
            _logger.LogError(ex, "Twilio API error sending verification. Code={Code}, Status={Status}, MoreInfo={MoreInfo}",
                ex.Code, ex.Status, ex.MoreInfo);
            throw new InvalidOperationException(TranslateTwilioError(ex), ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error sending verification to {Phone}", MaskPhone(formattedPhone));
            throw new InvalidOperationException("Erreur lors de l'envoi du SMS. Veuillez réessayer.", ex);
        }
    }

    public async Task<bool> VerifyCodeAsync(string phoneNumber, string code)
    {
        if (!_isConfigured)
        {
            throw new InvalidOperationException(
                "Le service SMS n'est pas configuré. Contactez l'administrateur.");
        }

        var formattedPhone = FormatPhoneNumber(phoneNumber);
        _logger.LogInformation("Verifying code for {Phone}", MaskPhone(formattedPhone));

        try
        {
            var verificationCheck = await VerificationCheckResource.CreateAsync(
                to: formattedPhone,
                code: code,
                pathServiceSid: _settings.VerificationServiceSid
            );

            _logger.LogInformation("Twilio verify status: {Status} for {Phone}",
                verificationCheck.Status, MaskPhone(formattedPhone));
            return verificationCheck.Status == "approved";
        }
        catch (ApiException ex)
        {
            _logger.LogError(ex, "Twilio API error verifying code. Code={Code}, Status={Status}",
                ex.Code, ex.Status);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error verifying code for {Phone}", MaskPhone(formattedPhone));
            return false;
        }
    }

    private static string FormatPhoneNumber(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return phone;
        
        // Remove spaces, dashes, parentheses
        phone = phone.Replace(" ", "").Replace("-", "").Replace("(", "").Replace(")", "");

        // Algerian numbers: convert local format to international E.164
        if (!phone.StartsWith("+"))
        {
            if (phone.StartsWith("0"))
            {
                phone = "+213" + phone.Substring(1);
            }
            else
            {
                phone = "+" + phone;
            }
        }
        
        return phone;
    }

    private static string MaskPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone) || phone.Length < 6) return "***";
        return phone[..4] + "****" + phone[^2..];
    }

    private static string TranslateTwilioError(ApiException ex)
    {
        return ex.Code switch
        {
            60200 => "Numéro de téléphone invalide. Vérifiez le format.",
            60203 => "Trop de tentatives. Veuillez attendre quelques minutes.",
            60212 => "Ce numéro ne peut pas recevoir de SMS.",
            20003 => "Erreur d'authentification du service SMS. Contactez l'administrateur.",
            20404 => "Service SMS non configuré correctement. Contactez l'administrateur.",
            _ => $"Erreur du service SMS (code {ex.Code}). Veuillez réessayer.",
        };
    }
}
