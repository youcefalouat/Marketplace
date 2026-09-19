using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/safety")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class SafetyController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SafetyController(ApplicationDbContext context) => _context = context;

    [HttpPost("listings/{annonceId:int}/reports")]
    public async Task<IActionResult> ReportListing(int annonceId, [FromBody] CreateListingReportDto dto)
    {
        var reporterId = GetCurrentUserId();
        if (reporterId == null) return Unauthorized();
        if (!ModelState.IsValid || string.IsNullOrWhiteSpace(dto.Reason))
            return BadRequest(new { message = "Motif de signalement invalide" });

        var annonce = await _context.Annonces.AsNoTracking()
            .Where(a => a.Id == annonceId && a.Status == AnnonceStatus.Approved)
            .Select(a => new { a.Id, a.UserId, a.Title })
            .FirstOrDefaultAsync();
        if (annonce == null) return NotFound(new { message = "Annonce introuvable" });
        if (annonce.UserId == reporterId) return BadRequest(new { message = "Vous ne pouvez pas signaler votre propre annonce" });

        var duplicate = await _context.ModerationReports.AnyAsync(r =>
            r.ReporterId == reporterId && r.ReportedAnnonceId == annonceId &&
            r.Type == "Listing" && r.Status == "Pending");
        if (duplicate) return Conflict(new { message = "Cette annonce a déjà été signalée" });

        _context.ModerationReports.Add(new ModerationReport
        {
            ReporterId = reporterId.Value,
            ReportedAnnonceId = annonce.Id,
            ReportedUserId = annonce.UserId,
            Type = "Listing",
            Reason = dto.Reason.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();
        return Ok(new { message = "Signalement enregistré" });
    }

    [HttpPost("users/{userId:int}/block")]
    public async Task<IActionResult> BlockUser(int userId, [FromBody] CreateBlockDto? dto)
    {
        var blockingUserId = GetCurrentUserId();
        if (blockingUserId == null) return Unauthorized();
        if (blockingUserId == userId) return BadRequest(new { message = "Vous ne pouvez pas vous bloquer vous-même" });

        var targetExists = await _context.Users.AnyAsync(u => u.Id == userId && !u.IsDeleted);
        if (!targetExists) return NotFound(new { message = "Utilisateur introuvable" });
        if (dto?.AnnonceId is int annonceId && !await _context.Annonces.AnyAsync(a => a.Id == annonceId && a.UserId == userId))
            return BadRequest(new { message = "Annonce invalide" });

        var alreadyBlocked = await _context.UserBlocks.AnyAsync(b =>
            b.BlockingUserId == blockingUserId && b.BlockedUserId == userId);
        if (!alreadyBlocked)
        {
            _context.UserBlocks.Add(new UserBlock
            {
                BlockingUserId = blockingUserId.Value,
                BlockedUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
        }

        // Keep blocking visible to the same moderation queue as user reports.
        var alreadyReported = await _context.ModerationReports.AnyAsync(r =>
            r.ReporterId == blockingUserId && r.ReportedUserId == userId &&
            r.Type == "Block" && r.Status == "Pending");
        if (!alreadyReported)
        {
            _context.ModerationReports.Add(new ModerationReport
            {
                ReporterId = blockingUserId.Value,
                ReportedUserId = userId,
                ReportedAnnonceId = dto?.AnnonceId,
                Type = "Block",
                Reason = "User blocked",
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "Utilisateur bloqué" });
    }

    [HttpGet("blocks")]
    public async Task<IActionResult> GetMyBlocks()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();
        var blocks = await _context.UserBlocks.AsNoTracking()
            .Where(b => b.BlockingUserId == userId)
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => new { b.BlockedUserId, b.CreatedAt, Name = b.BlockedUser.Name })
            .ToListAsync();
        return Ok(blocks);
    }

    [HttpDelete("users/{userId:int}/block")]
    public async Task<IActionResult> UnblockUser(int userId)
    {
        var blockingUserId = GetCurrentUserId();
        if (blockingUserId == null) return Unauthorized();
        var block = await _context.UserBlocks.FirstOrDefaultAsync(b =>
            b.BlockingUserId == blockingUserId && b.BlockedUserId == userId);
        if (block != null)
        {
            _context.UserBlocks.Remove(block);
            await _context.SaveChangesAsync();
        }
        return NoContent();
    }

    private int? GetCurrentUserId()
    {
        var value = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(value, out var id) ? id : null;
    }
}
