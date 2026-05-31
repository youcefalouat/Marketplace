using FirebaseAdmin.Messaging;
using MarketplaceApi.Data;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.DTOs;

namespace MarketplaceApi.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly ChatConnectionManager _connectionManager;

    public NotificationService(
        ApplicationDbContext context, 
        ChatConnectionManager connectionManager)
    {
        _context = context;
        _connectionManager = connectionManager;
    }

    public async Task SendMessageNotificationAsync(
        int recipientId,
        MessageDto message,
        string senderName,
        CancellationToken cancellationToken = default)
    {
        bool isOnline = _connectionManager.IsUserOnline(recipientId);

        if (isOnline)
        {
            return;
        }

        // User is offline, send FCM
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == recipientId, cancellationToken);
        if (user != null && !string.IsNullOrEmpty(user.FcmToken))
        {
            var fcmMessage = new FirebaseAdmin.Messaging.Message
            {
                Token = user.FcmToken,
                Notification = new Notification
                {
                    Title = $"Nouveau message de {senderName}",
                    Body = message.Content.Length > 50 ? message.Content.Substring(0, 47) + "..." : message.Content
                },
                Data = new Dictionary<string, string>
                {
                    { "type", "chat_message" },
                    { "conversationId", message.ConversationId.ToString() }
                }
            };

            try
            {
                // Note: FirebaseApp.DefaultInstance must be initialized in Program.cs
                if (FirebaseAdmin.FirebaseApp.DefaultInstance != null)
                {
                    await FirebaseMessaging.DefaultInstance.SendAsync(fcmMessage);
                }
            }
            catch (Exception)
            {
                // Silent catch for invalid tokens or disabled Firebase credentials in this environment
            }
        }
    }

    public async Task SendPushNotificationAsync(
        int userId,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

        if (user == null || string.IsNullOrEmpty(user.FcmToken))
            return;

        var fcmMessage = new FirebaseAdmin.Messaging.Message
        {
            Token = user.FcmToken,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>()
        };

        try
        {
            if (FirebaseAdmin.FirebaseApp.DefaultInstance != null)
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(fcmMessage, cancellationToken);
            }
        }
        catch (Exception)
        {
            // Silent catch for invalid tokens or disabled Firebase credentials
        }
    }
}
