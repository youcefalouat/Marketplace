using MarketplaceApi.Data;
using MarketplaceApi.Models;
using Microsoft.EntityFrameworkCore;

namespace MarketplaceApi.Services;

public enum AccountDeletionResult
{
    Success,
    NotFound,
    AlreadyDeleted,
    InvalidInput
}

public interface IAccountDeletionService
{
    Task<AccountDeletionResult> RequestDeletionAsync(int userId, CancellationToken cancellationToken = default);
    Task<AccountDeletionResult> RequestDeletionAsync(string? email, string? phone, CancellationToken cancellationToken = default);
}

public class AccountDeletionService : IAccountDeletionService
{
    private readonly ApplicationDbContext _context;

    public AccountDeletionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<AccountDeletionResult> RequestDeletionAsync(int userId, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FindAsync(new object?[] { userId }, cancellationToken);
        if (user == null)
        {
            return AccountDeletionResult.NotFound;
        }

        return await ApplyDeletionAsync(user, cancellationToken);
    }

    public async Task<AccountDeletionResult> RequestDeletionAsync(string? email, string? phone, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) && string.IsNullOrWhiteSpace(phone))
        {
            return AccountDeletionResult.InvalidInput;
        }

        var normalizedEmail = email?.Trim().ToLowerInvariant();
        var normalizedPhone = NormalizePhone(phone);

        User? user = null;

        if (!string.IsNullOrWhiteSpace(normalizedEmail))
        {
            user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail, cancellationToken);
        }

        if (user == null && !string.IsNullOrWhiteSpace(normalizedPhone))
        {
            user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == normalizedPhone, cancellationToken);
        }

        if (user == null)
        {
            return AccountDeletionResult.NotFound;
        }

        return await ApplyDeletionAsync(user, cancellationToken);
    }

    private async Task<AccountDeletionResult> ApplyDeletionAsync(User user, CancellationToken cancellationToken)
    {
        if (user.IsDeleted)
        {
            return AccountDeletionResult.AlreadyDeleted;
        }

        var anonymizedEmail = $"deleted-{user.Id}-{Guid.NewGuid():N}@deleted.local";

        user.IsDeleted = true;
        user.Email = anonymizedEmail;
        user.Name = "Compte supprimé";
        user.Phone = string.Empty;
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString());
        user.Provider = null;
        user.ProviderId = null;
        user.FcmToken = null;
        user.AvatarUrl = null;
        user.EmailVerified = false;
        user.PhoneVerified = false;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        user.PhoneVerificationCode = null;
        user.PhoneVerificationExpiry = null;
        user.VerifiedAt = null;
        user.Role = UserRole.User;

        await _context.SaveChangesAsync(cancellationToken);
        return AccountDeletionResult.Success;
    }

    private static string NormalizePhone(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
        {
            return string.Empty;
        }

        return new string(phone.Where(char.IsDigit).ToArray());
    }
}
