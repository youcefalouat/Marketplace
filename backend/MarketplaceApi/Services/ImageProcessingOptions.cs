namespace MarketplaceApi.Services;

public class ImageProcessingOptions
{
    public long MaxFileSizeBytes { get; set; } = 10 * 1024 * 1024; // 10 MB
    public int MaxWidth { get; set; } = 1200;
    public int WebPQuality { get; set; } = 80;
    public int[] ThumbnailSizes { get; set; } = [150, 300];
    public int MaxDimension { get; set; } = 8000; // Image bomb protection
    public string[] AllowedMimeTypes { get; set; } =
        ["image/jpeg", "image/png", "image/webp", "image/gif"];
}
