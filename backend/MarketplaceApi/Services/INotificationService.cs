using MarketplaceApi.DTOs;

namespace MarketplaceApi.Services;

public interface INotificationService
{
    Task SendMessageNotificationAsync(
        int recipientId,
        MessageDto message,
        string senderName,
        CancellationToken cancellationToken = default);
}
