using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketplaceApi.Models;

public class Reservation
{
    public int Id { get; set; }

    [Required]
    public int AnnonceId { get; set; }

    [Required]
    public int UserId { get; set; }

    public int Rank { get; set; }

    public DateTime ReservationDateTime { get; set; } = DateTime.UtcNow;

    public DateTime? RendezVousDateTime { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey("AnnonceId")]
    public Annonce Annonce { get; set; } = null!;

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;
}
