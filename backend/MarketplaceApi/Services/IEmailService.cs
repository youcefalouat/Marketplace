namespace MarketplaceApi.Services;

public interface IEmailService
{
    Task SendEmailVerificationAsync(string toEmail, string toName, string verificationLink);
    Task SendPasswordResetEmailAsync(string toEmail, string toName, string resetLink);
    Task SendGenericEmailAsync(string toEmail, string toName, string subject, string htmlBody);
}
