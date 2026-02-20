using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Data;
using MarketplaceApi.DTOs;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LocationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public LocationsController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    /// <summary>
    /// Get all wilayas
    /// </summary>
    [HttpGet("wilayas")]
    public async Task<ActionResult<List<WilayaDto>>> GetWilayas()
    {
        var wilayas = await _context.Wilayas
            .OrderBy(w => w.Code)
            .Select(w => new WilayaDto
            {
                Id = w.Id,
                Code = w.Code,
                Name = w.Name,
                ArName = w.ArName
            })
            .ToListAsync();
        
        return Ok(wilayas);
    }
    
    /// <summary>
    /// Get communes for a specific wilaya
    /// </summary>
    [HttpGet("wilayas/{wilayaId}/communes")]
    public async Task<ActionResult<List<CommuneDto>>> GetCommunes(int wilayaId)
    {
        var wilayaExists = await _context.Wilayas.AnyAsync(w => w.Id == wilayaId);
        if (!wilayaExists)
        {
            return NotFound(new { message = "Wilaya non trouvée" });
        }
        
        var communes = await _context.Communes
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
        
        return Ok(communes);
    }
}
