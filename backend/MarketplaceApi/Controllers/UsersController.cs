using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Services;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IRatingService _ratingService;
    private readonly IBlobStorageService _blobStorageService;
    private readonly IImageProcessingService _imageProcessingService;

    public UsersController(
        ApplicationDbContext context,
        IRatingService ratingService,
        IBlobStorageService blobStorageService,
        IImageProcessingService imageProcessingService)
    {
        _context = context;
        _ratingService = ratingService;
        _blobStorageService = blobStorageService;
        _imageProcessingService = imageProcessingService;
    }
    
    /// <summary>
    /// Get current user profile
    /// </summary>
    [HttpGet("profile")]
    public async Task<ActionResult<UserDto>> GetProfile()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();
        
        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId.Value);
        
        if (user == null)
        {
            return NotFound();
        }
        
        return Ok(new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Phone = user.Phone,
            WilayaId = user.WilayaId,
            CommuneId = user.CommuneId,
            WilayaName = user.Wilaya.Name,
            CommuneName = user.Commune.Name,
            Role = user.Role.ToString(),
            PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified,
            AvatarUrl = user.AvatarUrl,
            IsVerifiedSeller = user.IsVerifiedSeller
        });
    }

    /// <summary>
    /// Update current user profile
    /// </summary>
    [HttpPut("profile")]
    public async Task<ActionResult<UserDto>> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();
        
        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null)
        {
            return NotFound();
        }
        
        // Validate wilaya and commune
        var wilaya = await _context.Wilayas.FindAsync(dto.WilayaId);
        if (wilaya == null)
        {
            return BadRequest(new { message = "Wilaya invalide" });
        }
        
        var commune = await _context.Communes.FirstOrDefaultAsync(
            c => c.Id == dto.CommuneId && c.WilayaId == dto.WilayaId);
        if (commune == null)
        {
            return BadRequest(new { message = "Commune invalide pour cette wilaya" });
        }
        
        user.Name = dto.Name;
        user.Phone = dto.Phone;
        user.WilayaId = dto.WilayaId;
        user.CommuneId = dto.CommuneId;
        
        await _context.SaveChangesAsync();
        
        return Ok(new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Phone = user.Phone,
            WilayaId = user.WilayaId,
            CommuneId = user.CommuneId,
            WilayaName = wilaya.Name,
            CommuneName = commune.Name,
            Role = user.Role.ToString(),
            PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified,
            AvatarUrl = user.AvatarUrl,
            IsVerifiedSeller = user.IsVerifiedSeller
        });
    }

    /// <summary>
    /// Upload or replace avatar image
    /// </summary>
    [HttpPost("avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null) return NotFound();

        if (file == null || file.Length == 0)
            return BadRequest(new { success = false, message = "Aucun fichier fourni" });

        ImageProcessingResult processed;
        try
        {
            processed = await _imageProcessingService.ProcessImageAsync(file);
        }
        catch (ImageProcessingException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }

        using (processed)
        {
            if (!string.IsNullOrEmpty(user.AvatarUrl))
                await _blobStorageService.DeleteImageAsync(user.AvatarUrl);

            var stored = await _blobStorageService.StoreProcessedImageAsync(processed);
            user.AvatarUrl = stored.ImagePath;
            await _context.SaveChangesAsync();

            return Ok(new { avatarUrl = stored.ImagePath });
        }
    }

    /// <summary>
    /// Get top verified sellers (public, location-aware)
    /// </summary>
    [HttpGet("top-verified")]
    [AllowAnonymous]
    public async Task<ActionResult<List<TopVerifiedUserDto>>> GetTopVerifiedUsers(
        [FromQuery] int? communeId,
        [FromQuery] int? wilayaId)
    {
        var usersRaw = await _context.Users
            .AsNoTracking()
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .Where(u => u.IsVerifiedSeller && !u.IsDeleted)
            .Select(u => new
            {
                u.Id, u.Name, u.AvatarUrl, u.CreatedAt,
                WilayaName = u.Wilaya.Name, CommuneName = u.Commune.Name,
                u.WilayaId, u.CommuneId,
                TotalAnnonces = u.Annonces.Count(a => a.Status == MarketplaceApi.Models.AnnonceStatus.Approved)
            })
            .ToListAsync();

        var sellerIds = usersRaw.Select(u => u.Id).ToList();
        var summaries = await _ratingService.GetSellerSummariesAsync(sellerIds);

        var dtos = usersRaw.Select(u =>
        {
            summaries.TryGetValue(u.Id, out var rating);
            return new
            {
                u.Id, u.Name, u.AvatarUrl, u.WilayaName, u.CommuneName,
                u.CommuneId, u.WilayaId, u.CreatedAt,
                AverageRating = rating?.RatingCount > 0 ? (double?)rating.AverageRating : null,
                TotalReviews = rating?.RatingCount ?? 0,
                u.TotalAnnonces
            };
        })
        .OrderBy(u => communeId.HasValue && u.CommuneId == communeId ? 0
                    : wilayaId.HasValue && u.WilayaId == wilayaId ? 1 : 2)
        .ThenByDescending(u => u.AverageRating ?? 0)
        .ThenByDescending(u => u.TotalAnnonces)
        .ThenByDescending(u => u.CreatedAt)
        .Take(20)
        .Select(u => new TopVerifiedUserDto
        {
            Id = u.Id, Name = u.Name, AvatarUrl = u.AvatarUrl,
            WilayaName = u.WilayaName, CommuneName = u.CommuneName,
            AverageRating = u.AverageRating, TotalReviews = u.TotalReviews,
            TotalAnnonces = u.TotalAnnonces, IsVerifiedSeller = true
        })
        .ToList();

        return Ok(dtos);
    }

    /// <summary>
    /// Search users by name, commune, or wilaya
    /// </summary>
    [HttpGet("search")]
    [AllowAnonymous]
    public async Task<ActionResult<PaginatedResponse<UserSearchResultDto>>> SearchUsers(
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(page, 1);

        var q = _context.Users
            .AsNoTracking()
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .Where(u => !u.IsDeleted);

        if (!string.IsNullOrWhiteSpace(query))
        {
            var lower = query.ToLower();
            q = q.Where(u =>
                u.Name.ToLower().Contains(lower) ||
                u.Commune.Name.ToLower().Contains(lower) ||
                u.Wilaya.Name.ToLower().Contains(lower));
        }

        var totalCount = await q.CountAsync();

        var usersRaw = await q
            .OrderBy(u => u.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new { u.Id, u.Name, u.AvatarUrl, u.IsVerifiedSeller,
                WilayaName = u.Wilaya.Name, CommuneName = u.Commune.Name })
            .ToListAsync();

        var sellerIds = usersRaw.Select(u => u.Id).ToList();
        var summaries = await _ratingService.GetSellerSummariesAsync(sellerIds);

        var items = usersRaw.Select(u =>
        {
            summaries.TryGetValue(u.Id, out var rating);
            return new UserSearchResultDto
            {
                Id = u.Id, Name = u.Name, AvatarUrl = u.AvatarUrl,
                IsVerifiedSeller = u.IsVerifiedSeller,
                WilayaName = u.WilayaName, CommuneName = u.CommuneName,
                AverageRating = rating?.RatingCount > 0 ? rating.AverageRating : null
            };
        }).ToList();

        return Ok(new PaginatedResponse<UserSearchResultDto>
        {
            Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }

    /// <summary>
    /// Update current user FCM Token for push notifications
    /// </summary>
    [HttpPost("fcm-token")]
    public async Task<IActionResult> UpdateFcmToken([FromBody] FcmTokenDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null)
        {
            return NotFound();
        }

        user.FcmToken = dto.Token;
        await _context.SaveChangesAsync();
        
        return Ok();
    }
}
