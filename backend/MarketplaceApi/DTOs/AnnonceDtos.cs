using System.ComponentModel.DataAnnotations;
using MarketplaceApi.Models;

namespace MarketplaceApi.DTOs;

// Request DTOs
public class CreateAnnonceDto
{
    [Required]
    public Category Category { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }
    
    [Required]
    public ProductState State { get; set; }
    
    [Phone]
    public string? Phone { get; set; }
    
    [MaxLength(100)]
    public string? City { get; set; }
}

// Response DTOs
public class AnnonceListDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string City { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? MainImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class AnnonceDetailDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public List<string> ImageUrls { get; set; } = new();
    public SellerInfoDto Seller { get; set; } = null!;
}

public class SellerInfoDto
{
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
}

public class MyAnnonceDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? MainImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Admin DTOs
public class AdminAnnonceListDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string SellerName { get; set; } = string.Empty;
    public string SellerPhone { get; set; } = string.Empty;
    public bool IsGoodDeal { get; set; }
    public decimal? StorePriceEstimate { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class AdminAnnonceDetailDto : AnnonceDetailDto
{
    public bool IsGoodDeal { get; set; }
    public decimal? StorePriceEstimate { get; set; }
    public List<AdminNoteDto> AdminNotes { get; set; } = new();
}

public class AdminNoteDto
{
    public int Id { get; set; }
    public string Note { get; set; } = string.Empty;
    public string AdminName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AddAdminNoteDto
{
    [Required]
    [MaxLength(1000)]
    public string Note { get; set; } = string.Empty;
}

public class UpdateStoreEstimateDto
{
    public decimal? StorePriceEstimate { get; set; }
    public bool IsGoodDeal { get; set; }
}

// Filter DTOs
public class AnnonceFilterDto
{
    public Category? Category { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? City { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class PaginatedResponse<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
}
