using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class CreateRatingDto
{
    [Required]
    public int SellerId { get; set; }
    
    [Required]
    [Range(1, 5)]
    public int Rating { get; set; }
    
    [MaxLength(500)]
    public string? Comment { get; set; }
}

public class RatingDto
{
    public int Id { get; set; }
    public int SellerId { get; set; }
    public int RaterId { get; set; }
    public string RaterName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SellerRatingSummaryDto
{
    public double AverageRating { get; set; }
    public int RatingCount { get; set; }
    public List<RatingDto> Ratings { get; set; } = new();
}
