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
    private readonly IRatingService _ratingService;
    private readonly IAnnonceFeedService _feedService;
    
    public AnnoncesController(ApplicationDbContext context, IBlobStorageService blobStorage, IRatingService ratingService, IAnnonceFeedService feedService)
    {
        _context = context;
        _blobStorage = blobStorage;
        _ratingService = ratingService;
        _feedService = feedService;
    }
    
    /// <summary>
    /// Get all approved annonces (public)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PaginatedResponse<AnnonceListDto>>> GetAnnonces([FromQuery] AnnonceFilterDto filter)
    {
        var query = _context.Annonces
            .Include(a => a.Images)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .Where(a => a.Status == AnnonceStatus.Approved)
            .AsQueryable();
        
        // Apply filters
        if (filter.CategoryId.HasValue)
        {
            // Include category and all subcategories
            var categoryIds = await GetCategoryAndSubcategoryIds(filter.CategoryId.Value);
            query = query.Where(a => categoryIds.Contains(a.CategoryId));
        }
        
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchStr = filter.Search.ToLower();
            query = query.Where(a => 
                a.Title.ToLower().Contains(searchStr) || 
                a.Description.ToLower().Contains(searchStr) ||
                a.Category.Name.ToLower().Contains(searchStr));
        }
        
        if (filter.MinPrice.HasValue)
        {
            query = query.Where(a => a.Price >= filter.MinPrice.Value);
        }
        
        if (filter.MaxPrice.HasValue)
        {
            query = query.Where(a => a.Price <= filter.MaxPrice.Value);
        }
        
        if (filter.WilayaIds != null && filter.WilayaIds.Any())
        {
            query = query.Where(a => filter.WilayaIds.Contains(a.WilayaId));
        }
        
        if (filter.CommuneIds != null && filter.CommuneIds.Any())
        {
            query = query.Where(a => filter.CommuneIds.Contains(a.CommuneId));
        }
        
        var totalCount = await query.CountAsync();
        
        var rawItems = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .Select(a => new
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                WilayaName = a.Wilaya.Name,
                CommuneName = a.Commune.Name,
                Category = a.Category.Name,
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                IsExchange = a.IsExchange,
                IsGoodDeal = a.IsGoodDeal,
                SellerId = a.UserId,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();

        var sellerSummaries = await _ratingService.GetSellerSummariesAsync(rawItems.Select(i => i.SellerId));
        var items = rawItems.Select(a =>
        {
            double? avg = null;
            int? count = null;
            if (sellerSummaries.TryGetValue(a.SellerId, out var summary) && summary.RatingCount > 0)
            {
                avg = summary.AverageRating;
                count = summary.RatingCount;
            }

            return new AnnonceListDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                WilayaName = a.WilayaName,
                CommuneName = a.CommuneName,
                Category = a.Category,
                MainImageUrl = a.MainImageUrl,
                IsExchange = a.IsExchange,
                IsGoodDeal = a.IsGoodDeal,
                SellerAverageRating = avg,
                SellerRatingCount = count,
                CreatedAt = a.CreatedAt
            };
        }).ToList();
        
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
            .Include(a => a.User).ThenInclude(u => u.Wilaya)
            .Include(a => a.User).ThenInclude(u => u.Commune)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .FirstOrDefaultAsync(a => a.Id == id && a.Status == AnnonceStatus.Approved);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        var sellerRating = await _ratingService.GetSellerSummaryAsync(annonce.UserId);
        return Ok(MapToDetailDto(annonce, sellerRating));
    }

    /// <summary>
    /// Featured/random feed for home discovery (public)
    /// </summary>
    [HttpGet("featured")]
    public async Task<ActionResult<List<AnnonceListDto>>> GetFeatured([FromQuery] int? count)
    {
        var featured = await _feedService.GetFeaturedAnnoncesAsync(count);
        return Ok(featured);
    }
    
    /// <summary>
    /// Create a new annonce (authenticated users)
    /// </summary>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<AnnonceDetailDto>> CreateAnnonce([FromForm] CreateAnnonceDto dto, [FromForm] List<IFormFile>? images)
    {
        var userId = GetCurrentUserId();
        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId);
        
        if (user == null)
        {
            return Unauthorized();
        }
        
        // Check phone verification
        if (!user.PhoneVerified)
        {
            return StatusCode(403, new { message = "Veuillez vérifier votre numéro de téléphone avant de publier une annonce", requiresPhoneVerification = true });
        }
        
        // Validate images count
        if (images != null && images.Count > 5)
        {
            return BadRequest(new { message = "Maximum 5 images autorisées" });
        }
        
        var wilayaId = dto.WilayaId ?? user.WilayaId;
        var communeId = dto.CommuneId ?? user.CommuneId;
        
        // Validate wilaya/commune if provided
        if (dto.WilayaId.HasValue || dto.CommuneId.HasValue)
        {
            var commune = await _context.Communes.FirstOrDefaultAsync(
                c => c.Id == communeId && c.WilayaId == wilayaId);
            if (commune == null)
            {
                return BadRequest(new { message = "Commune invalide pour cette wilaya" });
            }
        }
        
        var annonce = new Annonce
        {
            UserId = userId,
            Title = dto.Title,
            Description = dto.Description,
            Price = dto.Price,
            CategoryId = dto.CategoryId,
            State = dto.State,
            Phone = dto.Phone ?? user.Phone,
            WilayaId = wilayaId,
            CommuneId = communeId,
            IsExchange = dto.IsExchange,
            ShowPhone = dto.ShowPhone,
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
        
        // Reload with all navigation properties
        annonce = await _context.Annonces
            .Include(a => a.Images)
            .Include(a => a.User).ThenInclude(u => u.Wilaya)
            .Include(a => a.User).ThenInclude(u => u.Commune)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .FirstAsync(a => a.Id == annonce.Id);
        
        var sellerRating = await _ratingService.GetSellerSummaryAsync(annonce.UserId);
        return CreatedAtAction(nameof(GetAnnonce), new { id = annonce.Id }, MapToDetailDto(annonce, sellerRating));
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
            .Include(a => a.Category)
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new MyAnnonceDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                Category = a.Category.Name,
                Status = a.Status.ToString(),
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                IsGoodDeal = a.IsGoodDeal,
                ModerationThreadId = _context.Conversations
                    .Where(t => t.AnnonceId == a.Id && t.IsModeration)
                    .Select(t => (int?)t.Id)
                    .FirstOrDefault(),
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
    
    private static AnnonceDetailDto MapToDetailDto(Annonce annonce, SellerRatingAggregate? sellerRating)
    {
        double? avg = null;
        int? count = null;
        if (sellerRating != null && sellerRating.RatingCount > 0)
        {
            avg = sellerRating.AverageRating;
            count = sellerRating.RatingCount;
        }

        var dto = new AnnonceDetailDto
        {
            Id = annonce.Id,
            Title = annonce.Title,
            Description = annonce.Description,
            Price = annonce.Price,
            Category = annonce.Category.Name,
            State = annonce.State.ToString(),
            Phone = annonce.ShowPhone ? annonce.Phone : string.Empty,
            ShowPhone = annonce.ShowPhone,
            WilayaId = annonce.WilayaId,
            CommuneId = annonce.CommuneId,
            WilayaName = annonce.Wilaya.Name,
            CommuneName = annonce.Commune.Name,
            IsExchange = annonce.IsExchange,
            Status = annonce.Status.ToString(),
            IsGoodDeal = annonce.IsGoodDeal,
            CreatedAt = annonce.CreatedAt,
            ImageUrls = annonce.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).ToList(),
            Seller = new SellerInfoDto
            {
                Id = annonce.UserId,
                Name = annonce.User.Name,
                Phone = annonce.ShowPhone ? annonce.User.Phone : string.Empty,
                WilayaName = annonce.User.Wilaya.Name,
                CommuneName = annonce.User.Commune.Name,
                AverageRating = avg,
                RatingCount = count
            }
        };
        
        return dto;
    }
    
    private async Task<List<int>> GetCategoryAndSubcategoryIds(int categoryId)
    {
        var categoryIds = new List<int> { categoryId };
        
        var subcategories = await _context.Categories
            .Where(c => c.ParentId == categoryId)
            .Select(c => c.Id)
            .ToListAsync();
            
        foreach (var subId in subcategories)
        {
            categoryIds.AddRange(await GetCategoryAndSubcategoryIds(subId));
        }
        
        return categoryIds.Distinct().ToList();
    }
}
