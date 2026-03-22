using System.ComponentModel.DataAnnotations;
using MarketplaceApi.Models;

namespace MarketplaceApi.DTOs;

// Request DTOs
public class CreateAnnonceDto
{
    [Required]
    public int CategoryId { get; set; }
    
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
    
    public int? WilayaId { get; set; }
    
    public int? CommuneId { get; set; }
    
    public bool IsExchange { get; set; } = false;
    
    public bool ShowPhone { get; set; } = true;
}

// Response DTOs
public class AnnonceListDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string WilayaName { get; set; } = string.Empty;
    public string CommuneName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? MainImageUrl { get; set; }
    public bool IsExchange { get; set; }
    public bool IsGoodDeal { get; set; }
    public double? SellerAverageRating { get; set; }
    public int? SellerRatingCount { get; set; }
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
    public bool ShowPhone { get; set; }
    public int WilayaId { get; set; }
    public int CommuneId { get; set; }
    public string WilayaName { get; set; } = string.Empty;
    public string CommuneName { get; set; } = string.Empty;
    public bool IsExchange { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool IsGoodDeal { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<string> ImageUrls { get; set; } = new();
    public SellerInfoDto Seller { get; set; } = null!;
}

public class SellerInfoDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string WilayaName { get; set; } = string.Empty;
    public string CommuneName { get; set; } = string.Empty;
    public double? AverageRating { get; set; }
    public int? RatingCount { get; set; }
}

public class MyAnnonceDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? MainImageUrl { get; set; }
    public bool IsGoodDeal { get; set; }
    public int? ModerationThreadId { get; set; }
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
    public int? CategoryId { get; set; }
    public string? Search { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public List<int>? WilayaIds { get; set; }
    public List<int>? CommuneIds { get; set; }
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

// Location DTOs
public class WilayaDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string ArName { get; set; } = string.Empty;
}

public class CommuneDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ArName { get; set; } = string.Empty;
    public int WilayaId { get; set; }
}
