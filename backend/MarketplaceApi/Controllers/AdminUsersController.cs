using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;
using MarketplaceApi.Services;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/admin/users")]
[Authorize(Roles = "Admin")]
public class AdminUsersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IRatingService _ratingService;

    public AdminUsersController(ApplicationDbContext context, IRatingService ratingService)
    {
        _context = context;
        _ratingService = ratingService;
    }

    // GET /api/admin/users/sellers?verified=all|true|false&search=&page=&pageSize=
    [HttpGet("sellers")]
    public async Task<ActionResult<PaginatedResponse<AdminUserDto>>> GetSellers(
        [FromQuery] string? verified = "all",
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        pageSize = Math.Clamp(pageSize, 1, 100);
        page = Math.Max(page, 1);

        var query = _context.Users
            .AsNoTracking()
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .Where(u => !u.IsDeleted);

        if (verified == "true")  query = query.Where(u => u.IsVerifiedSeller);
        if (verified == "false") query = query.Where(u => !u.IsVerifiedSeller);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var lower = search.ToLower();
            query = query.Where(u =>
                u.Name.ToLower().Contains(lower) ||
                u.Email.ToLower().Contains(lower));
        }

        var totalCount = await query.CountAsync();

        var usersRaw = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.Id, u.Name, u.Email, u.AvatarUrl, u.IsVerifiedSeller, u.CreatedAt,
                WilayaName = u.Wilaya.Name,
                CommuneName = u.Commune.Name,
                TotalAnnonces = u.Annonces.Count(a => a.Status == AnnonceStatus.Approved)
            })
            .ToListAsync();

        var sellerIds = usersRaw.Select(u => u.Id).ToList();
        var summaries = await _ratingService.GetSellerSummariesAsync(sellerIds);

        var items = usersRaw.Select(u =>
        {
            summaries.TryGetValue(u.Id, out var rating);
            return new AdminUserDto
            {
                Id = u.Id, Name = u.Name, Email = u.Email, AvatarUrl = u.AvatarUrl,
                WilayaName = u.WilayaName, CommuneName = u.CommuneName,
                AverageRating = rating?.RatingCount > 0 ? rating.AverageRating : null,
                TotalAnnonces = u.TotalAnnonces,
                IsVerifiedSeller = u.IsVerifiedSeller,
                CreatedAt = u.CreatedAt
            };
        }).ToList();

        return Ok(new PaginatedResponse<AdminUserDto>
        {
            Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize
        });
    }

    // PUT /api/admin/users/{id}/verified-seller
    [HttpPut("{id:int}/verified-seller")]
    public async Task<IActionResult> SetVerifiedSeller(int id, [FromBody] SetVerifiedSellerDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null || user.IsDeleted)
            return NotFound(new { message = "Utilisateur introuvable" });

        user.IsVerifiedSeller = dto.IsVerifiedSeller;
        user.VerifiedAt = dto.IsVerifiedSeller ? DateTime.UtcNow : null;
        await _context.SaveChangesAsync();

        return Ok(new { message = dto.IsVerifiedSeller ? "Vendeur vérifié" : "Vérification retirée", isVerifiedSeller = user.IsVerifiedSeller });
    }
}
