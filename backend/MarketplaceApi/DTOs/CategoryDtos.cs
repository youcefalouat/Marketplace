using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class CategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ArName { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int? ParentId { get; set; }
    public List<CategoryDto> Children { get; set; } = new();

    public List<CategoryDto> SubCategories
    {
        get => Children;
        set => Children = value ?? new();
    }
}

public class CreateCategoryDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(255)]
    public string ArName { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Slug { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? ImageUrl { get; set; }
    
    public int? ParentId { get; set; }
}

public class UpdateCategoryDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(255)]
    public string ArName { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Slug { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? ImageUrl { get; set; }
    
    public int? ParentId { get; set; }
}
