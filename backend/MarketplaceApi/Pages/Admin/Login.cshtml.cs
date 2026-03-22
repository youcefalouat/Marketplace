using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.Models;

namespace MarketplaceApi.Pages.Admin;

[IgnoreAntiforgeryToken]
public class LoginModel : PageModel
{
    private readonly ApplicationDbContext _context;

    public LoginModel(ApplicationDbContext context)
    {
        _context = context;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public string ErrorMessage { get; set; } = string.Empty;

    public class InputModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;
    }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
            return Page();

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == Input.Email.ToLower());

        if (user == null || !BCrypt.Net.BCrypt.Verify(Input.Password, user.PasswordHash))
        {
            ErrorMessage = "Email ou mot de passe incorrect";
            return Page();
        }

        if (user.Role != UserRole.Admin)
        {
            ErrorMessage = "Accès non autorisé. Vous n'êtes pas administrateur.";
            return Page();
        }

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Name),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.ToString())
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme, 
            principal, 
            new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(1)
            });

        return Redirect("/admin");
    }
}
