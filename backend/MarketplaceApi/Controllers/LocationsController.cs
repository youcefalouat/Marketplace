using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LocationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMemoryCache _cache;
    
    public LocationsController(ApplicationDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache = cache;
    }
    
    /// <summary>
    /// Get all wilayas
    /// </summary>
    [HttpGet("wilayas")]
    public async Task<ActionResult<List<WilayaDto>>> GetWilayas()
    {
        // Fix #17: Cache wilayas for 6 hours (static reference data)
        var wilayas = await _cache.GetOrCreateAsync("wilayas_all", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            return await _context.Wilayas
                .AsNoTracking()
                .OrderBy(w => w.Code)
                .Select(w => new WilayaDto
                {
                    Id = w.Id,
                    Code = w.Code,
                    Name = w.Name,
                    ArName = w.ArName
                })
                .ToListAsync();
        });
        
        return Ok(wilayas);
    }
    
    /// <summary>
    /// Get communes for a specific wilaya
    /// </summary>
    [HttpGet("wilayas/{wilayaId}/communes")]
    public async Task<ActionResult<List<CommuneDto>>> GetCommunes(int wilayaId)
    {
        // Fix #17: Cache communes per wilaya for 6 hours
        var cacheKey = $"communes_wilaya_{wilayaId}";
        var communes = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            var wilayaExists = await _context.Wilayas.AnyAsync(w => w.Id == wilayaId);
            if (!wilayaExists)
            {
                return null; // Signal not found
            }
            
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            return await _context.Communes
                .AsNoTracking()
                .Where(c => c.WilayaId == wilayaId)
                .OrderBy(c => c.Name)
                .Select(c => new CommuneDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    ArName = c.ArName,
                    WilayaId = c.WilayaId
                })
                .ToListAsync();
        });
        
        if (communes == null)
        {
            return NotFound(new { message = "Wilaya non trouvée" });
        }
        
        return Ok(communes);
    }
}
