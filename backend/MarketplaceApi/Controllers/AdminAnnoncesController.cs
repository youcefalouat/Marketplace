using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/admin/annonces")]
[Authorize(Roles = "Admin")]
public class AdminAnnoncesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public AdminAnnoncesController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    /// <summary>
    /// Get all pending annonces
    /// </summary>
    [HttpGet("pending")]
    public async Task<ActionResult<List<AdminAnnonceListDto>>> GetPendingAnnonces()
    {
        var annonces = await _context.Annonces
            .Include(a => a.User)
            .Include(a => a.Category)
            .Where(a => a.Status == AnnonceStatus.Pending || a.Status == AnnonceStatus.UnderReview)
            .OrderBy(a => a.CreatedAt)
            .Select(a => new AdminAnnonceListDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                Category = a.Category.Name,
                Status = a.Status.ToString(),
                SellerName = a.User.Name,
                SellerPhone = a.User.Phone,
                IsGoodDeal = a.IsGoodDeal,
                StorePriceEstimate = a.StorePriceEstimate,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
        
        return Ok(annonces);
    }
    
    /// <summary>
    /// Get all annonces for admin (with filters)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<AdminAnnonceListDto>>> GetAllAnnonces([FromQuery] AnnonceStatus? status)
    {
        var query = _context.Annonces
            .Include(a => a.User)
            .Include(a => a.Category)
            .AsQueryable();
        
        if (status.HasValue)
        {
            query = query.Where(a => a.Status == status.Value);
        }
        
        var annonces = await query
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new AdminAnnonceListDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                Category = a.Category.Name,
                Status = a.Status.ToString(),
                SellerName = a.User.Name,
                SellerPhone = a.User.Phone,
                IsGoodDeal = a.IsGoodDeal,
                StorePriceEstimate = a.StorePriceEstimate,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
        
        return Ok(annonces);
    }
    
    /// <summary>
    /// Get annonce detail for admin
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<AdminAnnonceDetailDto>> GetAnnonceDetail(int id)
    {
        var annonce = await _context.Annonces
            .Include(a => a.User).ThenInclude(u => u.Wilaya)
            .Include(a => a.User).ThenInclude(u => u.Commune)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .Include(a => a.Images)
            .Include(a => a.AdminNotes)
                .ThenInclude(n => n.Admin)
            .FirstOrDefaultAsync(a => a.Id == id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        return Ok(new AdminAnnonceDetailDto
        {
            Id = annonce.Id,
            Title = annonce.Title,
            Description = annonce.Description,
            Price = annonce.Price,
            Category = annonce.Category.Name,
            State = annonce.State.ToString(),
            Phone = annonce.Phone,
            WilayaId = annonce.WilayaId,
            CommuneId = annonce.CommuneId,
            WilayaName = annonce.Wilaya.Name,
            CommuneName = annonce.Commune.Name,
            IsExchange = annonce.IsExchange,
            Status = annonce.Status.ToString(),
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
                Phone = annonce.User.Phone,
                WilayaName = annonce.User.Wilaya.Name,
                CommuneName = annonce.User.Commune.Name,
                AverageRating = null,
                RatingCount = null
            },
            IsGoodDeal = annonce.IsGoodDeal,
            StorePriceEstimate = annonce.StorePriceEstimate,
            AdminNotes = annonce.AdminNotes.OrderByDescending(n => n.CreatedAt).Select(n => new AdminNoteDto
            {
                Id = n.Id,
                Note = n.Note,
                AdminName = n.Admin.Name,
                CreatedAt = n.CreatedAt
            }).ToList()
        });
    }
    
    /// <summary>
    /// Approve an annonce
    /// </summary>
    [HttpPost("{id}/approve")]
    public async Task<IActionResult> ApproveAnnonce(int id)
    {
        var annonce = await _context.Annonces.FindAsync(id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        annonce.Status = AnnonceStatus.Approved;

        var thread = await _context.ModerationThreads.FirstOrDefaultAsync(t => t.AnnonceId == id);
        if (thread != null && thread.ClosedAt == null)
        {
            thread.ClosedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Annonce approuvée" });
    }
    
    /// <summary>
    /// Reject an annonce
    /// </summary>
    [HttpPost("{id}/reject")]
    public async Task<IActionResult> RejectAnnonce(int id)
    {
        var annonce = await _context.Annonces.FindAsync(id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        annonce.Status = AnnonceStatus.Rejected;

        var thread = await _context.ModerationThreads.FirstOrDefaultAsync(t => t.AnnonceId == id);
        if (thread != null && thread.ClosedAt == null)
        {
            thread.ClosedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Annonce refusée" });
    }
    
    /// <summary>
    /// Add admin note to an annonce
    /// </summary>
    [HttpPost("{id}/note")]
    public async Task<ActionResult<AdminNoteDto>> AddNote(int id, [FromBody] AddAdminNoteDto dto)
    {
        var annonce = await _context.Annonces.FindAsync(id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        var adminId = GetCurrentUserId();
        var admin = await _context.Users.FindAsync(adminId);
        
        var note = new AdminNote
        {
            AnnonceId = id,
            AdminId = adminId,
            Note = dto.Note,
            CreatedAt = DateTime.UtcNow
        };
        
        _context.AdminNotes.Add(note);
        await _context.SaveChangesAsync();
        
        return Ok(new AdminNoteDto
        {
            Id = note.Id,
            Note = note.Note,
            AdminName = admin?.Name ?? "Admin",
            CreatedAt = note.CreatedAt
        });
    }
    
    /// <summary>
    /// Update store estimate and good deal flag
    /// </summary>
    [HttpPut("{id}/estimate")]
    public async Task<IActionResult> UpdateEstimate(int id, [FromBody] UpdateStoreEstimateDto dto)
    {
        var annonce = await _context.Annonces.FindAsync(id);
        
        if (annonce == null)
        {
            return NotFound();
        }
        
        annonce.StorePriceEstimate = dto.StorePriceEstimate;
        annonce.IsGoodDeal = dto.IsGoodDeal;
        
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Estimation mise à jour" });
    }
    
    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.Parse(userIdClaim ?? "0");
    }
}
