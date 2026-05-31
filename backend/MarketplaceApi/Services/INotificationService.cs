using MarketplaceApi.DTOs;

namespace MarketplaceApi.Services;

public interface INotificationService
{
    Task SendMessageNotificationAsync(
        int recipientId,
        MessageDto message,
        string senderName,
        CancellationToken cancellationToken = default);

    Task SendPushNotificationAsync(
        int userId,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
}
