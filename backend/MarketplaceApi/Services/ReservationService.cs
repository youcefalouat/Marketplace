using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;
using Microsoft.EntityFrameworkCore;

namespace MarketplaceApi.Services;

public interface IReservationService
{
    Task<CreateReservationResponseDto> CreateReservationAsync(int userId, int annonceId);
    Task<List<ReservationDto>> GetReservationsByAnnonceAsync(int annonceId);
    Task DeleteReservationAsync(int reservationId);
    Task UpdateRendezVousAsync(int reservationId, DateTime? rendezVous);
}

public class ReservationService : IReservationService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationService _notificationService;

    public ReservationService(ApplicationDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<CreateReservationResponseDto> CreateReservationAsync(int userId, int annonceId)
    {
        // Validation reads outside the strategy — fail fast before acquiring any lock.
        var annonce = await _context.Annonces
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == annonceId && !a.DeletedAt.HasValue);

        if (annonce == null)
            throw new InvalidOperationException("Annonce introuvable");

        if (!annonce.ReservationEnabled)
            throw new InvalidOperationException("Les réservations ne sont pas activées pour cette annonce");

        if (annonce.UserId == userId)
            throw new InvalidOperationException("Vous ne pouvez pas réserver votre propre annonce");

        var alreadyExists = await _context.Reservations
            .AsNoTracking()
            .AnyAsync(r => r.UserId == userId && r.AnnonceId == annonceId);

        if (alreadyExists)
            throw new InvalidOperationException("Vous avez déjà une réservation pour cette annonce");

        // Rank assignment must be atomic to prevent two concurrent reservations
        // receiving the same rank, so we keep it inside the transaction.
        var rank = 0;
        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            _context.ChangeTracker.Clear();
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var maxRank = await _context.Reservations
                .Where(r => r.AnnonceId == annonceId)
                .Select(r => (int?)r.Rank)
                .MaxAsync();

            rank = (maxRank ?? 0) + 1;

            _context.Reservations.Add(new Reservation
            {
                AnnonceId = annonceId,
                UserId = userId,
                Rank = rank,
                ReservationDateTime = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        });

        // Notify seller (fire-and-forget, best effort)
        _ = _notificationService.SendPushNotificationAsync(
            annonce.UserId,
            "Nouvelle réservation",
            $"Un utilisateur a réservé votre annonce : {annonce.Title}",
            new Dictionary<string, string>
            {
                { "type", "new_reservation" },
                { "annonceId", annonceId.ToString() }
            });

        return new CreateReservationResponseDto
        {
            Rank = rank,
            Message = $"Votre réservation a été enregistrée avec succès. Votre rang est : #{rank}"
        };
    }

    public async Task<List<ReservationDto>> GetReservationsByAnnonceAsync(int annonceId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Include(r => r.User)
            .Where(r => r.AnnonceId == annonceId)
            .OrderBy(r => r.Rank)
            .Select(r => new ReservationDto
            {
                Id = r.Id,
                Rank = r.Rank,
                UserName = r.User.Name,
                Phone = r.User.Phone ?? string.Empty,
                ReservationDateTime = r.ReservationDateTime,
                RendezVousDateTime = r.RendezVousDateTime
            })
            .ToListAsync();
    }

    public async Task DeleteReservationAsync(int reservationId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            _context.ChangeTracker.Clear();
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new InvalidOperationException("Réservation introuvable");

            var deletedRank = reservation.Rank;
            var annonceId = reservation.AnnonceId;

            _context.Reservations.Remove(reservation);
            await _context.SaveChangesAsync();

            var toReorder = await _context.Reservations
                .Where(r => r.AnnonceId == annonceId && r.Rank > deletedRank)
                .ToListAsync();

            foreach (var r in toReorder)
            {
                r.Rank--;
                r.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        });
    }

    public async Task UpdateRendezVousAsync(int reservationId, DateTime? rendezVous)
    {
        var reservation = await _context.Reservations
            .Include(r => r.Annonce)
            .FirstOrDefaultAsync(r => r.Id == reservationId);

        if (reservation == null)
            throw new InvalidOperationException("Réservation introuvable");

        reservation.RendezVousDateTime = rendezVous;
        reservation.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Notify the reserver if a rendez-vous date was set
        if (rendezVous.HasValue)
        {
            _ = _notificationService.SendPushNotificationAsync(
                reservation.UserId,
                "Rendez-vous confirmé",
                $"Un rendez-vous a été fixé pour votre réservation : {reservation.Annonce.Title}",
                new Dictionary<string, string>
                {
                    { "type", "rendez_vous_set" },
                    { "reservationId", reservationId.ToString() }
                });
        }
    }
}
