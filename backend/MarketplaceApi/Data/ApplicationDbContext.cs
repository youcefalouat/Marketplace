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
    public DbSet<Category> Categories { get; set; }
    public DbSet<Annonce> Annonces { get; set; }
    public DbSet<AnnonceImage> AnnonceImages { get; set; }
    public DbSet<AdminNote> AdminNotes { get; set; }
    public DbSet<Wilaya> Wilayas { get; set; }
    public DbSet<Commune> Communes { get; set; }
    public DbSet<Conversation> Conversations { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<UserRating> UserRatings { get; set; }
    public DbSet<ModerationThread> ModerationThreads { get; set; }
    public DbSet<ModerationMessage> ModerationMessages { get; set; }
    public DbSet<Reservation> Reservations { get; set; }

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
            entity.HasIndex(e => e.CategoryId);
            entity.HasIndex(e => e.CreatedAt);
            entity.HasIndex(e => e.IsPromoted);
        });

        // Category configuration
        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasIndex(e => e.Slug).IsUnique();
            entity.Property(e => e.ArName).HasMaxLength(255);

            entity.HasOne(c => c.Parent)
                .WithMany(c => c.SubCategories)
                .HasForeignKey(c => c.ParentId)
                .OnDelete(DeleteBehavior.Restrict);
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
            entity.HasIndex(e => e.LastMessageAt);
            entity.HasIndex(e => new { e.BuyerId, e.LastMessageAt });
            entity.HasIndex(e => new { e.SellerId, e.LastMessageAt });
            entity.HasIndex(e => new { e.AnnonceId, e.BuyerId, e.SellerId, e.IsModeration });

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
            entity.HasIndex(e => new { e.ConversationId, e.SentAt });
            entity.HasIndex(e => new { e.ReceiverId, e.IsRead });

            entity.HasOne(m => m.Conversation)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(m => m.Receiver)
                .WithMany()
                .HasForeignKey(m => m.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // UserRating configuration
        modelBuilder.Entity<UserRating>(entity =>
        {
            entity.HasIndex(r => new { r.SellerId, r.RaterId }).IsUnique();

            entity.HasOne(r => r.Seller)
                .WithMany(u => u.ReceivedRatings)
                .HasForeignKey(r => r.SellerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Rater)
                .WithMany()
                .HasForeignKey(r => r.RaterId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Moderation configuration (models added separately)
        modelBuilder.Entity<ModerationThread>(entity =>
        {
            entity.HasOne(t => t.Annonce)
                .WithMany()
                .HasForeignKey(t => t.AnnonceId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(t => t.Owner)
                .WithMany()
                .HasForeignKey(t => t.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(t => t.AnnonceId).IsUnique();
        });

        modelBuilder.Entity<ModerationMessage>(entity =>
        {
            entity.HasOne(m => m.Thread)
                .WithMany(t => t.Messages)
                .HasForeignKey(m => m.ThreadId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(m => m.ThreadId);
            entity.HasIndex(m => m.SentAt);
        });

        // Reservation configuration
        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.HasIndex(r => new { r.UserId, r.AnnonceId }).IsUnique();
            entity.HasIndex(r => new { r.AnnonceId, r.Rank });

            entity.HasOne(r => r.Annonce)
                .WithMany(a => a.Reservations)
                .HasForeignKey(r => r.AnnonceId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
