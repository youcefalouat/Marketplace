using System.Security.Claims;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Hubs;
using MarketplaceApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace MarketplaceApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<ChatHub> _hubContext;

    public ChatController(ApplicationDbContext context, IHubContext<ChatHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    [HttpGet("conversations")]
    public async Task<ActionResult<IEnumerable<ConversationDto>>> GetConversations()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var conversations = await _context.Conversations
            .Include(c => c.Annonce)
                .ThenInclude(a => a.Images)
            .Include(c => c.Buyer)
            .Include(c => c.Seller)
            .Include(c => c.Messages)
            .Where(c => c.BuyerId == userId || c.SellerId == userId)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        var dtos = conversations.Select(c =>
        {
            var isBuyer = c.BuyerId == userId;
            var interlocutor = isBuyer ? c.Seller : c.Buyer;
            var lastMessage = c.Messages.OrderByDescending(m => m.SentAt).FirstOrDefault();
            var mainImage = c.Annonce.Images.OrderBy(i => i.DisplayOrder).FirstOrDefault();

            return new ConversationDto
            {
                Id = c.Id,
                AnnonceId = c.AnnonceId,
                AnnonceTitle = c.Annonce.Title,
                AnnonceImage = mainImage != null ? mainImage.ImagePath : string.Empty,
                InterlocutorId = interlocutor.Id,
                InterlocutorName = interlocutor.Name,
                LastMessageAt = c.LastMessageAt,
                LastMessageContent = lastMessage?.Content ?? "",
                HasUnreadMessages = c.Messages.Any(m => m.SenderId != userId && !m.IsRead)
            };
        });

        return Ok(dtos);
    }

    [HttpGet("conversations/{id}/messages")]
    public async Task<ActionResult<IEnumerable<MessageDto>>> GetMessages(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var conversation = await _context.Conversations
            .Include(c => c.Messages)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (conversation == null)
        {
            return NotFound();
        }

        if (conversation.BuyerId != userId && conversation.SellerId != userId)
        {
            return Forbid();
        }

        // Mark messages as read
        var unreadMessages = conversation.Messages
            .Where(m => m.SenderId != userId && !m.IsRead)
            .ToList();

        if (unreadMessages.Any())
        {
            foreach (var msg in unreadMessages)
            {
                msg.IsRead = true;
            }
            await _context.SaveChangesAsync();
        }

        var messages = conversation.Messages.OrderBy(m => m.SentAt).Select(m => new MessageDto
        {
            Id = m.Id,
            ConversationId = m.ConversationId,
            SenderId = m.SenderId,
            Content = m.Content,
            SentAt = m.SentAt,
            IsRead = m.IsRead,
            IsMe = m.SenderId == userId
        });

        return Ok(messages);
    }

    [HttpPost("start")]
    public async Task<ActionResult<ConversationDto>> StartConversation([FromBody] StartConversationDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        
        var annonce = await _context.Annonces
            .Include(a => a.User)
            .Include(a => a.Images)
            .FirstOrDefaultAsync(a => a.Id == dto.AnnonceId);

        if (annonce == null)
        {
            return NotFound("Annonce non trouvée");
        }

        if (annonce.UserId == userId)
        {
            return BadRequest("Vous ne pouvez pas démarrer une conversation sur votre propre annonce");
        }

        // Check if conversation already exists
        var existingConversation = await _context.Conversations
            .Include(c => c.Buyer)
            .Include(c => c.Seller)
            .Include(c => c.Annonce)
                .ThenInclude(a => a.Images)
            .Include(c => c.Messages)
            .FirstOrDefaultAsync(c => c.AnnonceId == dto.AnnonceId && c.BuyerId == userId);

        if (existingConversation != null)
        {
            var interlocutor = existingConversation.Seller;
            var lastMessage = existingConversation.Messages.OrderByDescending(m => m.SentAt).FirstOrDefault();
            var mainImage = existingConversation.Annonce.Images.OrderBy(i => i.DisplayOrder).FirstOrDefault();

            return Ok(new ConversationDto
            {
                Id = existingConversation.Id,
                AnnonceId = existingConversation.AnnonceId,
                AnnonceTitle = existingConversation.Annonce.Title,
                AnnonceImage = mainImage != null ? mainImage.ImagePath : string.Empty,
                InterlocutorId = interlocutor.Id,
                InterlocutorName = interlocutor.Name,
                LastMessageAt = existingConversation.LastMessageAt,
                LastMessageContent = lastMessage?.Content ?? "",
                HasUnreadMessages = existingConversation.Messages.Any(m => m.SenderId != userId && !m.IsRead)
            });
        }

        // Create new conversation
        var conversation = new Conversation
        {
            AnnonceId = dto.AnnonceId,
            BuyerId = userId,
            SellerId = annonce.UserId,
            StartedAt = DateTime.UtcNow,
            LastMessageAt = DateTime.UtcNow
        };

        _context.Conversations.Add(conversation);
        await _context.SaveChangesAsync();

        // Reload to get navigation properties if needed, or just construct DTO manually
        // Since we have 'annonce' and 'userId', we can construct it 
        var mainImg = annonce.Images.OrderBy(i => i.DisplayOrder).FirstOrDefault();

        return CreatedAtAction(nameof(GetMessages), new { id = conversation.Id }, new ConversationDto
        {
            Id = conversation.Id,
            AnnonceId = annonce.Id,
            AnnonceTitle = annonce.Title,
            AnnonceImage = mainImg != null ? mainImg.ImagePath : string.Empty,
            InterlocutorId = annonce.UserId,
            InterlocutorName = annonce.User.Name,
            LastMessageAt = conversation.LastMessageAt,
            LastMessageContent = "",
            HasUnreadMessages = false
        });
    }

    [HttpPost("conversations/{id}/messages")]
    public async Task<ActionResult<MessageDto>> SendMessage(int id, [FromBody] SendMessageDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var conversation = await _context.Conversations.FindAsync(id);

        if (conversation == null)
        {
            return NotFound();
        }

        if (conversation.BuyerId != userId && conversation.SellerId != userId)
        {
            return Forbid();
        }

        var message = new Message
        {
            ConversationId = id,
            SenderId = userId,
            Content = dto.Content,
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        _context.Messages.Add(message);
        conversation.LastMessageAt = message.SentAt;
        await _context.SaveChangesAsync();

        var messageDto = new MessageDto
        {
            Id = message.Id,
            ConversationId = message.ConversationId,
            SenderId = message.SenderId,
            Content = message.Content,
            SentAt = message.SentAt,
            IsRead = message.IsRead,
            IsMe = true
        };
        
        // Broadcast to SignalR group
        // Use a generic logic: The receiver is the other party.
        // We broadcast to the conversation group ID.
        await _hubContext.Clients.Group(id.ToString()).SendAsync("ReceiveMessage", messageDto);

        return Ok(messageDto);
    }
}
