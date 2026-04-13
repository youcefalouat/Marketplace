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
    
    [MaxLength(500)]
    public string? ThumbnailSmallPath { get; set; }
    
    [MaxLength(500)]
    public string? ThumbnailMediumPath { get; set; }
    
    public int DisplayOrder { get; set; } = 0;
    
    // Navigation property
    public Annonce Annonce { get; set; } = null!;
}

