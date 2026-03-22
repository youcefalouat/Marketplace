using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class ModerationThread
{
    public int Id { get; set; }

    [Required]
    public int AnnonceId { get; set; }

    [Required]
    public int OwnerId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;
    public DateTime? ClosedAt { get; set; }

    // Navigation properties
    public Annonce Annonce { get; set; } = null!;
    public User Owner { get; set; } = null!;
    public ICollection<ModerationMessage> Messages { get; set; } = new List<ModerationMessage>();
}

