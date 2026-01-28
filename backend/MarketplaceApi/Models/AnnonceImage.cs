using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class AnnonceImage
{
    public int Id { get; set; }
    
    [Required]
    public int AnnonceId { get; set; }
    
    [Required]
    [MaxLength(500)]
    public string ImagePath { get; set; } = string.Empty;
    
    public int DisplayOrder { get; set; } = 0;
    
    // Navigation property
    public Annonce Annonce { get; set; } = null!;
}
