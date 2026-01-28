using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class AdminNote
{
    public int Id { get; set; }
    
    [Required]
    public int AnnonceId { get; set; }
    
    [Required]
    public int AdminId { get; set; }
    
    [Required]
    [MaxLength(1000)]
    public string Note { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public Annonce Annonce { get; set; } = null!;
    public User Admin { get; set; } = null!;
}
