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
    private readonly ISmsService _smsService;
    
    public AuthController(ApplicationDbContext context, ITokenService tokenService, ISmsService smsService)
    {
        _context = context;
        _tokenService = tokenService;
        _smsService = smsService;
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
        // Note: In production, you would verify dto.AccessToken with Google/Facebook API first
        // to ensure the request is legitimate and extract the real email/name.
        // For now, we trust the provided DTO (simplified setup).

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower() || 
                                      (u.Provider == dto.Provider && u.ProviderId == dto.ProviderId));
            
        if (user == null)
        {
            // Auto-create account
            // Get default location (Alger - 16)
            var wilaya = await _context.Wilayas.FirstOrDefaultAsync(w => w.Code == "16");
            var commune = await _context.Communes.FirstOrDefaultAsync(c => c.WilayaId == wilaya!.Id);
            
            user = new User
            {
                Email = dto.Email.ToLower(),
                Name = dto.Name,
                Provider = dto.Provider,
                ProviderId = dto.ProviderId,
                PasswordHash = "", 
                Phone = "", 
                WilayaId = wilaya?.Id ?? 1,
                CommuneId = commune?.Id ?? 1,
                Role = UserRole.User,
                CreatedAt = DateTime.UtcNow
            };
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            // Reload with includes
            user = await _context.Users
                .Include(u => u.Wilaya)
                .Include(u => u.Commune)
                .FirstAsync(u => u.Id == user.Id);
        }
        else if (string.IsNullOrEmpty(user.Provider))
        {
            // Link existing local account to this social provider
            user.Provider = dto.Provider;
            user.ProviderId = dto.ProviderId;
            await _context.SaveChangesAsync();
        }
        
        var token = _tokenService.GenerateToken(user);
        
        return Ok(new AuthResponseDto
        {
            Token = token,
            User = MapToUserDto(user, user.Wilaya?.Name ?? "", user.Commune?.Name ?? "")
        });
    }
    
    [HttpPut("profile")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult<UserDto>> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
        {
            return Unauthorized();
        }

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
            return NotFound(new { message = "Utilisateur introuvable" });

        // Validate wilaya and commune
        var wilaya = await _context.Wilayas.FindAsync(dto.WilayaId);
        if (wilaya == null)
            return BadRequest(new { message = "Wilaya invalide" });

        var commune = await _context.Communes.FirstOrDefaultAsync(
            c => c.Id == dto.CommuneId && c.WilayaId == dto.WilayaId);
        if (commune == null)
            return BadRequest(new { message = "Commune invalide pour cette wilaya" });

        user.Name = dto.Name;
        user.Phone = dto.Phone;
        user.WilayaId = dto.WilayaId;
        user.CommuneId = dto.CommuneId;

        await _context.SaveChangesAsync();

        return Ok(MapToUserDto(user, wilaya.Name, commune.Name));
    }
    
    /// <summary>
    /// Send phone verification code (mocked — code logged to console)
    /// </summary>
    [HttpPost("send-verification")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult> SendVerificationCode([FromBody] SendVerificationDto dto)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            return Unauthorized();

        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        // Update phone number
        user.Phone = dto.Phone;
        user.PhoneVerified = false;
        
        await _context.SaveChangesAsync();
        
        // Send real SMS
        try
        {
            var success = await _smsService.SendVerificationCodeAsync(dto.Phone);
            if (!success)
            {
                return BadRequest(new { message = "Erreur lors de l'envoi du code SMS (unknown)." });
            }
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = $"Erreur Twilio: {ex.Message}" });
        }
        
        return Ok(new { message = "Code de vérification envoyé" });
    }
    
    /// <summary>
    /// Verify phone with code
    /// </summary>
    [HttpPost("verify-phone")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult> VerifyPhone([FromBody] VerifyPhoneDto dto)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            return Unauthorized();

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return NotFound();

        var isCodeValid = await _smsService.VerifyCodeAsync(user.Phone, dto.Code);
        if (!isCodeValid)
        {
            return BadRequest(new { message = "Code incorrect ou expiré" });
        }

        user.PhoneVerified = true;
        // Clean up our local fields if we still have them from legacy
        user.PhoneVerificationCode = null;
        user.PhoneVerificationExpiry = null;
        
        await _context.SaveChangesAsync();
        
        return Ok(MapToUserDto(user, user.Wilaya?.Name ?? "", user.Commune?.Name ?? ""));
    }
    
    /// <summary>
    /// Send email verification code (mocked — code logged to console)
    /// </summary>
    [HttpPost("send-email-verification")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult> SendEmailVerification([FromBody] SendEmailVerificationDto dto)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            return Unauthorized();

        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        if (user.Email.ToLower() != dto.Email.ToLower())
            return BadRequest(new { message = "L'email ne correspond pas à votre compte." });

        // Generate 6-digit code
        var code = new Random().Next(100000, 999999).ToString();
        user.EmailVerificationCode = code;
        user.EmailVerificationExpiry = DateTime.UtcNow.AddMinutes(15);
        user.EmailVerified = false;
        
        await _context.SaveChangesAsync();
        
        // MOCK: Log the code to console instead of sending real email
        Console.WriteLine($"[MOCK EMAIL] Verification code for {dto.Email}: {code}");
        
        return Ok(new { message = "Code de vérification envoyé sur votre email", mockCode = code });
    }
    
    /// <summary>
    /// Verify email with code
    /// </summary>
    [HttpPost("verify-email")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult> VerifyEmail([FromBody] VerifyEmailDto dto)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            return Unauthorized();

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return NotFound();

        if (user.Email.ToLower() != dto.Email.ToLower())
            return BadRequest(new { message = "L'email ne correspond pas à votre compte." });

        if (user.EmailVerificationCode != dto.Code)
            return BadRequest(new { message = "Code incorrect" });
        
        if (user.EmailVerificationExpiry < DateTime.UtcNow)
            return BadRequest(new { message = "Code expiré. Veuillez renvoyer un nouveau code." });

        user.EmailVerified = true;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        
        await _context.SaveChangesAsync();
        
        return Ok(MapToUserDto(user, user.Wilaya?.Name ?? "", user.Commune?.Name ?? ""));
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
            Role = user.Role.ToString(),
            PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified
        };
    }
}
