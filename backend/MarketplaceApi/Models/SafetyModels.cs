namespace MarketplaceApi.Models;

public class ModerationReport
{
    public int Id { get; set; }
    public int ReporterId { get; set; }
    public int? ReportedAnnonceId { get; set; }
    public int? ReportedUserId { get; set; }
    public string Type { get; set; } = "Listing";
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User Reporter { get; set; } = null!;
    public User? ReportedUser { get; set; }
    public Annonce? ReportedAnnonce { get; set; }
}

public class UserBlock
{
    public int Id { get; set; }
    public int BlockingUserId { get; set; }
    public int BlockedUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User BlockingUser { get; set; } = null!;
    public User BlockedUser { get; set; } = null!;
}
