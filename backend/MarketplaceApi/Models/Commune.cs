using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.Models;

public class Commune
{
    public int Id { get; set; }
    [Required]
    [MaxLength(10)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string ArName { get; set; } = string.Empty;
    
    [Required]
    public int WilayaId { get; set; }
    
    // Navigation properties
    public Wilaya Wilaya { get; set; } = null!;
}
