using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;
using MarketplaceApi.Services;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AnnoncesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IBlobStorageService _blobStorage;
    
    public AnnoncesController(ApplicationDbContext context, IBlobStorageService blobStorage)
    {
        _context = context;
        _blobStorage = blobStorage;
    }
    
    /// <summary>
    /// Get all approved annonces (public)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PaginatedResponse<AnnonceListDto>>> GetAnnonces([FromQuery] AnnonceFilterDto filter)
    {
        var query = _context.Annonces
            .Include(a => a.Images)
            .Where(a => a.Status == AnnonceStatus.Approved)
            .AsQueryable();
        
        // Apply filters
        if (filter.Category.HasValue)
        {
            query = query.Where(a => a.Category == filter.Category.Value);
        }
        
        if (filter.MinPrice.HasValue)
        {
            query = query.Where(a => a.Price >= filter.MinPrice.Value);
        }
        
        if (filter.MaxPrice.HasValue)
        {
            query = query.Where(a => a.Price <= filter.MaxPrice.Value);
        }
        
        if (!string.IsNullOrWhiteSpace(filter.City))
        {
            query = query.Where(a => a.City.Contains(filter.City));
        }
        
        var totalCount = await query.CountAsync();
        
        var items = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .Select(a => new AnnonceListDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                City = a.City,
                Category = a.Category.ToString(),
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
        
        return Ok(new PaginatedResponse<AnnonceListDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = filter.Page,
            PageSize = filter.PageSize
        });
    }
    
    /// <summary>
    /// Get annonce details (public - approved only)
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<AnnonceDetailDto>> GetAnnonce(int id)
    {
        var annonce = await _context.Annonces
            .Include(a => a.Images)
            .Include(a => a.User)
            .FirstOrDefaultAsync(a => a.Id == id && a.Status == AnnonceStatus.Approved);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        return Ok(MapToDetailDto(annonce));
    }
    
    /// <summary>
    /// Create a new annonce (authenticated users)
    /// </summary>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<AnnonceDetailDto>> CreateAnnonce([FromForm] CreateAnnonceDto dto, [FromForm] List<IFormFile>? images)
    {
        var userId = GetCurrentUserId();
        var user = await _context.Users.FindAsync(userId);
        
        if (user == null)
        {
            return Unauthorized();
        }
        
        // Validate images count
        if (images != null && images.Count > 5)
        {
            return BadRequest(new { message = "Maximum 5 images autorisées" });
        }
        
        var annonce = new Annonce
        {
            UserId = userId,
            Title = dto.Title,
            Description = dto.Description,
            Price = dto.Price,
            Category = dto.Category,
            State = dto.State,
            Phone = dto.Phone ?? user.Phone,
            City = dto.City ?? user.City,
            Status = AnnonceStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        
        _context.Annonces.Add(annonce);
        await _context.SaveChangesAsync();
        
        // Upload images
        if (images != null && images.Any())
        {
            var order = 0;
            foreach (var image in images)
            {
                var imageUrl = await _blobStorage.UploadImageAsync(image);
                var annonceImage = new AnnonceImage
                {
                    AnnonceId = annonce.Id,
                    ImagePath = imageUrl,
                    DisplayOrder = order++
                };
                _context.AnnonceImages.Add(annonceImage);
            }
            await _context.SaveChangesAsync();
        }
        
        // Reload with images
        annonce = await _context.Annonces
            .Include(a => a.Images)
            .Include(a => a.User)
            .FirstAsync(a => a.Id == annonce.Id);
        
        return CreatedAtAction(nameof(GetAnnonce), new { id = annonce.Id }, MapToDetailDto(annonce));
    }
    
    /// <summary>
    /// Get current user's annonces
    /// </summary>
    [HttpGet("my")]
    [Authorize]
    public async Task<ActionResult<List<MyAnnonceDto>>> GetMyAnnonces()
    {
        var userId = GetCurrentUserId();
        
        var annonces = await _context.Annonces
            .Include(a => a.Images)
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new MyAnnonceDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                Category = a.Category.ToString(),
                Status = a.Status.ToString(),
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
        
        return Ok(annonces);
    }
    
    /// <summary>
    /// Delete an annonce (owner only)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> DeleteAnnonce(int id)
    {
        var userId = GetCurrentUserId();
        
        var annonce = await _context.Annonces
            .Include(a => a.Images)
            .FirstOrDefaultAsync(a => a.Id == id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        // Check ownership (unless admin)
        var isAdmin = User.IsInRole("Admin");
        if (annonce.UserId != userId && !isAdmin)
        {
            return Forbid();
        }
        
        // Delete images from storage
        foreach (var image in annonce.Images)
        {
            await _blobStorage.DeleteImageAsync(image.ImagePath);
        }
        
        _context.Annonces.Remove(annonce);
        await _context.SaveChangesAsync();
        
        return NoContent();
    }
    
    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.Parse(userIdClaim ?? "0");
    }
    
    private static AnnonceDetailDto MapToDetailDto(Annonce annonce)
    {
        return new AnnonceDetailDto
        {
            Id = annonce.Id,
            Title = annonce.Title,
            Description = annonce.Description,
            Price = annonce.Price,
            Category = annonce.Category.ToString(),
            State = annonce.State.ToString(),
            Phone = annonce.Phone,
            City = annonce.City,
            Status = annonce.Status.ToString(),
            CreatedAt = annonce.CreatedAt,
            ImageUrls = annonce.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).ToList(),
            Seller = new SellerInfoDto
            {
                Name = annonce.User.Name,
                Phone = annonce.User.Phone,
                City = annonce.User.City
            }
        };
    }
}
