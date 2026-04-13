namespace MarketplaceApi.Services;

public interface ISmsService
{
    Task<bool> SendVerificationCodeAsync(string phoneNumber);
    Task<bool> VerifyCodeAsync(string phoneNumber, string code);
}
