using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;
using MarketplaceApi.Models;

namespace MarketplaceApi.Services;

public interface IAnnonceFeedService
{
    Task<List<AnnonceListDto>> GetFeaturedAnnoncesAsync(int? count);
}

public class AnnonceFeedService : IAnnonceFeedService
{
    private readonly ApplicationDbContext _context;
    private readonly IRatingService _ratingService;
    private readonly FeaturedFeedOptions _options;

    public AnnonceFeedService(ApplicationDbContext context, IRatingService ratingService, IOptions<FeaturedFeedOptions> options)
    {
        _context = context;
        _ratingService = ratingService;
        _options = options.Value ?? new FeaturedFeedOptions();
    }

    public async Task<List<AnnonceListDto>> GetFeaturedAnnoncesAsync(int? count)
    {
        var targetCount = count ?? _options.DefaultCount;
        targetCount = Math.Clamp(targetCount, 1, Math.Max(1, _options.MaxCount));

        // Future-proofing: allow "promoted" to be inserted first.
        var promoted = await GetPromotedAnnoncesAsync(targetCount);
        if (promoted.Count >= targetCount) return promoted.Take(targetCount).ToList();

        var remaining = targetCount - promoted.Count;
        var promotedIds = promoted.Select(a => a.Id).ToHashSet();

        var baseQuery = _context.Annonces
            .AsNoTracking()
            .Include(a => a.Images)
            .Include(a => a.Wilaya)
            .Include(a => a.Commune)
            .Include(a => a.Category)
            .Where(a => a.Status == AnnonceStatus.Approved);

        var randomRaw = await baseQuery
            .Where(a => !promotedIds.Contains(a.Id))
            .OrderBy(_ => Guid.NewGuid())
            .Take(remaining)
            .Select(a => new
            {
                a.Id,
                a.Title,
                a.Price,
                WilayaName = a.Wilaya.Name,
                CommuneName = a.Commune.Name,
                Category = a.Category.Name,
                MainImageUrl = a.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImagePath).FirstOrDefault(),
                a.IsExchange,
                a.IsGoodDeal,
                SellerId = a.UserId,
                a.CreatedAt
            })
            .ToListAsync();

        var sellerSummaries = await _ratingService.GetSellerSummariesAsync(randomRaw.Select(x => x.SellerId));

        var randomDtos = randomRaw.Select(a =>
        {
            double? avg = null;
            int? ratingCount = null;
            if (sellerSummaries.TryGetValue(a.SellerId, out var summary) && summary.RatingCount > 0)
            {
                avg = summary.AverageRating;
                ratingCount = summary.RatingCount;
            }

            return new AnnonceListDto
            {
                Id = a.Id,
                Title = a.Title,
                Price = a.Price,
                WilayaName = a.WilayaName,
                CommuneName = a.CommuneName,
                Category = a.Category,
                MainImageUrl = a.MainImageUrl,
                IsExchange = a.IsExchange,
                IsGoodDeal = a.IsGoodDeal,
                SellerAverageRating = avg,
                SellerRatingCount = ratingCount,
                CreatedAt = a.CreatedAt
            };
        }).ToList();

        promoted.AddRange(randomDtos);
        return promoted;
    }

    private Task<List<AnnonceListDto>> GetPromotedAnnoncesAsync(int count)
    {
        // Placeholder for future "promoted annonces first" logic.
        return Task.FromResult(new List<AnnonceListDto>());
    }
}

