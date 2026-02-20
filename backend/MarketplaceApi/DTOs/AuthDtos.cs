using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

// Auth DTOs
public class RegisterDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [Phone]
    public string Phone { get; set; } = string.Empty;
    
    [Required]
    public int WilayaId { get; set; }
    
    [Required]
    public int CommuneId { get; set; }
}

public class LoginDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    public string Password { get; set; } = string.Empty;
}

public class SocialLoginDto
{
    [Required]
    public string Provider { get; set; } = string.Empty; // "Google" or "Facebook"
    
    [Required]
    public string AccessToken { get; set; } = string.Empty;
}

public class AuthResponseDto
{
    public string Token { get; set; } = string.Empty;
    public UserDto User { get; set; } = null!;
}

// User DTOs
public class UserDto
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public int WilayaId { get; set; }
    public int CommuneId { get; set; }
    public string WilayaName { get; set; } = string.Empty;
    public string CommuneName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}

public class UpdateProfileDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [Phone]
    public string Phone { get; set; } = string.Empty;
    
    [Required]
    public int WilayaId { get; set; }
    
    [Required]
    public int CommuneId { get; set; }
}
