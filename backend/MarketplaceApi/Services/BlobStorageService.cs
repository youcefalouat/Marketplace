using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace MarketplaceApi.Services;

/// <summary>
/// Result of storing a processed image (main + thumbnails).
/// All paths are relative URLs suitable for database storage.
/// </summary>
public class ImageStorageResult
{
    public string ImagePath { get; init; } = string.Empty;
    public string ThumbnailSmallPath { get; init; } = string.Empty;
    public string ThumbnailMediumPath { get; init; } = string.Empty;
}

public interface IBlobStorageService
{
    /// <summary>
    /// Stores an already-processed image (main + thumbnails) to local or Azure Blob storage.
    /// </summary>
    Task<ImageStorageResult> StoreProcessedImageAsync(ImageProcessingResult result);

    /// <summary>
    /// Deletes a single image by its relative path.
    /// </summary>
    Task DeleteImageAsync(string? imagePath);

    /// <summary>
    /// Deletes an image and its associated thumbnails.
    /// </summary>
    Task DeleteImageWithThumbnailsAsync(string? imagePath, string? thumbSmallPath, string? thumbMediumPath);
}

public class BlobStorageService : IBlobStorageService
{
    private readonly BlobServiceClient? _blobServiceClient;
    private readonly ILogger<BlobStorageService> _logger;
    private readonly string _webRootPath;

    public BlobStorageService(
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<BlobStorageService> logger)
    {
        var connectionString = configuration["AzureStorage:ConnectionString"];
        _logger = logger;
        _webRootPath = string.IsNullOrWhiteSpace(environment.WebRootPath)
            ? Path.Combine(environment.ContentRootPath, "wwwroot")
            : environment.WebRootPath;

        Directory.CreateDirectory(_webRootPath);

        if (!string.IsNullOrWhiteSpace(connectionString))
        {
            _blobServiceClient = new BlobServiceClient(connectionString);
        }
    }

    private bool IsLocalMode => _blobServiceClient == null;

    public async Task<ImageStorageResult> StoreProcessedImageAsync(ImageProcessingResult result)
    {
        var now = DateTime.UtcNow;
        var basePath = $"images/{now:yyyy}/{now:MM}";
        var hash = result.ContentHash;

        var mainFileName = $"{hash}.webp";
        var thumbSmallFileName = $"{hash}_150.webp";
        var thumbMediumFileName = $"{hash}_300.webp";

        if (IsLocalMode)
        {
            return await StoreLocallyAsync(result, basePath, mainFileName, thumbSmallFileName, thumbMediumFileName);
        }

        return await StoreToBlobAsync(result, basePath, mainFileName, thumbSmallFileName, thumbMediumFileName);
    }

    public async Task DeleteImageAsync(string? imagePath)
    {
        if (string.IsNullOrEmpty(imagePath)) return;

        if (IsLocalMode)
        {
            DeleteLocalFile(imagePath);
            return;
        }

        await DeleteBlobAsync(imagePath);
    }

    public async Task DeleteImageWithThumbnailsAsync(string? imagePath, string? thumbSmallPath, string? thumbMediumPath)
    {
        // Fix #16: Run deletes in parallel instead of sequentially
        await Task.WhenAll(
            DeleteImageAsync(imagePath),
            DeleteImageAsync(thumbSmallPath),
            DeleteImageAsync(thumbMediumPath)
        );
    }

    // ──────────────────────── Local Storage ────────────────────────

    private async Task<ImageStorageResult> StoreLocallyAsync(
        ImageProcessingResult result,
        string basePath,
        string mainFileName,
        string thumbSmallFileName,
        string thumbMediumFileName)
    {
        // Main image
        var mainDir = Path.Combine(_webRootPath, basePath.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(mainDir);
        var mainFilePath = Path.Combine(mainDir, mainFileName);
        await WriteStreamToFileAsync(result.OptimizedImage, mainFilePath);

        // Thumbnails
        var thumbDir = Path.Combine(mainDir, "thumbs");
        Directory.CreateDirectory(thumbDir);

        var thumbSmallPath = Path.Combine(thumbDir, thumbSmallFileName);
        await WriteStreamToFileAsync(result.ThumbnailSmall, thumbSmallPath);

        var thumbMediumPath = Path.Combine(thumbDir, thumbMediumFileName);
        await WriteStreamToFileAsync(result.ThumbnailMedium, thumbMediumPath);

        _logger.LogInformation(
            "Image stored locally: {Path} ({SizeKB}KB)",
            mainFilePath, result.OptimizedSize / 1024);

        return new ImageStorageResult
        {
            ImagePath = $"/{basePath}/{mainFileName}",
            ThumbnailSmallPath = $"/{basePath}/thumbs/{thumbSmallFileName}",
            ThumbnailMediumPath = $"/{basePath}/thumbs/{thumbMediumFileName}",
        };
    }

    private static async Task WriteStreamToFileAsync(Stream source, string filePath)
    {
        source.Position = 0;
        await using var fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None, 8192, useAsync: true);
        await source.CopyToAsync(fileStream);
    }

    private void DeleteLocalFile(string relativePath)
    {
        // Support both old /uploads/ and new /images/ paths
        var localPath = Path.Combine(
            _webRootPath,
            relativePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));

        if (File.Exists(localPath))
        {
            File.Delete(localPath);
            _logger.LogInformation("Deleted local file: {Path}", localPath);
        }
    }

    // ──────────────────────── Azure Blob Storage ────────────────────────

    private async Task<ImageStorageResult> StoreToBlobAsync(
        ImageProcessingResult result,
        string basePath,
        string mainFileName,
        string thumbSmallFileName,
        string thumbMediumFileName)
    {
        const string containerName = "annonces";
        var containerClient = _blobServiceClient!.GetBlobContainerClient(containerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

        // Main image
        var mainBlobPath = $"{basePath}/{mainFileName}";
        var mainUrl = await UploadStreamToBlobAsync(containerClient, mainBlobPath, result.OptimizedImage, result.MimeType);

        // Thumbnails
        var thumbSmallBlobPath = $"{basePath}/thumbs/{thumbSmallFileName}";
        var thumbSmallUrl = await UploadStreamToBlobAsync(containerClient, thumbSmallBlobPath, result.ThumbnailSmall, result.MimeType);

        var thumbMediumBlobPath = $"{basePath}/thumbs/{thumbMediumFileName}";
        var thumbMediumUrl = await UploadStreamToBlobAsync(containerClient, thumbMediumBlobPath, result.ThumbnailMedium, result.MimeType);

        _logger.LogInformation(
            "Image stored in Azure Blob: {Path} ({SizeKB}KB)",
            mainBlobPath, result.OptimizedSize / 1024);

        return new ImageStorageResult
        {
            ImagePath = mainUrl,
            ThumbnailSmallPath = thumbSmallUrl,
            ThumbnailMediumPath = thumbMediumUrl,
        };
    }

    private static async Task<string> UploadStreamToBlobAsync(
        BlobContainerClient containerClient,
        string blobPath,
        Stream content,
        string contentType)
    {
        content.Position = 0;
        var blobClient = containerClient.GetBlobClient(blobPath);
        await blobClient.UploadAsync(content, new BlobHttpHeaders { ContentType = contentType });
        return blobClient.Uri.ToString();
    }

    private async Task DeleteBlobAsync(string blobUrl)
    {
        try
        {
            var uri = new Uri(blobUrl);
            // Path segments: [ "/", "containername/", "path/to/blob" ]
            var containerName = uri.Segments[1].TrimEnd('/');
            var blobName = string.Join("", uri.Segments.Skip(2));

            var containerClient = _blobServiceClient!.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);
            await blobClient.DeleteIfExistsAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting blob: {BlobUrl}", blobUrl);
        }
    }
}
