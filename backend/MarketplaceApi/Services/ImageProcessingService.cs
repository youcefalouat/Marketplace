using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;

namespace MarketplaceApi.Services;

/// <summary>
/// Result of processing a single image through the optimization pipeline.
/// Streams must be disposed by the caller after storage.
/// </summary>
public class ImageProcessingResult : IDisposable
{
    public MemoryStream OptimizedImage { get; init; } = null!;
    public MemoryStream ThumbnailSmall { get; init; } = null!;   // 150px
    public MemoryStream ThumbnailMedium { get; init; } = null!;  // 300px
    public string ContentHash { get; init; } = string.Empty;
    public string MimeType { get; init; } = "image/webp";
    public int Width { get; init; }
    public int Height { get; init; }
    public long OriginalSize { get; init; }
    public long OptimizedSize { get; init; }

    public void Dispose()
    {
        OptimizedImage?.Dispose();
        ThumbnailSmall?.Dispose();
        ThumbnailMedium?.Dispose();
    }
}

public interface IImageProcessingService
{
    /// <summary>
    /// Validates, optimizes, strips metadata, and generates thumbnails for the given image file.
    /// </summary>
    Task<ImageProcessingResult> ProcessImageAsync(IFormFile file);
}

public class ImageProcessingService : IImageProcessingService
{
    private readonly ImageProcessingOptions _options;
    private readonly ILogger<ImageProcessingService> _logger;

    // Magic bytes for common image formats
    private static readonly byte[][] _imageSignatures =
    [
        [0xFF, 0xD8, 0xFF],                     // JPEG
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A],   // PNG
        [0x52, 0x49, 0x46, 0x46],                // WebP (RIFF)
        [0x47, 0x49, 0x46],                      // GIF
    ];

    public ImageProcessingService(
        IOptions<ImageProcessingOptions> options,
        ILogger<ImageProcessingService> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ImageProcessingResult> ProcessImageAsync(IFormFile file)
    {
        // ── 1. Validate file size ──
        if (file.Length == 0)
            throw new ImageProcessingException("Le fichier est vide.");

        if (file.Length > _options.MaxFileSizeBytes)
            throw new ImageProcessingException(
                $"Le fichier dépasse la taille maximale autorisée ({_options.MaxFileSizeBytes / (1024 * 1024)} Mo).");

        // ── 2. Validate MIME type ──
        var contentType = file.ContentType?.ToLowerInvariant() ?? string.Empty;
        if (!_options.AllowedMimeTypes.Contains(contentType))
            throw new ImageProcessingException(
                $"Type de fichier non autorisé: {contentType}. Types acceptés: {string.Join(", ", _options.AllowedMimeTypes)}");

        // ── 3. Read into memory and validate file signature (magic bytes) ──
        using var inputStream = new MemoryStream();
        await file.CopyToAsync(inputStream);
        inputStream.Position = 0;

        if (!ValidateFileSignature(inputStream))
            throw new ImageProcessingException(
                "Le contenu du fichier ne correspond pas à un format d'image valide.");

        inputStream.Position = 0;
        var originalSize = inputStream.Length;

        // ── 4. Load image with ImageSharp ──
        Image image;
        try
        {
            image = await Image.LoadAsync(inputStream);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to decode image: {FileName}", file.FileName);
            throw new ImageProcessingException("Impossible de décoder l'image. Fichier corrompu ou format non supporté.");
        }

        using (image)
        {
            // ── 5. Validate dimensions (image bomb protection) ──
            if (image.Width > _options.MaxDimension || image.Height > _options.MaxDimension)
                throw new ImageProcessingException(
                    $"Les dimensions de l'image dépassent le maximum autorisé ({_options.MaxDimension}px).");

            // ── 6. Strip ALL metadata ──
            StripMetadata(image);

            // ── 7. Resize if needed (defensive, max width) ──
            if (image.Width > _options.MaxWidth)
            {
                var ratio = (double)_options.MaxWidth / image.Width;
                var newHeight = (int)Math.Round(image.Height * ratio);
                image.Mutate(ctx => ctx.Resize(_options.MaxWidth, newHeight, KnownResamplers.Lanczos3));
            }

            // ── 8. Encode optimized image as WebP ──
            var encoder = new WebpEncoder
            {
                Quality = _options.WebPQuality,
                FileFormat = WebpFileFormatType.Lossy,
            };

            var optimizedStream = new MemoryStream();
            await image.SaveAsync(optimizedStream, encoder);
            optimizedStream.Position = 0;

            // ── 9. Compute content hash for dedup filename ──
            var hash = ComputeHash(optimizedStream);
            optimizedStream.Position = 0;

            // ── 10. Generate thumbnails ──
            var thumbSmallStream = await GenerateThumbnailAsync(image, _options.ThumbnailSizes[0], encoder);
            var thumbMediumStream = await GenerateThumbnailAsync(image, _options.ThumbnailSizes[1], encoder);

            _logger.LogInformation(
                "Image processed: {FileName} | {OriginalKB}KB → {OptimizedKB}KB ({Reduction}% reduction) | {W}x{H}",
                file.FileName,
                originalSize / 1024,
                optimizedStream.Length / 1024,
                originalSize > 0 ? (int)((1 - (double)optimizedStream.Length / originalSize) * 100) : 0,
                image.Width,
                image.Height);

            return new ImageProcessingResult
            {
                OptimizedImage = optimizedStream,
                ThumbnailSmall = thumbSmallStream,
                ThumbnailMedium = thumbMediumStream,
                ContentHash = hash,
                MimeType = "image/webp",
                Width = image.Width,
                Height = image.Height,
                OriginalSize = originalSize,
                OptimizedSize = optimizedStream.Length,
            };
        }
    }

    private static void StripMetadata(Image image)
    {
        image.Metadata.ExifProfile = null;
        image.Metadata.IptcProfile = null;
        image.Metadata.XmpProfile = null;
        
        // Clear ICC profile if present (optional, keeps color accuracy)
        // image.Metadata.IccProfile = null;
    }

    private bool ValidateFileSignature(Stream stream)
    {
        var headerBytes = new byte[8];
        var bytesRead = stream.Read(headerBytes, 0, headerBytes.Length);
        if (bytesRead < 3) return false;

        foreach (var signature in _imageSignatures)
        {
            if (bytesRead >= signature.Length)
            {
                bool match = true;
                for (int i = 0; i < signature.Length; i++)
                {
                    if (headerBytes[i] != signature[i])
                    {
                        match = false;
                        break;
                    }
                }
                if (match) return true;
            }
        }

        return false;
    }

    private static string ComputeHash(Stream stream)
    {
        var hashBytes = SHA256.HashData(stream);
        return Convert.ToHexString(hashBytes).ToLowerInvariant()[..16]; // 16 hex chars = 8 bytes, enough for uniqueness
    }

    private static async Task<MemoryStream> GenerateThumbnailAsync(Image source, int targetWidth, WebpEncoder encoder)
    {
        // Clone so we don't mutate the source
        using var clone = source.Clone(ctx =>
        {
            if (source.Width > targetWidth)
            {
                var ratio = (double)targetWidth / source.Width;
                var newHeight = (int)Math.Round(source.Height * ratio);
                ctx.Resize(targetWidth, newHeight, KnownResamplers.Lanczos3);
            }
        });

        var stream = new MemoryStream();
        await clone.SaveAsync(stream, encoder);
        stream.Position = 0;
        return stream;
    }
}

/// <summary>
/// Exception thrown when image validation or processing fails.
/// </summary>
public class ImageProcessingException : Exception
{
    public ImageProcessingException(string message) : base(message) { }
}
