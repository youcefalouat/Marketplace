using System.Security.Claims;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Models;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReservationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IReservationService _reservationService;

    public ReservationsController(ApplicationDbContext context, IReservationService reservationService)
    {
        _context = context;
        _reservationService = reservationService;
    }

    // POST /api/reservations
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<CreateReservationResponseDto>> CreateReservation(
        [FromBody] CreateReservationDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null) return Unauthorized();

        if (!user.PhoneVerified)
            return StatusCode(403, new
            {
                message = "Veuillez vérifier votre numéro de téléphone avant de réserver",
                requiresPhoneVerification = true
            });

        try
        {
            var result = await _reservationService.CreateReservationAsync(userId.Value, dto.AnnonceId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // GET /api/annonces/{annonceId}/reservations
    [HttpGet("/api/annonces/{annonceId:int}/reservations")]
    [Authorize]
    public async Task<ActionResult<PaginatedResponse<ReservationDto>>> GetReservations(
        int annonceId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var annonce = await _context.Annonces
            .AsNoTracking()
            .Where(a => a.Id == annonceId)
            .Select(a => new { a.UserId })
            .FirstOrDefaultAsync();

        if (annonce == null) return NotFound(new { message = "Annonce introuvable" });

        var isAdmin = User.IsInRole("Admin");
        if (annonce.UserId != userId.Value && !isAdmin)
            return Forbid();

        pageSize = Math.Clamp(pageSize, 1, 100);
        page = Math.Max(page, 1);

        var query = _context.Reservations
            .AsNoTracking()
            .Where(r => r.AnnonceId == annonceId)
            .OrderBy(r => r.Rank);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new ReservationDto
            {
                Id = r.Id,
                Rank = r.Rank,
                UserName = r.User.Name,
                Phone = r.User.Phone ?? string.Empty,
                ReservationDateTime = r.ReservationDateTime,
                RendezVousDateTime = r.RendezVousDateTime
            })
            .ToListAsync();

        return Ok(new PaginatedResponse<ReservationDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    // DELETE /api/reservations/{id}
    [HttpDelete("{id:int}")]
    [Authorize]
    public async Task<IActionResult> DeleteReservation(int id)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var reservation = await _context.Reservations
            .Include(r => r.Annonce)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (reservation == null) return NotFound(new { message = "Réservation introuvable" });

        var isAdmin = User.IsInRole("Admin");
        if (reservation.Annonce.UserId != userId.Value && !isAdmin)
            return Forbid();

        try
        {
            await _reservationService.DeleteReservationAsync(id);
            return Ok(new { message = "Réservation supprimée avec succès" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // PUT /api/reservations/{id}/rendez-vous
    [HttpPut("{id:int}/rendez-vous")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateRendezVous(int id, [FromBody] UpdateRendezVousDto dto)
    {
        try
        {
            await _reservationService.UpdateRendezVousAsync(id, dto.RendezVousDateTime);
            return Ok(new { message = "Rendez-vous mis à jour avec succès" });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }
}
