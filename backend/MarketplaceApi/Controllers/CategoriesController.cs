using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CategoriesController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all categories as a hierarchical tree
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<CategoryDto>>> GetCategories()
    {
        return Ok(await BuildCategoryHierarchyAsync());
    }

    /// <summary>
    /// Get all categories as a hierarchical tree with children nodes
    /// </summary>
    [HttpGet("hierarchy")]
    public async Task<ActionResult<List<CategoryDto>>> GetCategoryHierarchy()
    {
        return Ok(await BuildCategoryHierarchyAsync());
    }

    private async Task<List<CategoryDto>> BuildCategoryHierarchyAsync()
    {
        var allCategories = await _context.Categories
            .AsNoTracking()
            .OrderBy(c => c.Name)
            .ToListAsync();
        
        var rootCategories = allCategories.Where(c => c.ParentId == null).ToList();
        return rootCategories.Select(c => MapToDto(c, allCategories)).ToList();
    }

    /// <summary>
    /// Get a specific category
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<CategoryDto>> GetCategory(int id)
    {
        var category = await _context.Categories.FindAsync(id);

        if (category == null)
        {
            return NotFound();
        }

        var allCategories = await _context.Categories.ToListAsync();
        return Ok(MapToDto(category, allCategories));
    }

    /// <summary>
    /// Create a new category (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CategoryDto>> CreateCategory([FromBody] CreateCategoryDto dto)
    {
        if (await _context.Categories.AnyAsync(c => c.Slug == dto.Slug))
        {
            return BadRequest(new { message = "Le slug existe déjà" });
        }

        if (dto.ParentId.HasValue)
        {
            var parentExists = await _context.Categories.AnyAsync(c => c.Id == dto.ParentId.Value);
            if (!parentExists)
            {
                return BadRequest(new { message = "La catégorie parente n'existe pas" });
            }
        }

        var category = new Category
        {
            Name = dto.Name,
            ArName = dto.ArName,
            Slug = dto.Slug,
            ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim(),
            ParentId = dto.ParentId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, MapToDto(category, new List<Category> { category }));
    }

    /// <summary>
    /// Update a category (Admin only)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateCategory(int id, [FromBody] UpdateCategoryDto dto)
    {
        var category = await _context.Categories.FindAsync(id);

        if (category == null)
        {
            return NotFound();
        }

        if (await _context.Categories.AnyAsync(c => c.Slug == dto.Slug && c.Id != id))
        {
            return BadRequest(new { message = "Le slug existe déjà" });
        }

        if (dto.ParentId.HasValue)
        {
            if (dto.ParentId.Value == id)
            {
                return BadRequest(new { message = "Une catégorie ne peut pas être son propre parent" });
            }

            var parentExists = await _context.Categories.AnyAsync(c => c.Id == dto.ParentId.Value);
            if (!parentExists)
            {
                return BadRequest(new { message = "La catégorie parente n'existe pas" });
            }
            
            // Note: In a complete implementation, you'd also want to prevent circular dependencies
        }

        category.Name = dto.Name;
        category.ArName = dto.ArName;
        category.Slug = dto.Slug;
        category.ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim();
        category.ParentId = dto.ParentId;
        category.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Delete a category (Admin only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        var category = await _context.Categories
            .Include(c => c.SubCategories)
            .Include(c => c.Annonces)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (category == null)
        {
            return NotFound();
        }

        if (category.SubCategories.Any())
        {
            return BadRequest(new { message = "Impossible de supprimer une catégorie qui contient des sous-catégories" });
        }

        if (category.Annonces.Any())
        {
            return BadRequest(new { message = "Impossible de supprimer une catégorie qui contient des annonces" });
        }

        _context.Categories.Remove(category);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private CategoryDto MapToDto(Category category, List<Category> allCategories)
    {
        var dto = new CategoryDto
        {
            Id = category.Id,
            Name = category.Name,
            ArName = category.ArName,
            Slug = category.Slug,
            ImageUrl = category.ImageUrl,
            ParentId = category.ParentId,
            Children = allCategories
                .Where(c => c.ParentId == category.Id)
                .OrderBy(c => c.Name)
                .Select(c => MapToDto(c, allCategories))
                .ToList()
        };
        
        return dto;
    }
}
