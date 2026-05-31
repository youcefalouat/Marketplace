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
    private readonly IImageProcessingService _imageProcessing;
    private readonly IRatingService _ratingService;
    private readonly IAnnonceFeedService _feedService;
    private readonly ILogger<AnnoncesController> _logger;
    
    public AnnoncesController(
        ApplicationDbContext context,
        IBlobStorageService blobStorage,
        IImageProcessingService imageProcessing,
        IRatingService ratingService,
        IAnnonceFeedService feedService,
        ILogger<AnnoncesController> logger)
    {
        _context = context;
        _blobStorage = blobStorage;
        _imageProcessing = imageProcessing;
        _ratingService = ratingService;
        _feedService = feedService;
        _logger = logger;
    }
    
    /// <summary>
    /// Get all approved annonces (public)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PaginatedResponse<AnnonceListDto>>> GetAnnonces([FromQuery] AnnonceFilterDto filter)
    {
        // Fix #13: Clamp PageSize to prevent data dump
        filter.PageSize = Math.Clamp(filter.PageSize, 1, 100);
        filter.Page = Math.Max(filter.Page, 1);

        // Fix #18: Add AsNoTracking for read-only listing query
        var query = _context.Annonces
            .AsNoTracking()
            .Include(a => a.Images)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .Where(a => a.Status == AnnonceStatus.Approved)
            .AsQueryable();
        
        // Apply filters
        if (filter.CategoryId.HasValue)
        {
            // Fix #15: Load all categories in one query and traverse in-memory
            var categoryIds = await GetCategoryAndSubcategoryIds(filter.CategoryId.Value);
            query = query.Where(a => categoryIds.Contains(a.CategoryId));
        }
        
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var searchStr = filter.Search.ToLower();
            query = query.Where(a => 
                a.Title.ToLower().Contains(searchStr) || 
                a.Description.ToLower().Contains(searchStr) ||
                a.Category.Name.ToLower().Contains(searchStr) ||
                a.Category.ArName.ToLower().Contains(searchStr));
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
                CategoryId = a.CategoryId,
                CategoryName = a.Category.Name,
                CategoryArName = a.Category.ArName,
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                MainThumbnailUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ThumbnailMediumPath).FirstOrDefault(),
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
                CategoryId = a.CategoryId,
                Category = a.CategoryName,
                CategoryName = a.CategoryName,
                CategoryArName = a.CategoryArName,
                MainImageUrl = a.MainImageUrl,
                MainThumbnailUrl = a.MainThumbnailUrl,
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
        _logger.LogInformation("GetAnnonce requested for ID {AnnonceId}", id);

        // First check if the annonce exists at all
        var annonceExists = await _context.Annonces.AnyAsync(a => a.Id == id);
        if (!annonceExists)
        {
            _logger.LogWarning("Annonce {AnnonceId} does not exist in database", id);
            return NotFound(new { message = "Cette annonce n'existe pas." });
        }

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
            // Annonce exists but is not approved
            var status = await _context.Annonces
                .Where(a => a.Id == id)
                .Select(a => a.Status)
                .FirstAsync();
            _logger.LogInformation("Annonce {AnnonceId} exists but has status {Status}", id, status);
            return NotFound(new { message = "Cette annonce a été supprimée ou n'est plus disponible.", status = status.ToString() });
        }
        
        var sellerRating = await _ratingService.GetSellerSummaryAsync(annonce.UserId);
        _logger.LogInformation("Returning annonce detail for ID {AnnonceId}", id);
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
        if (userId == null) return Unauthorized();

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId.Value);
        
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

        var selectedCategory = await _context.Categories
            .AsNoTracking()
            .Where(c => c.Id == dto.CategoryId)
            .Select(c => new { c.Id, c.ParentId })
            .FirstOrDefaultAsync();
        if (selectedCategory == null)
        {
            return BadRequest(new { message = "Catégorie invalide" });
        }

        if (dto.ParentCategoryId.HasValue &&
            selectedCategory.ParentId != dto.ParentCategoryId.Value)
        {
            return BadRequest(new { message = "La catégorie parente ne correspond pas à la catégorie sélectionnée" });
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
            UserId = userId.Value,
            Title = dto.Title,
            Description = dto.Description,
            Price = dto.Price,
            CategoryId = dto.CategoryId,
            State = dto.State,
            Phone = dto.Phone ?? user.Phone,
            WilayaId = wilayaId,
            CommuneId = communeId,
            ReservationEnabled = dto.ReservationEnabled,
            IsExchange = dto.ReservationEnabled ? false : dto.IsExchange,
            ShowPhone = dto.ReservationEnabled ? false : dto.ShowPhone,
            Status = AnnonceStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        
        _context.Annonces.Add(annonce);
        await _context.SaveChangesAsync();
        
        // Process and upload images
        if (images != null && images.Any())
        {
            var order = 0;
            var storedImages = new List<AnnonceImage>(); // Fix #3: Track stored images for cleanup
            foreach (var image in images)
            {
                try
                {
                    using var processingResult = await _imageProcessing.ProcessImageAsync(image);
                    var storageResult = await _blobStorage.StoreProcessedImageAsync(processingResult);
                    
                    var annonceImage = new AnnonceImage
                    {
                        AnnonceId = annonce.Id,
                        ImagePath = storageResult.ImagePath,
                        ThumbnailSmallPath = storageResult.ThumbnailSmallPath,
                        ThumbnailMediumPath = storageResult.ThumbnailMediumPath,
                        DisplayOrder = order++
                    };
                    _context.AnnonceImages.Add(annonceImage);
                    storedImages.Add(annonceImage);
                }
                catch (ImageProcessingException ex)
                {
                    // Fix #3: Delete already-stored images before removing the annonce
                    foreach (var stored in storedImages)
                    {
                        await _blobStorage.DeleteImageWithThumbnailsAsync(
                            stored.ImagePath, stored.ThumbnailSmallPath, stored.ThumbnailMediumPath);
                    }
                    _context.Annonces.Remove(annonce);
                    await _context.SaveChangesAsync();
                    return BadRequest(new { message = ex.Message });
                }
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
        if (userId == null) return Unauthorized();
        
        var annonces = await _context.Annonces
            .AsNoTracking()
            .Include(a => a.Images)
            .Include(a => a.Category)
            .Where(a => a.UserId == userId.Value)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new MyAnnonceDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                CategoryId = a.CategoryId,
                Category = a.Category.Name,
                CategoryName = a.Category.Name,
                CategoryArName = a.Category.ArName,
                Status = a.Status.ToString(),
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                MainThumbnailUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ThumbnailMediumPath).FirstOrDefault(),
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
    [HttpPost("{id}/delete")]
    [Authorize]
    public async Task<ActionResult<MyAnnonceDto>> DeleteAnnonce(int id, [FromBody] DeleteAnnonceDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();
        
        var annonce = await _context.Annonces
            .Include(a => a.Images)
            .FirstOrDefaultAsync(a => a.Id == id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        // Check ownership (unless admin)
        var isAdmin = User.IsInRole("Admin");
        if (annonce.UserId != userId.Value && !isAdmin)
        {
            return Forbid();
        }

        if (!IsSoftDeleteStatus(dto.Status))
        {
            return BadRequest(new
            {
                message = "Le statut de suppression doit être Vendu, Archivé ou Supprimé"
            });
        }

        annonce.Status = dto.Status;
        annonce.DeletedAt = DateTime.UtcNow;
        annonce.DeletedBy = userId.Value;
        await _context.SaveChangesAsync();

        var updatedAnnonce = await BuildMyAnnonceDtoQuery(id)
            .FirstAsync();

        return Ok(updatedAnnonce);
    }
    
    // Fix #2: Return nullable int and Unauthorized instead of defaulting to 0
    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
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
            CategoryId = annonce.CategoryId,
            Category = annonce.Category.Name,
            CategoryName = annonce.Category.Name,
            CategoryArName = annonce.Category.ArName,
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
            ReservationEnabled = annonce.ReservationEnabled,
            CreatedAt = annonce.CreatedAt,
            ImageUrls = annonce.Images.OrderBy(i => i.DisplayOrder).Select(i => new ImageUrlDto
            {
                Url = i.ImagePath,
                ThumbnailSmall = i.ThumbnailSmallPath,
                ThumbnailMedium = i.ThumbnailMediumPath,
            }).ToList(),
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

    private IQueryable<MyAnnonceDto> BuildMyAnnonceDtoQuery(int annonceId)
    {
        return _context.Annonces
            .AsNoTracking()
            .Include(a => a.Images)
            .Include(a => a.Category)
            .Where(a => a.Id == annonceId)
            .Select(a => new MyAnnonceDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                CategoryId = a.CategoryId,
                Category = a.Category.Name,
                CategoryName = a.Category.Name,
                CategoryArName = a.Category.ArName,
                Status = a.Status.ToString(),
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                MainThumbnailUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ThumbnailMediumPath).FirstOrDefault(),
                IsGoodDeal = a.IsGoodDeal,
                ModerationThreadId = _context.Conversations
                    .Where(t => t.AnnonceId == a.Id && t.IsModeration)
                    .Select(t => (int?)t.Id)
                    .FirstOrDefault(),
                CreatedAt = a.CreatedAt
            });
    }

    private static bool IsSoftDeleteStatus(AnnonceStatus status) =>
        status is AnnonceStatus.Sold or AnnonceStatus.Archived or AnnonceStatus.Deleted;
    
    // Fix #15: Single query to load all categories, then traverse in-memory
    private async Task<List<int>> GetCategoryAndSubcategoryIds(int categoryId)
    {
        var allCategories = await _context.Categories
            .AsNoTracking()
            .Select(c => new { c.Id, c.ParentId })
            .ToListAsync();
        
        var result = new List<int> { categoryId };
        var queue = new Queue<int>();
        queue.Enqueue(categoryId);
        
        while (queue.Count > 0)
        {
            var parentId = queue.Dequeue();
            var children = allCategories.Where(c => c.ParentId == parentId).Select(c => c.Id);
            foreach (var childId in children)
            {
                result.Add(childId);
                queue.Enqueue(childId);
            }
        }
        
        return result.Distinct().ToList();
    }
}
