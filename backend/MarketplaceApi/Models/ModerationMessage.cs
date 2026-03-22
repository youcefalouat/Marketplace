using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class ModerationMessage
{
    public int Id { get; set; }

    [Required]
    public int ThreadId { get; set; }

    [Required]
    public int SenderId { get; set; }

    [Required]
    [MaxLength(2000)]
    public string Content { get; set; } = string.Empty;

    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public bool IsFromAdmin { get; set; }

    // Navigation properties
    public ModerationThread Thread { get; set; } = null!;
    public User Sender { get; set; } = null!;
}

