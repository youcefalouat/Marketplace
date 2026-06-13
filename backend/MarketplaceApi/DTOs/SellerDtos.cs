namespace MarketplaceApi.DTOs;

public class SellerProfileDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string CommuneName { get; set; } = string.Empty;
    public string WilayaName { get; set; } = string.Empty;
    public bool IsVerifiedSeller { get; set; }
    public double? AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public int TotalAnnonces { get; set; }
    public DateTime MemberSince { get; set; }
}

public class SellerReviewDto
{
    public int ReviewerId { get; set; }
    public string ReviewerName { get; set; } = string.Empty;
    public string? ReviewerAvatarUrl { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TopVerifiedUserDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string CommuneName { get; set; } = string.Empty;
    public string WilayaName { get; set; } = string.Empty;
    public double? AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public int TotalAnnonces { get; set; }
    public bool IsVerifiedSeller { get; set; }
}

public class UserSearchResultDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public bool IsVerifiedSeller { get; set; }
    public string CommuneName { get; set; } = string.Empty;
    public string WilayaName { get; set; } = string.Empty;
    public double? AverageRating { get; set; }
}

public class AdminUserDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string CommuneName { get; set; } = string.Empty;
    public string WilayaName { get; set; } = string.Empty;
    public double? AverageRating { get; set; }
    public int TotalAnnonces { get; set; }
    public bool IsVerifiedSeller { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SetVerifiedSellerDto
{
    public bool IsVerifiedSeller { get; set; }
}
