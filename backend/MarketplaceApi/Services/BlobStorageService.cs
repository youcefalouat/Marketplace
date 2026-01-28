using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace MarketplaceApi.Services;

public interface IBlobStorageService
{
    Task<string> UploadImageAsync(IFormFile file, string containerName = "annonces");
    Task DeleteImageAsync(string blobUrl);
    Task<List<string>> UploadImagesAsync(IEnumerable<IFormFile> files, string containerName = "annonces");
}

public class BlobStorageService : IBlobStorageService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly ILogger<BlobStorageService> _logger;
    private readonly string _baseUrl;
    
    public BlobStorageService(IConfiguration configuration, ILogger<BlobStorageService> logger)
    {
        var connectionString = configuration["AzureStorage:ConnectionString"];
        
        if (string.IsNullOrEmpty(connectionString))
        {
            // Use local storage for development
            _baseUrl = "/uploads";
            _blobServiceClient = null!;
            _logger = logger;
            return;
        }
        
        _blobServiceClient = new BlobServiceClient(connectionString);
        _baseUrl = configuration["AzureStorage:BaseUrl"] ?? "";
        _logger = logger;
    }
    
    public async Task<string> UploadImageAsync(IFormFile file, string containerName = "annonces")
    {
        if (_blobServiceClient == null)
        {
            // Local storage fallback for development
            return await SaveLocallyAsync(file);
        }
        
        var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);
        
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var blobClient = containerClient.GetBlobClient(fileName);
        
        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, new BlobHttpHeaders 
        { 
            ContentType = file.ContentType 
        });
        
        return blobClient.Uri.ToString();
    }
    
    public async Task<List<string>> UploadImagesAsync(IEnumerable<IFormFile> files, string containerName = "annonces")
    {
        var urls = new List<string>();
        
        foreach (var file in files)
        {
            var url = await UploadImageAsync(file, containerName);
            urls.Add(url);
        }
        
        return urls;
    }
    
    public async Task DeleteImageAsync(string blobUrl)
    {
        if (_blobServiceClient == null || string.IsNullOrEmpty(blobUrl))
        {
            // Handle local file deletion
            if (blobUrl?.StartsWith("/uploads") == true)
            {
                var localPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", blobUrl.TrimStart('/'));
                if (File.Exists(localPath))
                {
                    File.Delete(localPath);
                }
            }
            return;
        }
        
        try
        {
            var uri = new Uri(blobUrl);
            var containerName = uri.Segments[1].TrimEnd('/');
            var blobName = uri.Segments[2];
            
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);
            
            await blobClient.DeleteIfExistsAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting blob: {BlobUrl}", blobUrl);
        }
    }
    
    private async Task<string> SaveLocallyAsync(IFormFile file)
    {
        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
        Directory.CreateDirectory(uploadsFolder);
        
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsFolder, fileName);
        
        using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);
        
        return $"/uploads/{fileName}";
    }
}
