using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
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

    public AuthController(
        ApplicationDbContext context,
        ITokenService tokenService,
        ISmsService smsService)
    {
        _context = context;
        _tokenService = tokenService;
        _smsService = smsService;
    }

    // ─── Helper to build AuthResponseDto ───

    private async Task<AuthResponseDto> BuildAuthResponse(User user)
    {
        // Ensure navigation properties are loaded
        if (user.Wilaya == null || user.Commune == null)
        {
            await _context.Entry(user).Reference(u => u.Wilaya).LoadAsync();
            await _context.Entry(user).Reference(u => u.Commune).LoadAsync();
        }

        var token = _tokenService.GenerateToken(user);
        return new AuthResponseDto
        {
            Token = token,
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                Name = user.Name,
                Phone = user.Phone,
                WilayaId = user.WilayaId,
                CommuneId = user.CommuneId,
                WilayaName = user.Wilaya?.Name ?? "",
                CommuneName = user.Commune?.Name ?? "",
                Role = user.Role.ToString(),
                PhoneVerified = user.PhoneVerified,
                EmailVerified = user.EmailVerified
            }
        };
    }

    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return null;
        return userId;
    }

    // ─── POST /api/auth/register ───

    /// <summary>
    /// Register a new user account.
    /// </summary>
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        // Check for existing email
        var existing = await _context.Users
            .AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        if (existing)
            return BadRequest(new { message = "Un compte avec cet email existe déjà" });

        // Validate wilaya/commune
        var wilaya = await _context.Wilayas.FindAsync(dto.WilayaId);
        if (wilaya == null)
            return BadRequest(new { message = "Wilaya invalide" });

        var commune = await _context.Communes
            .FirstOrDefaultAsync(c => c.Id == dto.CommuneId && c.WilayaId == dto.WilayaId);
        if (commune == null)
            return BadRequest(new { message = "Commune invalide pour cette wilaya" });

        var user = new User
        {
            Email = dto.Email.Trim().ToLower(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Name = dto.Name.Trim(),
            Phone = dto.Phone.Trim(),
            WilayaId = dto.WilayaId,
            CommuneId = dto.CommuneId,
            Role = UserRole.User,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // Reload with navigation properties
        user.Wilaya = wilaya;
        user.Commune = commune;

        var response = await BuildAuthResponse(user);
        return Ok(response);
    }

    // ─── POST /api/auth/login ───

    /// <summary>
    /// Login with email and password.
    /// </summary>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower());

        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            return Unauthorized(new { message = "Email ou mot de passe incorrect" });

        if (user.IsDeleted)
            return Unauthorized(new { message = "Ce compte a été désactivé" });

        var response = await BuildAuthResponse(user);
        return Ok(response);
    }

    // ─── POST /api/auth/social-login ───

    /// <summary>
    /// Login or register via social provider (Google).
    /// </summary>
    [HttpPost("social-login")]
    public async Task<IActionResult> SocialLogin([FromBody] SocialLoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        // Try to find existing user by provider
        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u =>
                u.Provider == dto.Provider && u.ProviderId == dto.ProviderId);

        // If not found by provider, check by email
        if (user == null)
        {
            user = await _context.Users
                .Include(u => u.Wilaya)
                .Include(u => u.Commune)
                .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower());

            if (user != null)
            {
                // Link provider to existing account
                user.Provider = dto.Provider;
                user.ProviderId = dto.ProviderId;
                await _context.SaveChangesAsync();
            }
        }

        // If still not found, create new user
        if (user == null)
        {
            // Use Alger as default location for social-created accounts
            var algerWilaya = await _context.Wilayas.FirstOrDefaultAsync(w => w.Code == "16");
            var algerCommune = algerWilaya != null
                ? await _context.Communes.FirstOrDefaultAsync(c => c.WilayaId == algerWilaya.Id)
                : null;

            user = new User
            {
                Email = dto.Email.Trim().ToLower(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()),
                Name = dto.Name.Trim(),
                Phone = "",
                WilayaId = algerWilaya?.Id ?? 1,
                CommuneId = algerCommune?.Id ?? 1,
                Role = UserRole.User,
                Provider = dto.Provider,
                ProviderId = dto.ProviderId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            user.Wilaya = algerWilaya!;
            user.Commune = algerCommune!;
        }

        if (user.IsDeleted)
            return Unauthorized(new { message = "Ce compte a été désactivé" });

        var response = await BuildAuthResponse(user);
        return Ok(response);
    }

    // ─── POST /api/auth/phone-login-request ───

    /// <summary>
    /// Request OTP for phone-based login/registration (unauthenticated).
    /// </summary>
    [HttpPost("phone-login-request")]
    public async Task<IActionResult> PhoneLoginRequest([FromBody] PhoneLoginRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Numéro de téléphone invalide" });

        try
        {
            var success = await _smsService.SendVerificationCodeAsync(dto.Phone);
            if (!success)
                return BadRequest(new { message = "Erreur lors de l'envoi du code" });

            return Ok(new { message = "Code envoyé" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ─── POST /api/auth/phone-login-verify ───

    /// <summary>
    /// Verify phone OTP and login (or auto-register).
    /// </summary>
    [HttpPost("phone-login-verify")]
    public async Task<IActionResult> PhoneLoginVerify([FromBody] PhoneLoginVerifyDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        try
        {
            var verified = await _smsService.VerifyCodeAsync(dto.Phone, dto.Code);
            if (!verified)
                return BadRequest(new { message = "Code invalide ou expiré" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        // Find or create user by phone
        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Phone == dto.Phone);

        if (user == null)
        {
            // Auto-register
            var algerWilaya = await _context.Wilayas.FirstOrDefaultAsync(w => w.Code == "16");
            var algerCommune = algerWilaya != null
                ? await _context.Communes.FirstOrDefaultAsync(c => c.WilayaId == algerWilaya.Id)
                : null;

            user = new User
            {
                Email = $"{dto.Phone}@phone.local",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()),
                Name = "Utilisateur",
                Phone = dto.Phone,
                WilayaId = algerWilaya?.Id ?? 1,
                CommuneId = algerCommune?.Id ?? 1,
                Role = UserRole.User,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            user.Wilaya = algerWilaya!;
            user.Commune = algerCommune!;
        }
        else
        {
            // Mark phone as verified
            user.PhoneVerified = true;
            await _context.SaveChangesAsync();
        }

        if (user.IsDeleted)
            return Unauthorized(new { message = "Ce compte a été désactivé" });

        var response = await BuildAuthResponse(user);
        return Ok(response);
    }

    // ─── POST /api/auth/send-verification ─── (authenticated, for phone verification)

    /// <summary>
    /// Send a verification code to the user's phone (authenticated).
    /// </summary>
    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("send-verification")]
    public async Task<IActionResult> SendVerification([FromBody] SendVerificationDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Numéro invalide" });

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new { message = "Utilisateur introuvable" });

        try
        {
            var success = await _smsService.SendVerificationCodeAsync(dto.Phone);
            if (!success)
                return BadRequest(new { message = "Erreur lors de l'envoi du code" });

            // Store the phone being verified
            user.Phone = dto.Phone;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Code envoyé" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ─── POST /api/auth/verify-phone ─── (authenticated)

    /// <summary>
    /// Verify phone with code (authenticated).
    /// </summary>
    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("verify-phone")]
    public async Task<IActionResult> VerifyPhone([FromBody] VerifyPhoneDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Code invalide" });

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId.Value);

        if (user == null) return NotFound(new { message = "Utilisateur introuvable" });

        try
        {
            var verified = await _smsService.VerifyCodeAsync(user.Phone, dto.Code);
            if (!verified)
                return BadRequest(new { message = "Code invalide ou expiré" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        user.PhoneVerified = true;
        user.PhoneVerificationCode = null;
        user.PhoneVerificationExpiry = null;
        await _context.SaveChangesAsync();

        return Ok(new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Phone = user.Phone,
            WilayaId = user.WilayaId,
            CommuneId = user.CommuneId,
            WilayaName = user.Wilaya?.Name ?? "",
            CommuneName = user.Commune?.Name ?? "",
            Role = user.Role.ToString(),
            PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified
        });
    }

    // ─── POST /api/auth/send-email-verification ─── (authenticated)

    /// <summary>
    /// Send email verification code (authenticated).
    /// </summary>
    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("send-email-verification")]
    public async Task<IActionResult> SendEmailVerification([FromBody] SendEmailVerificationDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Email invalide" });

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new { message = "Utilisateur introuvable" });

        if (user.EmailVerified)
            return BadRequest(new { message = "L'email est déjà vérifié" });

        // Generate a 6-digit code
        var code = new Random().Next(100000, 999999).ToString();
        user.EmailVerificationCode = code;
        user.EmailVerificationExpiry = DateTime.UtcNow.AddMinutes(15);
        await _context.SaveChangesAsync();

        // In production, send email here. For dev, log it.
        Console.WriteLine($"[EMAIL VERIFICATION] Code for {user.Email}: {code}");

        return Ok(new { message = "Code de vérification envoyé", code }); // code returned for dev convenience
    }

    // ─── POST /api/auth/verify-email ─── (authenticated)

    /// <summary>
    /// Verify email with code (authenticated).
    /// </summary>
    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Id == userId.Value);

        if (user == null) return NotFound(new { message = "Utilisateur introuvable" });

        if (user.EmailVerificationCode != dto.Code)
            return BadRequest(new { message = "Code invalide" });

        if (user.EmailVerificationExpiry.HasValue && user.EmailVerificationExpiry < DateTime.UtcNow)
            return BadRequest(new { message = "Code expiré. Veuillez en demander un nouveau." });

        user.EmailVerified = true;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        await _context.SaveChangesAsync();

        return Ok(new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Name = user.Name,
            Phone = user.Phone,
            WilayaId = user.WilayaId,
            CommuneId = user.CommuneId,
            WilayaName = user.Wilaya?.Name ?? "",
            CommuneName = user.Commune?.Name ?? "",
            Role = user.Role.ToString(),
            PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified
        });
    }
}
