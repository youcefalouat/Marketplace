using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketplaceApi.Models;

public class UserRating
{
    public int Id { get; set; }
    
    [Required]
    public int SellerId { get; set; }
    
    [Required]
    public int RaterId { get; set; }
    
    [Required]
    [Range(1, 5)]
    public int Rating { get; set; }
    
    [MaxLength(500)]
    public string? Comment { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    [ForeignKey("SellerId")]
    public User Seller { get; set; } = null!;
    
    [ForeignKey("RaterId")]
    public User Rater { get; set; } = null!;
}
