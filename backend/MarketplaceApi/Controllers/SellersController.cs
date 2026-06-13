using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;
using MarketplaceApi.Services;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SellersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IRatingService _ratingService;

    public SellersController(ApplicationDbContext context, IRatingService ratingService)
    {
        _context = context;
        _ratingService = ratingService;
    }

    // GET /api/sellers/{id}
    [HttpGet("{id:int}")]
    public async Task<ActionResult<SellerProfileDto>> GetSellerProfile(int id)
    {
        var user = await _context.Users
            .AsNoTracking()
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .Where(u => u.Id == id && !u.IsDeleted)
            .Select(u => new
            {
                u.Id, u.Name, u.AvatarUrl, u.IsVerifiedSeller, u.CreatedAt,
                WilayaName = u.Wilaya.Name,
                CommuneName = u.Commune.Name,
                TotalAnnonces = u.Annonces.Count(a => a.Status == AnnonceStatus.Approved)
            })
            .FirstOrDefaultAsync();

        if (user == null) return NotFound(new { message = "Vendeur introuvable" });

        var summary = await _ratingService.GetSellerSummaryAsync(id);

        return Ok(new SellerProfileDto
        {
            Id = user.Id,
            Name = user.Name,
            AvatarUrl = user.AvatarUrl,
            CommuneName = user.CommuneName,
            WilayaName = user.WilayaName,
            IsVerifiedSeller = user.IsVerifiedSeller,
            AverageRating = summary?.RatingCount > 0 ? summary.AverageRating : null,
            TotalReviews = summary?.RatingCount ?? 0,
            TotalAnnonces = user.TotalAnnonces,
            MemberSince = user.CreatedAt
        });
    }

    // GET /api/sellers/{id}/annonces
    [HttpGet("{id:int}/annonces")]
    public async Task<ActionResult<PaginatedResponse<AnnonceListDto>>> GetSellerAnnonces(
        int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (!await _context.Users.AnyAsync(u => u.Id == id && !u.IsDeleted))
            return NotFound(new { message = "Vendeur introuvable" });

        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(page, 1);

        var query = _context.Annonces
            .AsNoTracking()
            .Include(a => a.Images)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .Where(a => a.UserId == id && a.Status == AnnonceStatus.Approved);

        var totalCount = await query.CountAsync();

        var raw = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new
            {
                a.Id, a.Title, a.Price, a.IsExchange, a.IsGoodDeal, a.CreatedAt,
                WilayaName = a.Wilaya.Name, CommuneName = a.Commune.Name,
                CategoryId = a.CategoryId,
                CategoryName = a.Category.Name, CategoryArName = a.Category.ArName,
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                MainThumbnailUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ThumbnailMediumPath).FirstOrDefault(),
                SellerId = a.UserId
            })
            .ToListAsync();

        var sellerSummaries = await _ratingService.GetSellerSummariesAsync(raw.Select(x => x.SellerId));

        var items = raw.Select(a =>
        {
            sellerSummaries.TryGetValue(a.SellerId, out var rating);
            return new AnnonceListDto
            {
                Id = a.Id, Title = a.Title, Price = a.Price,
                WilayaName = a.WilayaName, CommuneName = a.CommuneName,
                CategoryId = a.CategoryId, Category = a.CategoryName,
                CategoryName = a.CategoryName, CategoryArName = a.CategoryArName,
                MainImageUrl = a.MainImageUrl, MainThumbnailUrl = a.MainThumbnailUrl,
                IsExchange = a.IsExchange, IsGoodDeal = a.IsGoodDeal,
                SellerAverageRating = rating?.RatingCount > 0 ? rating.AverageRating : null,
                SellerRatingCount = rating?.RatingCount,
                CreatedAt = a.CreatedAt
            };
        }).ToList();

        return Ok(new PaginatedResponse<AnnonceListDto>
        {
            Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    // GET /api/sellers/{id}/reviews
    [HttpGet("{id:int}/reviews")]
    public async Task<ActionResult<PaginatedResponse<SellerReviewDto>>> GetSellerReviews(
        int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (!await _context.Users.AnyAsync(u => u.Id == id && !u.IsDeleted))
            return NotFound(new { message = "Vendeur introuvable" });

        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(page, 1);

        var query = _context.UserRatings
            .AsNoTracking()
            .Include(r => r.Rater)
            .Where(r => r.SellerId == id);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new SellerReviewDto
            {
                ReviewerId = r.RaterId,
                ReviewerName = r.Rater.Name,
                ReviewerAvatarUrl = r.Rater.AvatarUrl,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();

        return Ok(new PaginatedResponse<SellerReviewDto>
        {
            Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }
}
