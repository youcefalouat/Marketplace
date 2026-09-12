namespace MarketplaceApi.Models;

public class AppleAuthSettings
{
    public string TeamId { get; set; } = string.Empty;
    public string KeyId { get; set; } = string.Empty;
    public string BundleId { get; set; } = string.Empty;

    /// <summary>
    /// Base-64 encoded contents of the .p8 private key file (without PEM headers).
    /// Loaded from environment variable APPLE_PRIVATE_KEY.
    /// </summary>
    public string PrivateKey { get; set; } = string.Empty;
}
