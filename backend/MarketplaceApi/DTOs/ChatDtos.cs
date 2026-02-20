using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class ConversationDto
{
    public int Id { get; set; }
    public int AnnonceId { get; set; }
    public string AnnonceTitle { get; set; } = string.Empty;
    public string AnnonceImage { get; set; } = string.Empty;
    public int InterlocutorId { get; set; }
    public string InterlocutorName { get; set; } = string.Empty;
    public DateTime LastMessageAt { get; set; }
    public string LastMessageContent { get; set; } = string.Empty;
    public bool HasUnreadMessages { get; set; }
}

public class MessageDto
{
    public int Id { get; set; }
    public int ConversationId { get; set; }
    public int SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public bool IsRead { get; set; }
    public bool IsMe { get; set; }
}

public class SendMessageDto
{
    [Required]
    public string Content { get; set; } = string.Empty;
}

public class StartConversationDto
{
    [Required]
    public int AnnonceId { get; set; }
}
