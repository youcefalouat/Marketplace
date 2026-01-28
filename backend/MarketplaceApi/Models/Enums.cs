namespace MarketplaceApi.Models;

public enum UserRole
{
    User = 0,
    Admin = 1
}

public enum Category
{
    Electromenager = 0,
    Meubles = 1,
    Literie = 2,
    Decoration = 3
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
    Rejected = 2
}
