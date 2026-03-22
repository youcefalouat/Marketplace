using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class CreateModerationThreadDto
{
    [Required]
    public int AnnonceId { get; set; }

    [Required]
    [MaxLength(2000)]
    public string Message { get; set; } = string.Empty;
}

public class SendModerationMessageDto
{
    [Required]
    [MaxLength(2000)]
    public string Content { get; set; } = string.Empty;
}

public class ModerationThreadSummaryDto
{
    public int Id { get; set; }
    public int AnnonceId { get; set; }
    public string AnnonceTitle { get; set; } = string.Empty;
    public string AnnonceStatus { get; set; } = string.Empty;
    public string? AnnonceMainImageUrl { get; set; }
    public DateTime LastMessageAt { get; set; }
    public string LastMessagePreview { get; set; } = string.Empty;
    public bool IsClosed { get; set; }
}

public class ModerationThreadDto
{
    public int Id { get; set; }
    public int AnnonceId { get; set; }
    public string AnnonceTitle { get; set; } = string.Empty;
    public string AnnonceStatus { get; set; } = string.Empty;
    public int OwnerId { get; set; }
    public string OwnerName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime LastMessageAt { get; set; }
    public bool IsClosed { get; set; }
    public List<ModerationMessageDto> Messages { get; set; } = new();
}

public class ModerationMessageDto
{
    public int Id { get; set; }
    public int ThreadId { get; set; }
    public int SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public bool IsFromAdmin { get; set; }
    public bool IsMe { get; set; }
}

