using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ModerationController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ModerationController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// List moderation threads for the current user (owner).
    /// </summary>
    [HttpGet("threads/my")]
    public async Task<ActionResult<List<ModerationThreadSummaryDto>>> GetMyThreads()
    {
        var me = GetCurrentUserId();
        if (me == null) return Unauthorized();

        var threads = await _context.ModerationThreads
            .AsNoTracking()
            .Include(t => t.Annonce).ThenInclude(a => a.Images)
            .Where(t => t.OwnerId == me.Value)
            .OrderByDescending(t => t.LastMessageAt)
            .Select(t => new ModerationThreadSummaryDto
            {
                Id = t.Id,
                AnnonceId = t.AnnonceId,
                AnnonceTitle = t.Annonce.Title,
                AnnonceStatus = t.Annonce.Status.ToString(),
                AnnonceMainImageUrl = t.Annonce.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                LastMessageAt = t.LastMessageAt,
                LastMessagePreview = t.Messages
                    .OrderByDescending(m => m.SentAt)
                    .Select(m => m.Content)
                    .FirstOrDefault() ?? "",
                IsClosed = t.ClosedAt != null
            })
            .ToListAsync();

        return Ok(threads);
    }

    /// <summary>
    /// Get a moderation thread with messages (owner or admin).
    /// </summary>
    [HttpGet("threads/{threadId:int}")]
    public async Task<ActionResult<ModerationThreadDto>> GetThread(int threadId)
    {
        var thread = await _context.ModerationThreads
            .AsNoTracking()
            .Include(t => t.Annonce)
            .Include(t => t.Owner)
            .Include(t => t.Messages).ThenInclude(m => m.Sender)
            .FirstOrDefaultAsync(t => t.Id == threadId);

        if (thread == null) return NotFound();

        var me = GetCurrentUserId();
        if (me == null) return Unauthorized();
        var isAdmin = User.IsInRole("Admin");
        if (!isAdmin && thread.OwnerId != me.Value) return Forbid();

        return Ok(new ModerationThreadDto
        {
            Id = thread.Id,
            AnnonceId = thread.AnnonceId,
            AnnonceTitle = thread.Annonce.Title,
            AnnonceStatus = thread.Annonce.Status.ToString(),
            OwnerId = thread.OwnerId,
            OwnerName = thread.Owner.Name,
            CreatedAt = thread.CreatedAt,
            LastMessageAt = thread.LastMessageAt,
            IsClosed = thread.ClosedAt != null,
            Messages = thread.Messages
                .OrderBy(m => m.SentAt)
                .Select(m => new ModerationMessageDto
                {
                    Id = m.Id,
                    ThreadId = m.ThreadId,
                    SenderId = m.SenderId,
                    SenderName = m.Sender?.Name ?? (m.IsFromAdmin ? "Admin" : "Utilisateur"),
                    Content = m.Content,
                    SentAt = m.SentAt,
                    IsFromAdmin = m.IsFromAdmin,
                    IsMe = m.SenderId == me.Value
                })
                .ToList()
        });
    }

    /// <summary>
    /// Send a message as the annonce owner (admin uses /api/admin/moderation).
    /// </summary>
    [HttpPost("threads/{threadId:int}/messages")]
    public async Task<ActionResult<ModerationMessageDto>> SendOwnerMessage(int threadId, [FromBody] SendModerationMessageDto dto)
    {
        var me = GetCurrentUserId();
        if (me == null) return Unauthorized();

        var thread = await _context.ModerationThreads
            .Include(t => t.Annonce)
            .FirstOrDefaultAsync(t => t.Id == threadId);

        if (thread == null) return NotFound();
        if (thread.OwnerId != me.Value) return Forbid();
        if (thread.ClosedAt != null) return BadRequest(new { message = "Conversation clôturée" });

        var user = await _context.Users.FindAsync(me.Value);

        var message = new ModerationMessage
        {
            ThreadId = threadId,
            SenderId = me.Value,
            Content = dto.Content,
            SentAt = DateTime.UtcNow,
            IsFromAdmin = false
        };

        _context.ModerationMessages.Add(message);
        thread.LastMessageAt = message.SentAt;

        // Keep annonce under review while exchanging.
        if (thread.Annonce.Status == AnnonceStatus.Pending)
        {
            thread.Annonce.Status = AnnonceStatus.UnderReview;
        }

        await _context.SaveChangesAsync();

        return Ok(new ModerationMessageDto
        {
            Id = message.Id,
            ThreadId = message.ThreadId,
            SenderId = message.SenderId,
            SenderName = user?.Name ?? "Utilisateur",
            Content = message.Content,
            SentAt = message.SentAt,
            IsFromAdmin = false,
            IsMe = true
        });
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }
}
