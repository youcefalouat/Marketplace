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
    public DbSet<Wilaya> Wilayas { get; set; }
    public DbSet<Commune> Communes { get; set; }
    public DbSet<Conversation> Conversations { get; set; }
    public DbSet<Message> Messages { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Wilaya configuration
        modelBuilder.Entity<Wilaya>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
        });
        
        // Commune configuration
        modelBuilder.Entity<Commune>(entity =>
        {
            entity.HasOne(c => c.Wilaya)
                .WithMany(w => w.Communes)
                .HasForeignKey(c => c.WilayaId)
                .OnDelete(DeleteBehavior.Cascade);
        });
        
        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Role).HasConversion<int>();
            
            entity.HasOne(u => u.Wilaya)
                .WithMany()
                .HasForeignKey(u => u.WilayaId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(u => u.Commune)
                .WithMany()
                .HasForeignKey(u => u.CommuneId)
                .OnDelete(DeleteBehavior.Restrict);
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
            
            entity.HasOne(a => a.Wilaya)
                .WithMany()
                .HasForeignKey(a => a.WilayaId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(a => a.Commune)
                .WithMany()
                .HasForeignKey(a => a.CommuneId)
                .OnDelete(DeleteBehavior.Restrict);
            
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

        // Conversation configuration
        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasOne(c => c.Annonce)
                .WithMany()
                .HasForeignKey(c => c.AnnonceId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(c => c.Buyer)
                .WithMany()
                .HasForeignKey(c => c.BuyerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(c => c.Seller)
                .WithMany()
                .HasForeignKey(c => c.SellerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Message configuration
        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasOne(m => m.Conversation)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
