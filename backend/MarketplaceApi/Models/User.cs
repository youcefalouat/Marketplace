using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class User
{
    public int Id { get; set; }
    
    [Required]
    [EmailAddress]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    public string PasswordHash { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [Phone]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
    
    [Required]
    public int WilayaId { get; set; }
    
    [Required]
    public int CommuneId { get; set; }
    
    public UserRole Role { get; set; } = UserRole.User;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public Wilaya Wilaya { get; set; } = null!;
    public Commune Commune { get; set; } = null!;
    public ICollection<Annonce> Annonces { get; set; } = new List<Annonce>();
    public ICollection<AdminNote> AdminNotes { get; set; } = new List<AdminNote>();
}
