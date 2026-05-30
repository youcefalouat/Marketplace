namespace MarketplaceApi.Models;

public enum UserRole
{
    User = 0,
    Admin = 1
}



public enum ProductState
{
    New = 0,
    Used = 1
}

public enum AnnonceStatus
{
    Pending = 0,
    Approved = 1,
    Rejected = 2,
    UnderReview = 3,
    Sold = 4,
    Archived = 5,
    Deleted = 6
}
