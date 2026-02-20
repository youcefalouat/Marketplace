using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;
using MarketplaceApi.Services;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ITokenService _tokenService;
    
    public AuthController(ApplicationDbContext context, ITokenService tokenService)
    {
        _context = context;
        _tokenService = tokenService;
    }
    
    /// <summary>
    /// Register a new user
    /// </summary>
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register([FromBody] RegisterDto dto)
    {
        // Check if email already exists
        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower()))
        {
            return BadRequest(new { message = "Un compte avec cet email existe déjà" });
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
        
        var user = new User
        {
            Email = dto.Email.ToLower(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Name = dto.Name,
            Phone = dto.Phone,
            WilayaId = dto.WilayaId,
            CommuneId = dto.CommuneId,
            Role = UserRole.User,
            CreatedAt = DateTime.UtcNow
        };
        
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        
        var token = _tokenService.GenerateToken(user);
        
        return Ok(new AuthResponseDto
        {
            Token = token,
            User = MapToUserDto(user, wilaya.Name, commune.Name)
        });
    }
    
    /// <summary>
    /// Login with email and password
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login([FromBody] LoginDto dto)
    {
        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        
        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
        {
            return Unauthorized(new { message = "Email ou mot de passe incorrect" });
        }
        
        var token = _tokenService.GenerateToken(user);
        
        return Ok(new AuthResponseDto
        {
            Token = token,
            User = MapToUserDto(user, user.Wilaya.Name, user.Commune.Name)
        });
    }
    
    /// <summary>
    /// Social login (Google / Facebook) - exchanges social token for app JWT
    /// </summary>
    [HttpPost("social-login")]
    public async Task<ActionResult<AuthResponseDto>> SocialLogin([FromBody] SocialLoginDto dto)
    {
        // TODO: Validate the social token with Google/Facebook API
        // For now, return a placeholder response
        // In production, you would:
        // 1. Verify the token with the provider
        // 2. Extract user info (email, name)
        // 3. Find or create the user
        // 4. Generate a JWT token
        
        return BadRequest(new { message = "Social login not yet configured. Please provide Google/Facebook client IDs." });
    }
    
    private static UserDto MapToUserDto(User user, string wilayaName, string communeName)
    {
        return new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Phone = user.Phone,
            WilayaId = user.WilayaId,
            CommuneId = user.CommuneId,
            WilayaName = wilayaName,
            CommuneName = communeName,
            Role = user.Role.ToString()
        };
    }
}
