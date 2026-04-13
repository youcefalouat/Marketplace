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
public class RatingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IRatingService _ratingService;

    public RatingsController(ApplicationDbContext context, IRatingService ratingService)
    {
        _context = context;
        _ratingService = ratingService;
    }

    /// <summary>
    /// Create/update a rating for a seller (authenticated users only)
    /// </summary>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<SellerRatingSummaryDto>> CreateRating([FromBody] CreateRatingDto dto)
    {
        var raterId = GetCurrentUserId();
        if (raterId == null) return Unauthorized();

        if (dto.SellerId == raterId.Value)
        {
            return BadRequest(new { message = "Vous ne pouvez pas vous noter vous-même" });
        }

        var sellerExists = await _context.Users.AnyAsync(u => u.Id == dto.SellerId && !u.IsDeleted);
        if (!sellerExists)
        {
            return NotFound(new { message = "Vendeur introuvable" });
        }

        await _ratingService.CreateOrUpdateRatingAsync(raterId.Value, dto.SellerId, dto.Rating, dto.Comment);

        var summary = await _ratingService.GetSellerSummaryAsync(dto.SellerId);
        return Ok(new SellerRatingSummaryDto
        {
            AverageRating = summary?.AverageRating ?? 0,
            RatingCount = summary?.RatingCount ?? 0,
            Ratings = new List<RatingDto>()
        });
    }

    /// <summary>
    /// Get seller rating summary (public)
    /// </summary>
    [HttpGet("user/{userId:int}")]
    public async Task<ActionResult<SellerRatingSummaryDto>> GetSellerRatings(
        int userId,
        [FromQuery] bool includeRatings = false,
        [FromQuery] int take = 20)
    {
        var summary = await _ratingService.GetSellerSummaryAsync(userId);

        var dto = new SellerRatingSummaryDto
        {
            AverageRating = summary?.AverageRating ?? 0,
            RatingCount = summary?.RatingCount ?? 0
        };

        if (includeRatings)
        {
            take = Math.Clamp(take, 1, 50);

            dto.Ratings = await _context.UserRatings
                .AsNoTracking()
                .Where(r => r.SellerId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .Take(take)
                .Select(r => new RatingDto
                {
                    Id = r.Id,
                    SellerId = r.SellerId,
                    RaterId = r.RaterId,
                    RaterName = r.Rater.Name,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();
        }

        return Ok(dto);
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }
}
