using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.Models;

namespace MarketplaceApi.Services;

public record SellerRatingAggregate(int SellerId, double AverageRating, int RatingCount);

public interface IRatingService
{
    Task<Dictionary<int, SellerRatingAggregate>> GetSellerSummariesAsync(IEnumerable<int> sellerIds);
    Task<SellerRatingAggregate?> GetSellerSummaryAsync(int sellerId);
    Task<UserRating> CreateOrUpdateRatingAsync(int raterId, int sellerId, int rating, string? comment);
}

public class RatingService : IRatingService
{
    private readonly ApplicationDbContext _context;

    public RatingService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Dictionary<int, SellerRatingAggregate>> GetSellerSummariesAsync(IEnumerable<int> sellerIds)
    {
        var ids = sellerIds.Distinct().ToList();
        if (ids.Count == 0) return new Dictionary<int, SellerRatingAggregate>();

        return await _context.UserRatings
            .Where(r => ids.Contains(r.SellerId))
            .GroupBy(r => r.SellerId)
            .Select(g => new SellerRatingAggregate(
                g.Key,
                g.Average(x => (double)x.Rating),
                g.Count()))
            .ToDictionaryAsync(x => x.SellerId);
    }

    public async Task<SellerRatingAggregate?> GetSellerSummaryAsync(int sellerId)
    {
        return await _context.UserRatings
            .Where(r => r.SellerId == sellerId)
            .GroupBy(r => r.SellerId)
            .Select(g => new SellerRatingAggregate(
                g.Key,
                g.Average(x => (double)x.Rating),
                g.Count()))
            .FirstOrDefaultAsync();
    }

    public async Task<UserRating> CreateOrUpdateRatingAsync(int raterId, int sellerId, int rating, string? comment)
    {
        var existing = await _context.UserRatings
            .FirstOrDefaultAsync(r => r.SellerId == sellerId && r.RaterId == raterId);

        if (existing != null)
        {
            existing.Rating = rating;
            existing.Comment = comment;
            // Keep CreatedAt as initial rating timestamp
            await _context.SaveChangesAsync();
            return existing;
        }

        var entity = new UserRating
        {
            SellerId = sellerId,
            RaterId = raterId,
            Rating = rating,
            Comment = comment,
            CreatedAt = DateTime.UtcNow
        };

        _context.UserRatings.Add(entity);
        await _context.SaveChangesAsync();
        return entity;
    }
}

