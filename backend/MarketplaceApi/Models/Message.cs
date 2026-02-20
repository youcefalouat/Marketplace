using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketplaceApi.Models;

public class Message
{
    public int Id { get; set; }

    [Required]
    public int ConversationId { get; set; }

    [Required]
    public int SenderId { get; set; }

    [Required]
    public string Content { get; set; } = string.Empty;

    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public bool IsRead { get; set; } = false;

    // Navigation properties
    public Conversation Conversation { get; set; } = null!;
    
    [ForeignKey("SenderId")]
    public User Sender { get; set; } = null!;
}
