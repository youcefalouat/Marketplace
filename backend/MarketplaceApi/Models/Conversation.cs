using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketplaceApi.Models;

public class Conversation
{
    public int Id { get; set; }

    [Required]
    public int AnnonceId { get; set; }

    [Required]
    public int BuyerId { get; set; }

    [Required]
    public int SellerId { get; set; }

    public DateTime StartedAt { get; set; } = DateTime.UtcNow;

    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

    public bool IsModeration { get; set; } = false;

    // Navigation properties
    public Annonce Annonce { get; set; } = null!;
    
    [ForeignKey("BuyerId")]
    public User Buyer { get; set; } = null!;
    
    [ForeignKey("SellerId")]
    public User Seller { get; set; } = null!;

    public ICollection<Message> Messages { get; set; } = new List<Message>();
}
