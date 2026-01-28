using Microsoft.EntityFrameworkCore;
using MarketplaceApi.Models;

namespace MarketplaceApi.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
        : base(options)
    {
    }
    
    public DbSet<User> Users { get; set; }
    public DbSet<Annonce> Annonces { get; set; }
    public DbSet<AnnonceImage> AnnonceImages { get; set; }
    public DbSet<AdminNote> AdminNotes { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Role).HasConversion<int>();
        });
        
        // Annonce configuration
        modelBuilder.Entity<Annonce>(entity =>
        {
            entity.Property(e => e.Category).HasConversion<int>();
            entity.Property(e => e.State).HasConversion<int>();
            entity.Property(e => e.Status).HasConversion<int>();
            
            entity.HasOne(a => a.User)
                .WithMany(u => u.Annonces)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.Category);
            entity.HasIndex(e => e.CreatedAt);
        });
        
        // AnnonceImage configuration
        modelBuilder.Entity<AnnonceImage>(entity =>
        {
            entity.HasOne(i => i.Annonce)
                .WithMany(a => a.Images)
                .HasForeignKey(i => i.AnnonceId)
                .OnDelete(DeleteBehavior.Cascade);
        });
        
        // AdminNote configuration
        modelBuilder.Entity<AdminNote>(entity =>
        {
            entity.HasOne(n => n.Annonce)
                .WithMany(a => a.AdminNotes)
                .HasForeignKey(n => n.AnnonceId)
                .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasOne(n => n.Admin)
                .WithMany(u => u.AdminNotes)
                .HasForeignKey(n => n.AdminId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
