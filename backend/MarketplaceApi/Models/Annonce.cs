using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketplaceApi.Models;

public class Annonce
{
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }
    
    [Required]
    public Category Category { get; set; }
    
    [Required]
    public ProductState State { get; set; }
    
    [Required]
    [Phone]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
    
    [Required]
    public int WilayaId { get; set; }
    
    [Required]
    public int CommuneId { get; set; }
    
    public bool IsExchange { get; set; } = false;
    
    public bool ShowPhone { get; set; } = true;
    
    public AnnonceStatus Status { get; set; } = AnnonceStatus.Pending;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Admin internal fields
    [Column(TypeName = "decimal(18,2)")]
    public decimal? StorePriceEstimate { get; set; }
    
    public bool IsGoodDeal { get; set; } = false;
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Wilaya Wilaya { get; set; } = null!;
    public Commune Commune { get; set; } = null!;
    public ICollection<AnnonceImage> Images { get; set; } = new List<AnnonceImage>();
    public ICollection<AdminNote> AdminNotes { get; set; } = new List<AdminNote>();
}
