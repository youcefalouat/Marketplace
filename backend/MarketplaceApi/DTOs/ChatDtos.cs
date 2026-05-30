using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class ConversationDto
{
    public int Id { get; set; }
    public int AnnonceId { get; set; }
    public string AnnonceTitle { get; set; } = string.Empty;
    public string AnnonceImage { get; set; } = string.Empty;
    public decimal AnnoncePrice { get; set; }
    public string AnnonceCurrency { get; set; } = "DA";
    public int AnnonceOwnerId { get; set; }
    public int AnnonceCategoryId { get; set; }
    public string AnnonceCategoryName { get; set; } = string.Empty;
    public string AnnonceCategoryArName { get; set; } = string.Empty;
    public string AnnonceStatus { get; set; } = string.Empty;
    public int InterlocutorId { get; set; }
    public string InterlocutorName { get; set; } = string.Empty;
    public bool IsInterlocutorOnline { get; set; }
    public DateTime LastMessageAt { get; set; }
    public string LastMessageContent { get; set; } = string.Empty;
    public int? LastMessageSenderId { get; set; }
    public int UnreadCount { get; set; }
    public bool HasUnreadMessages { get; set; }
    public bool IsModeration { get; set; }
}

public class MessageDto
{
    public int Id { get; set; }
    public int ConversationId { get; set; }
    public int SenderId { get; set; }
    public int ReceiverId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsMe { get; set; }
    public string? ClientMessageId { get; set; }
}

public class SendMessageDto
{
    [Required]
    [MaxLength(4000)]
    public string Content { get; set; } = string.Empty;

    public int? AnnonceId { get; set; }

    [MaxLength(100)]
    public string? ClientMessageId { get; set; }
}

public class StartConversationDto
{
    [Required]
    public int AnnonceId { get; set; }
}

public class UnreadConversationCountDto
{
    public int ConversationId { get; set; }
    public int Count { get; set; }
}

public class UnreadSummaryDto
{
    public int TotalUnread { get; set; }
    public List<UnreadConversationCountDto> Conversations { get; set; } = new();
}

public class MessageReadReceiptDto
{
    public int ConversationId { get; set; }
    public int ReaderId { get; set; }
    public DateTime ReadAt { get; set; }
    public List<int> MessageIds { get; set; } = new();
}

public class ConversationReadResultDto
{
    public int ConversationId { get; set; }
    public DateTime? ReadAt { get; set; }
    public List<int> MessageIds { get; set; } = new();
    public UnreadSummaryDto UnreadSummary { get; set; } = new();
}
