using MarketplaceApi.Models;

namespace MarketplaceApi.Data;

public static class CategorySeedData
{
    public static void SeedCategories(ApplicationDbContext db)
    {
        if (!db.Categories.Any())
        {
            var electro = new Category { Name = "Électroménager", ArName = "الأجهزة المنزلية", Slug = "electromenager", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var meubles = new Category { Name = "Meubles", ArName = "أثاث", Slug = "meubles", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var literie = new Category { Name = "Literie", ArName = "مفروشات", Slug = "literie", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var deco = new Category { Name = "Décoration", ArName = "ديكور", Slug = "decoration", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            
            db.Categories.AddRange(electro, meubles, literie, deco);
            db.SaveChanges();
            
            // Add some subcategories for demonstration
            var grosElectro = new Category { Name = "Gros Électroménager", ArName = "أجهزة منزلية كبيرة", Slug = "gros-electromenager", ParentId = electro.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var petitElectro = new Category { Name = "Petit Électroménager", ArName = "أجهزة منزلية صغيرة", Slug = "petit-electromenager", ParentId = electro.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            
            var salon = new Category { Name = "Salon", ArName = "غرفة المعيشة", Slug = "salon", ParentId = meubles.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            var chambre = new Category { Name = "Chambre", ArName = "غرفة النوم", Slug = "chambre", ParentId = meubles.Id, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };
            
            db.Categories.AddRange(grosElectro, petitElectro, salon, chambre);
            db.SaveChanges();
        }
    }
}
