using System.ComponentModel.DataAnnotations;

namespace MarketplaceApi.DTOs;

public class CreateListingReportDto
{
    [Required, MaxLength(100)]
    public string Reason { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Description { get; set; }
}

public class CreateBlockDto
{
    public int? AnnonceId { get; set; }
}

public class ModerationReportDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int ReporterId { get; set; }
    public string ReporterName { get; set; } = string.Empty;
    public int? ReportedUserId { get; set; }
    public string? ReportedUserName { get; set; }
    public int? ReportedAnnonceId { get; set; }
    public string? ReportedAnnonceTitle { get; set; }
}

public class UpdateModerationReportStatusDto
{
    [Required]
    public string Status { get; set; } = string.Empty;
}
