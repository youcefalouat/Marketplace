using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public UsersController(ApplicationDbContext context)
    {
        _context = context;
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
            EmailVerified = user.EmailVerified
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
            EmailVerified = user.EmailVerified
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
