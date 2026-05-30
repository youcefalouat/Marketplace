using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;

namespace MarketplaceApi.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly ApplicationDbContext _context;
    private readonly Services.ChatConnectionManager _connectionManager;

    public ChatHub(ApplicationDbContext context, Services.ChatConnectionManager connectionManager)
    {
        _context = context;
        _connectionManager = connectionManager;
    }

    public static string GetUserGroupName(int userId) => $"user_{userId}";
    public static string GetConversationGroupName(int conversationId) => $"conversation_{conversationId}";

    public override async Task OnConnectedAsync()
    {
        var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userIdClaim) && int.TryParse(userIdClaim, out var userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, GetUserGroupName(userId));
            var becameOnline = _connectionManager.ConnectUser(userId, Context.ConnectionId);
            if (becameOnline)
            {
                await NotifyContactsAsync(userId, "UserOnline");
            }
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userIdClaim) && int.TryParse(userIdClaim, out var userId))
        {
            var becameOffline = _connectionManager.DisconnectUser(userId, Context.ConnectionId);
            if (becameOffline)
            {
                await NotifyContactsAsync(userId, "UserOffline");
            }
        }

        await base.OnDisconnectedAsync(exception);
    }

    // Fix #14: Validate that the authenticated user belongs to the conversation
    public async Task JoinConversation(int conversationId)
    {
        var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
        {
            throw new HubException("Unauthorized");
        }

        var isMember = await _context.Conversations
            .AsNoTracking()
            .AnyAsync(c => c.Id == conversationId && (c.BuyerId == userId || c.SellerId == userId));

        if (!isMember)
        {
            throw new HubException("You are not a member of this conversation");
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, GetConversationGroupName(conversationId));
    }

    public async Task LeaveConversation(int conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetConversationGroupName(conversationId));
    }

    public Task<IReadOnlyCollection<int>> GetOnlineUserIds()
    {
        return Task.FromResult(_connectionManager.OnlineUserIds);
    }

    private async Task NotifyContactsAsync(int userId, string methodName)
    {
        var contactIds = await _context.Conversations
            .AsNoTracking()
            .Where(c => c.BuyerId == userId || c.SellerId == userId)
            .Select(c => c.BuyerId == userId ? c.SellerId : c.BuyerId)
            .Distinct()
            .ToListAsync();

        foreach (var contactId in contactIds)
        {
            await Clients.Group(GetUserGroupName(contactId))
                .SendAsync(methodName, new { userId });
        }
    }
}
