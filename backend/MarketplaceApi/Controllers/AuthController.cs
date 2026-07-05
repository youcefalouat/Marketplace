using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MarketplaceApi.Data;
using Microsoft.Extensions.Logging;
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
    private readonly IEmailService _emailService;
    private readonly IEmailVerificationService _emailVerificationService;
    private readonly IMemoryCache _cache;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        ApplicationDbContext context,
        ITokenService tokenService,
        ISmsService smsService,
        IEmailService emailService,
        IEmailVerificationService emailVerificationService,
        IMemoryCache cache,
        ILogger<AuthController> logger)
    {
        _context = context;
        _tokenService = tokenService;
        _smsService = smsService;
        _emailService = emailService;
        _emailVerificationService = emailVerificationService;
        _cache = cache;
        _logger = logger;
    }

    // ─── Helper to build AuthResponseDto ───

    private async Task<AuthResponseDto> BuildAuthResponse(User user)
    {
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
                EmailVerified = user.EmailVerified,
                AvatarUrl = user.AvatarUrl,
                IsVerifiedSeller = user.IsVerifiedSeller
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

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        var existing = await _context.Users
            .AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());
        if (existing)
            return BadRequest(new { message = "Un compte avec cet email existe déjà" });

        var wilaya = await _context.Wilayas.FindAsync(dto.WilayaId);
        if (wilaya == null)
            return BadRequest(new { message = "Wilaya invalide" });

        var commune = await _context.Communes
            .FirstOrDefaultAsync(c => c.Id == dto.CommuneId && c.WilayaId == dto.WilayaId);
        if (commune == null)
            return BadRequest(new { message = "Commune invalide pour cette wilaya" });

        var verificationToken = _emailVerificationService.GenerateToken();

        var user = new User
        {
            Email = dto.Email.Trim().ToLower(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Name = dto.Name.Trim(),
            Phone = dto.Phone.Trim(),
            WilayaId = dto.WilayaId,
            CommuneId = dto.CommuneId,
            Role = UserRole.User,
            CreatedAt = DateTime.UtcNow,
            EmailVerified = false,
            EmailVerificationCode = verificationToken,
            EmailVerificationExpiry = DateTime.UtcNow.AddHours(24)
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        user.Wilaya = wilaya;
        user.Commune = commune;

        // Send verification email (fire-and-forget — don't block registration)
        var verificationLink = _emailVerificationService.BuildVerificationLink(verificationToken, user.Email);
        _ = _emailService.SendEmailVerificationAsync(user.Email, user.Name, verificationLink)
            .ContinueWith(t => { }, TaskContinuationOptions.OnlyOnFaulted);

        var authResponse = await BuildAuthResponse(user);

        return Ok(new RegisterResultDto
        {
            Success = true,
            EmailVerificationRequired = true,
            Token = authResponse.Token,
            User = authResponse.User
        });
    }

    // ─── POST /api/auth/login ───

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

    [HttpPost("social-login")]
    public async Task<IActionResult> SocialLogin([FromBody] SocialLoginDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Données invalides" });

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u =>
                u.Provider == dto.Provider && u.ProviderId == dto.ProviderId);

        if (user == null)
        {
            user = await _context.Users
                .Include(u => u.Wilaya)
                .Include(u => u.Commune)
                .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower());

            if (user != null)
            {
                user.Provider = dto.Provider;
                user.ProviderId = dto.ProviderId;
                // Trust Google's email verification
                if (dto.Provider == "Google") user.EmailVerified = true;
                await _context.SaveChangesAsync();
            }
        }

        if (user == null)
        {
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
                // Google guarantees email ownership
                EmailVerified = dto.Provider == "Google",
                VerifiedAt = dto.Provider == "Google" ? DateTime.UtcNow : null,
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

        var user = await _context.Users
            .Include(u => u.Wilaya)
            .Include(u => u.Commune)
            .FirstOrDefaultAsync(u => u.Phone == dto.Phone);

        if (user == null)
        {
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
                EmailVerified = true, // Phone accounts don't require email verification
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            user.Wilaya = algerWilaya!;
            user.Commune = algerCommune!;
        }
        else
        {
            user.PhoneVerified = true;
            await _context.SaveChangesAsync();
        }

        if (user.IsDeleted)
            return Unauthorized(new { message = "Ce compte a été désactivé" });

        var response = await BuildAuthResponse(user);
        return Ok(response);
    }

    // ─── POST /api/auth/request-account-deletion ─── (authenticated)

    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("request-account-deletion")]
    public async Task<IActionResult> RequestAccountDeletion()
    {
        // Log incoming request authentication info for diagnostics
        try
        {
            var authType = User?.Identity?.AuthenticationType ?? "(none)";
            var isAuthenticated = User?.Identity?.IsAuthenticated ?? false;
            var nameId = User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            _logger?.LogInformation("RequestAccountDeletion called. AuthType={AuthType} IsAuthenticated={IsAuthenticated} NameId={NameId}", authType, isAuthenticated, nameId);
            foreach (var claim in User?.Claims ?? Enumerable.Empty<System.Security.Claims.Claim>())
            {
                _logger?.LogDebug("Claim: {Type} = {Value}", claim.Type, claim.Value);
            }
        }
        catch (Exception ex)
        {
            _logger?.LogWarning(ex, "Failed to log authentication info for RequestAccountDeletion");
        }

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var user = await _context.Users.FindAsync(userId.Value);
        if (user == null) return NotFound(new { message = "Utilisateur introuvable" });

        if (user.IsDeleted)
            return Ok(new { message = "Votre demande de suppression a déjà été traitée." });

        var anonymizedEmail = $"deleted-{user.Id}-{Guid.NewGuid():N}@deleted.local";

        user.IsDeleted = true;
        user.Email = anonymizedEmail;
        user.Name = "Compte supprimé";
        user.Phone = string.Empty;
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString());
        user.Provider = null;
        user.ProviderId = null;
        user.FcmToken = null;
        user.AvatarUrl = null;
        user.EmailVerified = false;
        user.PhoneVerified = false;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        user.PhoneVerificationCode = null;
        user.PhoneVerificationExpiry = null;
        user.VerifiedAt = null;
        user.Role = UserRole.User;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Votre demande de suppression a été prise en compte." });
    }

    // ─── POST /api/auth/send-verification ─── (authenticated, phone)

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

        // Rate limit: 1 per 60 seconds
        var rateLimitKey = $"email_resend_{user.Email}";
        if (_cache.TryGetValue(rateLimitKey, out _))
            return StatusCode(429, new { message = "Veuillez patienter 60 secondes avant de renvoyer un email." });

        var token = _emailVerificationService.GenerateToken();
        var link = _emailVerificationService.BuildVerificationLink(token, user.Email);

        user.EmailVerificationCode = token;
        user.EmailVerificationExpiry = DateTime.UtcNow.AddHours(24);
        await _context.SaveChangesAsync();

        _cache.Set(rateLimitKey, true, TimeSpan.FromSeconds(60));

        await _emailService.SendEmailVerificationAsync(user.Email, user.Name, link);

        return Ok(new { message = "Email de vérification envoyé", expiresAt = user.EmailVerificationExpiry });
    }

    // ─── POST /api/auth/resend-verification ─── (unauthenticated, rate-limited)

    [HttpPost("resend-verification")]
    [AllowAnonymous]
    public async Task<IActionResult> ResendVerification([FromBody] ResendVerificationDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(new { message = "Email invalide" });

        // Rate limit: 1 per 60 seconds per email
        var rateLimitKey = $"email_resend_{dto.Email.ToLower()}";
        if (_cache.TryGetValue(rateLimitKey, out _))
            return StatusCode(429, new { message = "Veuillez patienter 60 secondes avant de renvoyer un email." });

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.Email.ToLower() && !u.IsDeleted);

        // Return success even if user not found (prevent email enumeration)
        if (user == null || user.EmailVerified)
        {
            _cache.Set(rateLimitKey, true, TimeSpan.FromSeconds(60));
            return Ok(new { message = "Si un compte existe, un email de vérification a été envoyé." });
        }

        var token = _emailVerificationService.GenerateToken();
        var link = _emailVerificationService.BuildVerificationLink(token, user.Email);

        user.EmailVerificationCode = token;
        user.EmailVerificationExpiry = DateTime.UtcNow.AddHours(24);
        await _context.SaveChangesAsync();

        _cache.Set(rateLimitKey, true, TimeSpan.FromSeconds(60));

        _ = _emailService.SendEmailVerificationAsync(user.Email, user.Name, link)
            .ContinueWith(t => { }, TaskContinuationOptions.OnlyOnFaulted);

        return Ok(new { message = "Email de vérification envoyé." });
    }

    // ─── GET /verify-email ─── (web browser link from email)

    [HttpGet("/verify-email")]
    [AllowAnonymous]
    public async Task<ContentResult> VerifyEmailLink([FromQuery] string token, [FromQuery] string email)
    {
        if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(email))
            return Content(BuildEmailVerificationPage(false, "Lien invalide"), "text/html");

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email && !u.IsDeleted);
        if (user == null)
            return Content(BuildEmailVerificationPage(false, "Utilisateur introuvable"), "text/html");

        if (user.EmailVerified)
            return Content(BuildEmailVerificationPage(true, "Email déjà vérifié"), "text/html");

        if (user.EmailVerificationCode != token)
            return Content(BuildEmailVerificationPage(false, "Lien invalide ou déjà utilisé"), "text/html");

        if (user.EmailVerificationExpiry.HasValue && user.EmailVerificationExpiry < DateTime.UtcNow)
            return Content(BuildEmailVerificationPage(false, "Lien expiré. Veuillez en demander un nouveau depuis l'application."), "text/html");

        user.EmailVerified = true;
        user.VerifiedAt = DateTime.UtcNow;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        await _context.SaveChangesAsync();

        return Content(BuildEmailVerificationPage(true, "Votre adresse email a été vérifiée avec succès."), "text/html");
    }

    // ─── POST /api/auth/verify-email ─── (authenticated — kept for compatibility)

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
            return BadRequest(new { message = "Lien expiré. Veuillez en demander un nouveau." });

        user.EmailVerified = true;
        user.VerifiedAt = DateTime.UtcNow;
        user.EmailVerificationCode = null;
        user.EmailVerificationExpiry = null;
        await _context.SaveChangesAsync();

        return Ok(new UserDto
        {
            Id = user.Id, Email = user.Email, Name = user.Name,
            Phone = user.Phone, WilayaId = user.WilayaId, CommuneId = user.CommuneId,
            WilayaName = user.Wilaya?.Name ?? "", CommuneName = user.Commune?.Name ?? "",
            Role = user.Role.ToString(), PhoneVerified = user.PhoneVerified,
            EmailVerified = user.EmailVerified,
            AvatarUrl = user.AvatarUrl, IsVerifiedSeller = user.IsVerifiedSeller
        });
    }

    private static string BuildEmailVerificationPage(bool success, string message)
    {
        var color = success ? "#16a34a" : "#dc2626";
        var icon = success ? "✓" : "✗";
        var deepLinkScript = success
            ? """
              <script>
                // Attempt to open the app via deep link
                window.location.href = 'myapp://email-verified';
                // Fallback: show message if app is not installed
                setTimeout(function() {
                  document.getElementById('fallback').style.display = 'block';
                }, 2500);
              </script>
              """
            : "";

        return $"""
            <!DOCTYPE html>
            <html lang="fr">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width,initial-scale=1">
              <title>Vérification Email — Marketplace Controlée</title>
            </head>
            <body style="font-family:Arial,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:linear-gradient(135deg,#f0f4ff,#e8f5e9);">
              <div style="background:#fff;border-radius:16px;padding:40px 32px;max-width:420px;width:90%;text-align:center;box-shadow:0 8px 32px rgba(0,0,0,.12);">
                <div style="font-size:56px;color:{color};margin-bottom:16px;">{icon}</div>
                <h2 style="color:{color};margin:0 0 12px;font-size:22px;">{(success ? "Vérification réussie" : "Erreur")}</h2>
                <p style="color:#555;margin:0 0 24px;font-size:15px;">{System.Net.WebUtility.HtmlEncode(message)}</p>
                {(success ? """
                <p style="color:#777;font-size:13px;" id="redirect-msg">Redirection vers l'application...</p>
                <div id="fallback" style="display:none;margin-top:16px;">
                  <p style="color:#999;font-size:13px;">Si l'application ne s'ouvre pas automatiquement :</p>
                  <p style="color:#555;font-size:14px;font-weight:bold;">Vous pouvez fermer cette page et ouvrir l'application manuellement.</p>
                </div>
                """ : "")}
                <p style="color:#bbb;font-size:11px;margin-top:32px;">© Marketplace Controlée</p>
              </div>
              {deepLinkScript}
            </body>
            </html>
            """;
    }
}
