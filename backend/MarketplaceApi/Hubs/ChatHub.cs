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

    public ChatHub(ApplicationDbContext context)
    {
        _context = context;
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

        await Groups.AddToGroupAsync(Context.ConnectionId, conversationId.ToString());
    }

    public async Task LeaveConversation(int conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, conversationId.ToString());
    }
}
