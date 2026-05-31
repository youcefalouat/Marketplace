using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class CreateReservationDto
{
    [Required]
    public int AnnonceId { get; set; }
}

public class ReservationDto
{
    public int Id { get; set; }
    public int Rank { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public DateTime ReservationDateTime { get; set; }
    public DateTime? RendezVousDateTime { get; set; }
}

public class CreateReservationResponseDto
{
    public int Rank { get; set; }
    public string Message { get; set; } = string.Empty;
}

public class UpdateRendezVousDto
{
    public DateTime? RendezVousDateTime { get; set; }
}
