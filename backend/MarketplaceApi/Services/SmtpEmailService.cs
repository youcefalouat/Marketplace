using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace MarketplaceApi.Services;

public class EmailSettings
{
    public string SmtpHost { get; set; } = string.Empty;
    public int SmtpPort { get; set; } = 587;
    public bool UseSsl { get; set; } = true;
    public string SenderEmail { get; set; } = string.Empty;
    public string SenderName { get; set; } = "Marketplace Controlée";
    // Optional: if different from SenderEmail (e.g., SendGrid uses "apikey")
    public string? Username { get; set; }
    public string BaseUrl { get; set; } = string.Empty;
}

public class SmtpEmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IOptions<EmailSettings> settings, ILogger<SmtpEmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendEmailVerificationAsync(string toEmail, string toName, string verificationLink)
    {
        var body = BuildVerificationEmailHtml(toName, verificationLink);
        await SendAsync(toEmail, toName, "Vérifiez votre adresse email — Marketplace Controlée", body);
    }

    public async Task SendPasswordResetEmailAsync(string toEmail, string toName, string resetLink)
    {
        var body = BuildPasswordResetEmailHtml(toName, resetLink);
        await SendAsync(toEmail, toName, "Réinitialisez votre mot de passe — Marketplace Controlée", body);
    }

    public async Task SendGenericEmailAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        await SendAsync(toEmail, toName, subject, htmlBody);
    }

    private async Task SendAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        if (string.IsNullOrWhiteSpace(_settings.SmtpHost))
        {
            _logger.LogWarning("SMTP not configured. Would send '{Subject}' to {Email}", subject, toEmail);
            return;
        }

        using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort)
        {
            EnableSsl = _settings.UseSsl,
            Credentials = new NetworkCredential(
                _settings.Username ?? _settings.SenderEmail,
                GetSmtpPassword()
            )
        };

        using var message = new MailMessage
        {
            From = new MailAddress(_settings.SenderEmail, _settings.SenderName),
            Subject = subject,
            Body = htmlBody,
            IsBodyHtml = true
        };
        message.To.Add(new MailAddress(toEmail, toName));

        await client.SendMailAsync(message);
    }

    private string GetSmtpPassword()
        => Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? string.Empty;

    private static string BuildVerificationEmailHtml(string name, string link)
    {
        return $"""
            <!DOCTYPE html>
            <html lang="fr">
            <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
            <body style="font-family:Arial,sans-serif;background:#f5f5f5;margin:0;padding:20px;">
              <div style="max-width:520px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 16px rgba(0,0,0,.08);">
                <div style="background:#2563EB;padding:32px;text-align:center;">
                  <h1 style="color:#fff;margin:0;font-size:22px;">Marketplace Controlée</h1>
                </div>
                <div style="padding:32px;">
                  <h2 style="color:#1a1a1a;margin-bottom:8px;font-size:20px;">Vérification de votre email</h2>
                  <p style="color:#555;margin-bottom:24px;">Bonjour <strong>{System.Net.WebUtility.HtmlEncode(name)}</strong>,</p>
                  <p style="color:#555;">Cliquez sur le bouton ci-dessous pour vérifier votre adresse email.<br>Ce lien expire dans <strong>24 heures</strong>.</p>
                  <div style="text-align:center;margin:32px 0;">
                    <a href="{link}" style="background:#2563EB;color:#fff;padding:14px 36px;border-radius:8px;text-decoration:none;font-weight:bold;font-size:16px;display:inline-block;">
                      ✉ Vérifier mon email
                    </a>
                  </div>
                  <p style="color:#777;font-size:13px;">Ou copiez ce lien dans votre navigateur :</p>
                  <p style="color:#2563EB;font-size:12px;word-break:break-all;">{link}</p>
                  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
                  <p style="color:#999;font-size:12px;">Si vous n'avez pas créé de compte sur Marketplace Controlée, ignorez cet email.</p>
                </div>
                <div style="background:#f9f9f9;padding:16px;text-align:center;">
                  <p style="color:#bbb;font-size:11px;margin:0;">© Marketplace Controlée — Algérie</p>
                </div>
              </div>
            </body></html>
            """;
    }

    private static string BuildPasswordResetEmailHtml(string name, string link)
    {
        return $"""
            <!DOCTYPE html>
            <html lang="fr">
            <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
            <body style="font-family:Arial,sans-serif;background:#f5f5f5;margin:0;padding:20px;">
              <div style="max-width:520px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 16px rgba(0,0,0,.08);">
                <div style="background:#dc2626;padding:32px;text-align:center;">
                  <h1 style="color:#fff;margin:0;font-size:22px;">Marketplace Controlée</h1>
                </div>
                <div style="padding:32px;">
                  <h2 style="color:#1a1a1a;margin-bottom:8px;font-size:20px;">Réinitialisation du mot de passe</h2>
                  <p style="color:#555;margin-bottom:24px;">Bonjour <strong>{System.Net.WebUtility.HtmlEncode(name)}</strong>,</p>
                  <p style="color:#555;">Vous avez demandé à réinitialiser votre mot de passe.<br>Cliquez sur le bouton ci-dessous. Ce lien expire dans <strong>1 heure</strong>.</p>
                  <div style="text-align:center;margin:32px 0;">
                    <a href="{link}" style="background:#dc2626;color:#fff;padding:14px 36px;border-radius:8px;text-decoration:none;font-weight:bold;font-size:16px;display:inline-block;">
                      🔑 Réinitialiser mon mot de passe
                    </a>
                  </div>
                  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
                  <p style="color:#999;font-size:12px;">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
                </div>
                <div style="background:#f9f9f9;padding:16px;text-align:center;">
                  <p style="color:#bbb;font-size:11px;margin:0;">© Marketplace Controlée — Algérie</p>
                </div>
              </div>
            </body></html>
            """;
    }
}
