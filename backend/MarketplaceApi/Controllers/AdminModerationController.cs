using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/admin/moderation")]
[Authorize(Roles = "Admin")]
public class AdminModerationController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AdminModerationController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Create (or reuse) a moderation thread for an annonce and send the first admin message.
    /// Also moves the annonce to UnderReview while the thread is active.
    /// </summary>
    [HttpPost("threads")]
    public async Task<ActionResult<ModerationThreadDto>> CreateThread([FromBody] CreateModerationThreadDto dto)
    {
        var annonce = await _context.Annonces
            .Include(a => a.Images)
            .Include(a => a.User)
            .FirstOrDefaultAsync(a => a.Id == dto.AnnonceId);

        if (annonce == null) return NotFound(new { message = "Annonce introuvable" });
        if (annonce.Status == AnnonceStatus.Approved || annonce.Status == AnnonceStatus.Rejected)
        {
            return BadRequest(new { message = "Cette annonce est déjà traitée" });
        }

        var thread = await _context.ModerationThreads
            .Include(t => t.Messages)
                .ThenInclude(m => m.Sender)
            .FirstOrDefaultAsync(t => t.AnnonceId == dto.AnnonceId);

        if (thread == null)
        {
            thread = new ModerationThread
            {
                AnnonceId = annonce.Id,
                OwnerId = annonce.UserId,
                CreatedAt = DateTime.UtcNow,
                LastMessageAt = DateTime.UtcNow
            };
            _context.ModerationThreads.Add(thread);
            await _context.SaveChangesAsync();
        }

        var adminId = GetCurrentUserId();

        var message = new ModerationMessage
        {
            ThreadId = thread.Id,
            SenderId = adminId,
            Content = dto.Message,
            SentAt = DateTime.UtcNow,
            IsFromAdmin = true
        };

        _context.ModerationMessages.Add(message);
        thread.LastMessageAt = message.SentAt;

        if (annonce.Status == AnnonceStatus.Pending)
        {
            annonce.Status = AnnonceStatus.UnderReview;
        }

        await _context.SaveChangesAsync();

        return await GetThread(thread.Id);
    }

    [HttpGet("threads/{threadId:int}")]
    public async Task<ActionResult<ModerationThreadDto>> GetThread(int threadId)
    {
        var thread = await _context.ModerationThreads
            .Include(t => t.Annonce).ThenInclude(a => a.Images)
            .Include(t => t.Owner)
            .Include(t => t.Messages).ThenInclude(m => m.Sender)
            .FirstOrDefaultAsync(t => t.Id == threadId);

        if (thread == null) return NotFound();

        var me = GetCurrentUserId();
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
                    IsMe = m.SenderId == me
                })
                .ToList()
        });
    }

    [HttpPost("threads/{threadId:int}/messages")]
    public async Task<ActionResult<ModerationMessageDto>> SendMessage(int threadId, [FromBody] SendModerationMessageDto dto)
    {
        var thread = await _context.ModerationThreads
            .Include(t => t.Annonce)
            .FirstOrDefaultAsync(t => t.Id == threadId);

        if (thread == null) return NotFound();
        if (thread.ClosedAt != null) return BadRequest(new { message = "Conversation clôturée" });

        var adminId = GetCurrentUserId();
        var admin = await _context.Users.FindAsync(adminId);

        var message = new ModerationMessage
        {
            ThreadId = threadId,
            SenderId = adminId,
            Content = dto.Content,
            SentAt = DateTime.UtcNow,
            IsFromAdmin = true
        };

        _context.ModerationMessages.Add(message);
        thread.LastMessageAt = message.SentAt;

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
            SenderName = admin?.Name ?? "Admin",
            Content = message.Content,
            SentAt = message.SentAt,
            IsFromAdmin = true,
            IsMe = true
        });
    }

    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.Parse(userIdClaim ?? "0");
    }
}
