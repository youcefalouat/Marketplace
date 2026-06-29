using System.Data;
using System.Security.Claims;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Hubs;
using MarketplaceApi.Models;
using MarketplaceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

// PaginatedResponse<T> is defined in AnnonceDtos.cs (same DTOs namespace)

namespace MarketplaceApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private const string DefaultCurrency = "DA";
    private const int DefaultPageSize = 50;
    private const int MaxPageSize = 100;
    private static readonly TimeSpan HubSideEffectTimeout = TimeSpan.FromSeconds(3);

    private readonly ApplicationDbContext _context;
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly INotificationService _notificationService;
    private readonly ChatConnectionManager _connectionManager;
    private readonly ILogger<ChatController> _logger;

    public ChatController(
        ApplicationDbContext context,
        IHubContext<ChatHub> hubContext,
        INotificationService notificationService,
        ChatConnectionManager connectionManager,
        ILogger<ChatController> logger)
    {
        _context = context;
        _hubContext = hubContext;
        _notificationService = notificationService;
        _connectionManager = connectionManager;
        _logger = logger;
    }

    [HttpGet("conversations")]
    public async Task<ActionResult<PaginatedResponse<ConversationDto>>> GetConversations(
        [FromQuery] int? annonceId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        pageSize = Math.Clamp(pageSize, 1, 100);
        page = Math.Max(page, 1);

        var query = BuildConversationDtoQuery(userId.Value);

        if (annonceId.HasValue)
        {
            query = query.Where(c => c.AnnonceId == annonceId.Value);
        }

        query = query.OrderByDescending(c => c.LastMessageAt);

        var totalCount = await query.CountAsync(cancellationToken);

        var conversations = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        ApplyOnlineFlags(conversations);

        return Ok(new PaginatedResponse<ConversationDto>
        {
            Items = conversations,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<UnreadSummaryDto>> GetUnreadCount(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        return Ok(await BuildUnreadSummaryAsync(userId.Value, cancellationToken));
    }

    [HttpGet("conversations/unread-counts")]
    public async Task<ActionResult<IEnumerable<UnreadConversationCountDto>>> GetUnreadCountPerConversation(
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var summary = await BuildUnreadSummaryAsync(userId.Value, cancellationToken);
        return Ok(summary.Conversations);
    }

    [HttpGet("conversations/{id:int}/messages")]
    public async Task<ActionResult<IEnumerable<MessageDto>>> GetMessages(
        int id,
        [FromQuery] int? beforeMessageId,
        [FromQuery] int pageSize = DefaultPageSize,
        CancellationToken cancellationToken = default)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var participant = await GetConversationParticipantAsync(id, cancellationToken);
        if (participant == null) return NotFound();
        if (!participant.Contains(userId.Value)) return Forbid();

        pageSize = Math.Clamp(pageSize, 1, MaxPageSize);

        var query = _context.Messages
            .AsNoTracking()
            .Where(m => m.ConversationId == id);

        if (beforeMessageId.HasValue)
        {
            query = query.Where(m => m.Id < beforeMessageId.Value);
        }

        var messages = await query
            .OrderByDescending(m => m.Id)
            .Take(pageSize)
            .Select(m => new MessageDto
            {
                Id = m.Id,
                ConversationId = m.ConversationId,
                SenderId = m.SenderId,
                ReceiverId = m.ReceiverId,
                Content = m.Content,
                SentAt = m.SentAt,
                IsRead = m.IsRead,
                ReadAt = m.ReadAt,
                IsMe = m.SenderId == userId.Value
            })
            .ToListAsync(cancellationToken);

        messages.Reverse();

        await MarkConversationAsReadInternalAsync(participant, userId.Value, cancellationToken);

        return Ok(messages);
    }

    [HttpPost("conversations/{id:int}/read")]
    public async Task<ActionResult<ConversationReadResultDto>> MarkConversationAsRead(
        int id,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var participant = await GetConversationParticipantAsync(id, cancellationToken);
        if (participant == null) return NotFound();
        if (!participant.Contains(userId.Value)) return Forbid();

        return Ok(await MarkConversationAsReadInternalAsync(participant, userId.Value, cancellationToken));
    }

    [HttpPost("start")]
    public async Task<ActionResult<ConversationDto>> StartConversation(
        [FromBody] StartConversationDto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var existingConversationId = await _context.Conversations
            .AsNoTracking()
            .Where(c => c.AnnonceId == dto.AnnonceId && c.BuyerId == userId.Value && !c.IsModeration)
            .Select(c => (int?)c.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (existingConversationId.HasValue)
        {
            var existingConversation = await BuildConversationDtoQuery(userId.Value)
                .FirstAsync(c => c.Id == existingConversationId.Value, cancellationToken);
            ApplyOnlineFlags(existingConversation);
            return Ok(existingConversation);
        }

        var annonce = await _context.Annonces
            .AsNoTracking()
            .Where(a => a.Id == dto.AnnonceId)
            .Select(a => new
            {
                a.Id,
                a.Title,
                a.Price,
                a.CategoryId,
                CategoryName = a.Category.Name,
                CategoryArName = a.Category.ArName,
                Status = a.Status.ToString(),
                OwnerId = a.UserId,
                OwnerName = a.User.Name,
                Image = a.Images
                    .OrderBy(i => i.DisplayOrder)
                    .Select(i => i.ThumbnailMediumPath ?? i.ImagePath)
                    .FirstOrDefault()
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (annonce == null)
        {
            return NotFound(new { message = "Annonce non trouvee" });
        }

        if (annonce.OwnerId == userId.Value)
        {
            return BadRequest(new { message = "Vous ne pouvez pas demarrer une conversation sur votre propre annonce" });
        }

        var pendingConversation = new ConversationDto
        {
            Id = 0,
            AnnonceId = annonce.Id,
            AnnonceTitle = annonce.Title,
            AnnonceImage = annonce.Image ?? string.Empty,
            AnnoncePrice = annonce.Price,
            AnnonceCurrency = DefaultCurrency,
            AnnonceOwnerId = annonce.OwnerId,
            AnnonceCategoryId = annonce.CategoryId,
            AnnonceCategoryName = annonce.CategoryName,
            AnnonceCategoryArName = annonce.CategoryArName,
            AnnonceStatus = annonce.Status,
            InterlocutorId = annonce.OwnerId,
            InterlocutorName = annonce.OwnerName,
            IsInterlocutorOnline = _connectionManager.IsUserOnline(annonce.OwnerId),
            LastMessageAt = DateTime.UtcNow,
            LastMessageContent = string.Empty,
            LastMessageSenderId = null,
            UnreadCount = 0,
            HasUnreadMessages = false,
            IsModeration = false
        };

        return Ok(pendingConversation);
    }

    [HttpPost("conversations/{id:int}/messages")]
    public async Task<ActionResult<MessageDto>> SendMessage(
        int id,
        [FromBody] SendMessageDto dto,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var content = dto.Content.Trim();
        if (string.IsNullOrWhiteSpace(content))
            return BadRequest(new { message = "Le message est vide" });

        // ── Validation reads — AsNoTracking, outside the retry strategy ──────
        // Keeps the Serializable lock window as short as possible.
        if (id > 0)
        {
            var conv = await _context.Conversations
                .AsNoTracking()
                .Where(c => c.Id == id)
                .Select(c => new { c.BuyerId, c.SellerId })
                .FirstOrDefaultAsync(cancellationToken);

            if (conv == null) return NotFound(new { message = "Conversation introuvable" });
            if (conv.BuyerId != userId.Value && conv.SellerId != userId.Value) return Forbid();
        }
        else
        {
            if (!dto.AnnonceId.HasValue)
                return BadRequest(new { message = "annonceId est requis pour creer une conversation" });

            var annonce = await _context.Annonces
                .AsNoTracking()
                .Where(a => a.Id == dto.AnnonceId.Value)
                .Select(a => new { a.Id, a.UserId })
                .FirstOrDefaultAsync(cancellationToken);

            if (annonce == null) return NotFound(new { message = "Annonce non trouvee" });
            if (annonce.UserId == userId.Value)
                return BadRequest(new { message = "Vous ne pouvez pas demarrer une conversation sur votre propre annonce" });
        }

        // ── Transactional writes — wrapped in the execution strategy ─────────
        // SqlServerRetryingExecutionStrategy (configured via EnableRetryOnFailure)
        // forbids direct BeginTransactionAsync calls. The strategy must own the
        // retry loop so it can restart the entire transaction on a transient fault.
        Message? savedMessage = null;
        Conversation? savedConversation = null;

        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            // Clear tracker so that a retry starts from a clean state and does
            // not re-insert partially-tracked entities from the previous attempt.
            _context.ChangeTracker.Clear();

            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable, cancellationToken);

            Conversation? conversation = null;

            if (id > 0)
            {
                conversation = await _context.Conversations
                    .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
            }
            else
            {
                var annonce = await _context.Annonces
                    .AsNoTracking()
                    .Where(a => a.Id == dto.AnnonceId!.Value)
                    .Select(a => new { a.Id, a.UserId })
                    .FirstOrDefaultAsync(cancellationToken);

                conversation = await _context.Conversations
                    .FirstOrDefaultAsync(
                        c => c.AnnonceId == annonce!.Id && c.BuyerId == userId.Value && !c.IsModeration,
                        cancellationToken);

                if (conversation == null)
                {
                    conversation = new Conversation
                    {
                        AnnonceId = annonce!.Id,
                        BuyerId = userId.Value,
                        SellerId = annonce.UserId,
                        StartedAt = DateTime.UtcNow,
                        LastMessageAt = DateTime.UtcNow,
                        IsModeration = false
                    };
                    _context.Conversations.Add(conversation);
                    await _context.SaveChangesAsync(cancellationToken);
                }
            }

            var receiverId = conversation!.BuyerId == userId.Value
                ? conversation.SellerId
                : conversation.BuyerId;

            var now = DateTime.UtcNow;
            var msg = new Message
            {
                ConversationId = conversation.Id,
                SenderId = userId.Value,
                ReceiverId = receiverId,
                Content = content,
                SentAt = now,
                IsRead = false,
                ReadAt = null
            };

            _context.Messages.Add(msg);
            conversation.LastMessageAt = now;

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            savedMessage = msg;
            savedConversation = conversation;
        });

        // ── Post-transaction side-effects (SignalR + push notifications) ──────
        var senderMessageDto = MapMessageDto(savedMessage!, userId.Value, dto.ClientMessageId);

        await PushMessageAndConversationUpdatesAsync(
            savedConversation!,
            savedMessage!,
            dto.ClientMessageId,
            cancellationToken);

        var senderName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Un utilisateur";
        await _notificationService.SendMessageNotificationAsync(
            savedMessage!.ReceiverId,
            MapMessageDto(savedMessage, savedMessage.ReceiverId, dto.ClientMessageId),
            senderName,
            cancellationToken);

        return Ok(senderMessageDto);
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }

    private IQueryable<ConversationDto> BuildConversationDtoQuery(int userId)
    {
        return _context.Conversations
            .AsNoTracking()
            .Where(c => c.BuyerId == userId || c.SellerId == userId)
            .Select(c => new ConversationDto
            {
                Id = c.Id,
                AnnonceId = c.AnnonceId,
                AnnonceTitle = c.Annonce.Title,
                AnnonceImage = c.Annonce.Images
                    .OrderBy(i => i.DisplayOrder)
                    .Select(i => i.ThumbnailMediumPath ?? i.ImagePath)
                    .FirstOrDefault() ?? string.Empty,
                AnnoncePrice = c.Annonce.Price,
                AnnonceCurrency = DefaultCurrency,
                AnnonceOwnerId = c.Annonce.UserId,
                AnnonceCategoryId = c.Annonce.CategoryId,
                AnnonceCategoryName = c.Annonce.Category.Name,
                AnnonceCategoryArName = c.Annonce.Category.ArName,
                AnnonceStatus = c.Annonce.Status.ToString(),
                InterlocutorId = c.BuyerId == userId ? c.Seller.Id : c.Buyer.Id,
                InterlocutorName = c.BuyerId == userId ? c.Seller.Name : c.Buyer.Name,
                LastMessageAt = c.LastMessageAt,
                LastMessageContent = c.Messages
                    .OrderByDescending(m => m.Id)
                    .Select(m => m.Content)
                    .FirstOrDefault() ?? string.Empty,
                LastMessageSenderId = c.Messages
                    .OrderByDescending(m => m.Id)
                    .Select(m => (int?)m.SenderId)
                    .FirstOrDefault(),
                UnreadCount = c.Messages.Count(m => m.ReceiverId == userId && !m.IsRead),
                HasUnreadMessages = c.Messages.Any(m => m.ReceiverId == userId && !m.IsRead),
                IsModeration = c.IsModeration
            });
    }

    private async Task<ConversationParticipantInfo?> GetConversationParticipantAsync(
        int conversationId,
        CancellationToken cancellationToken)
    {
        return await _context.Conversations
            .AsNoTracking()
            .Where(c => c.Id == conversationId)
            .Select(c => new ConversationParticipantInfo(c.Id, c.BuyerId, c.SellerId))
            .FirstOrDefaultAsync(cancellationToken);
    }

    private async Task<UnreadSummaryDto> BuildUnreadSummaryAsync(int userId, CancellationToken cancellationToken)
    {
        var conversations = await _context.Messages
            .AsNoTracking()
            .Where(m => m.ReceiverId == userId && !m.IsRead)
            .GroupBy(m => m.ConversationId)
            .Select(g => new UnreadConversationCountDto
            {
                ConversationId = g.Key,
                Count = g.Count()
            })
            .ToListAsync(cancellationToken);

        return new UnreadSummaryDto
        {
            TotalUnread = conversations.Sum(c => c.Count),
            Conversations = conversations
        };
    }

    private async Task<ConversationReadResultDto> MarkConversationAsReadInternalAsync(
        ConversationParticipantInfo participant,
        int userId,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var unreadMessages = await _context.Messages
            .Where(m => m.ConversationId == participant.Id && m.ReceiverId == userId && !m.IsRead)
            .OrderBy(m => m.Id)
            .ToListAsync(cancellationToken);

        foreach (var message in unreadMessages)
        {
            message.IsRead = true;
            message.ReadAt = now;
        }

        if (unreadMessages.Count > 0)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }

        var messageIds = unreadMessages.Select(m => m.Id).ToList();
        var otherParticipantId = participant.OtherParticipant(userId);
        var summary = await BuildUnreadSummaryAsync(userId, cancellationToken);

        if (messageIds.Count > 0)
        {
            var receipt = new MessageReadReceiptDto
            {
                ConversationId = participant.Id,
                ReaderId = userId,
                ReadAt = now,
                MessageIds = messageIds
            };

            var currentUserConversation =
                await BuildConversationDtoAsync(participant.Id, userId, cancellationToken);
            var otherParticipantConversation =
                await BuildConversationDtoAsync(participant.Id, otherParticipantId, cancellationToken);

            QueueHubSend(
                ChatHub.GetUserGroupName(userId),
                "MessagesRead",
                receipt,
                participant.Id);
            QueueHubSend(
                ChatHub.GetUserGroupName(otherParticipantId),
                "MessagesRead",
                receipt,
                participant.Id);

            if (currentUserConversation != null)
            {
                QueueHubSend(
                    ChatHub.GetUserGroupName(userId),
                    "ConversationUpdated",
                    currentUserConversation,
                    participant.Id);
            }

            if (otherParticipantConversation != null)
            {
                QueueHubSend(
                    ChatHub.GetUserGroupName(otherParticipantId),
                    "ConversationUpdated",
                    otherParticipantConversation,
                    participant.Id);
            }
        }

        QueueHubSend(
            ChatHub.GetUserGroupName(userId),
            "UnreadCountUpdated",
            summary,
            participant.Id);

        return new ConversationReadResultDto
        {
            ConversationId = participant.Id,
            ReadAt = messageIds.Count > 0 ? now : null,
            MessageIds = messageIds,
            UnreadSummary = summary
        };
    }

    private async Task PushMessageAndConversationUpdatesAsync(
        Conversation conversation,
        Message message,
        string? clientMessageId,
        CancellationToken cancellationToken)
    {
        var senderDto = MapMessageDto(message, message.SenderId, clientMessageId);
        var receiverDto = MapMessageDto(message, message.ReceiverId, clientMessageId);

        await _hubContext.Clients.Group(ChatHub.GetUserGroupName(message.SenderId))
            .SendAsync("ReceiveMessage", senderDto, cancellationToken);
        await _hubContext.Clients.Group(ChatHub.GetUserGroupName(message.ReceiverId))
            .SendAsync("ReceiveMessage", receiverDto, cancellationToken);

        await PushConversationUpdatedAsync(conversation.Id, conversation.BuyerId, cancellationToken);
        await PushConversationUpdatedAsync(conversation.Id, conversation.SellerId, cancellationToken);
        await PushUnreadSummaryAsync(conversation.BuyerId, cancellationToken);
        await PushUnreadSummaryAsync(conversation.SellerId, cancellationToken);
    }

    private async Task PushConversationUpdatedAsync(
        int conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        var conversation = await BuildConversationDtoAsync(conversationId, userId, cancellationToken);
        if (conversation == null) return;

        await _hubContext.Clients.Group(ChatHub.GetUserGroupName(userId))
            .SendAsync("ConversationUpdated", conversation, cancellationToken);
    }

    private async Task<ConversationDto?> BuildConversationDtoAsync(
        int conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        var conversation = await BuildConversationDtoQuery(userId)
            .FirstOrDefaultAsync(c => c.Id == conversationId, cancellationToken);

        if (conversation != null)
        {
            ApplyOnlineFlags(conversation);
        }

        return conversation;
    }

    private void QueueHubSend(
        string groupName,
        string methodName,
        object payload,
        int conversationId)
    {
        _ = SendHubUpdateSafelyAsync(groupName, methodName, payload, conversationId);
    }

    private async Task SendHubUpdateSafelyAsync(
        string groupName,
        string methodName,
        object payload,
        int conversationId)
    {
        using var timeout = new CancellationTokenSource(HubSideEffectTimeout);

        try
        {
            await _hubContext.Clients.Group(groupName)
                .SendAsync(methodName, payload, timeout.Token);
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning(
                ex,
                "Timed out sending chat hub update {MethodName} for conversation {ConversationId}",
                methodName,
                conversationId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to send chat hub update {MethodName} for conversation {ConversationId}",
                methodName,
                conversationId);
        }
    }

    private async Task PushUnreadSummaryAsync(int userId, CancellationToken cancellationToken)
    {
        var summary = await BuildUnreadSummaryAsync(userId, cancellationToken);
        await _hubContext.Clients.Group(ChatHub.GetUserGroupName(userId))
            .SendAsync("UnreadCountUpdated", summary, cancellationToken);
    }

    private void ApplyOnlineFlags(IEnumerable<ConversationDto> conversations)
    {
        foreach (var conversation in conversations)
        {
            ApplyOnlineFlags(conversation);
        }
    }

    private void ApplyOnlineFlags(ConversationDto conversation)
    {
        conversation.IsInterlocutorOnline = _connectionManager.IsUserOnline(conversation.InterlocutorId);
    }

    private static MessageDto MapMessageDto(Message message, int currentUserId, string? clientMessageId = null)
    {
        return new MessageDto
        {
            Id = message.Id,
            ConversationId = message.ConversationId,
            SenderId = message.SenderId,
            ReceiverId = message.ReceiverId,
            Content = message.Content,
            SentAt = message.SentAt,
            IsRead = message.IsRead,
            ReadAt = message.ReadAt,
            IsMe = message.SenderId == currentUserId,
            ClientMessageId = clientMessageId
        };
    }

    private sealed record ConversationParticipantInfo(int Id, int BuyerId, int SellerId)
    {
        public bool Contains(int userId) => BuyerId == userId || SellerId == userId;

        public int OtherParticipant(int userId) => BuyerId == userId ? SellerId : BuyerId;
    }
}
