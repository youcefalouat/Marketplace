using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MarketplaceApi.Data;
using MarketplaceApi.Services;
using MarketplaceApi.Components;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddSignalR();

// Add Blazor Server for Admin
builder.Services.AddRazorPages();
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Configure Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "Marketplace Contrôlée API", 
        Version = "v1",
        Description = "API pour la marketplace contrôlée de produits d'électroménager, meubles, literie et décoration"
    });
    
    // JWT Authentication in Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Configure Entity Framework with SQL Server
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Configure JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"] ?? "YourSuperSecretKeyWithAtLeast32Characters!";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = "JWT_OR_COOKIE";
    options.DefaultChallengeScheme = "JWT_OR_COOKIE";
})
.AddCookie(Microsoft.AspNetCore.Authentication.Cookies.CookieAuthenticationDefaults.AuthenticationScheme, options =>
{
    options.LoginPath = "/Admin/Login";
    options.LogoutPath = "/Admin/Logout";
    options.AccessDeniedPath = "/Admin/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromDays(1);
})
.AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
    };
})
.AddPolicyScheme("JWT_OR_COOKIE", "JWT_OR_COOKIE", options =>
{
    options.ForwardDefaultSelector = context =>
    {
        string authorization = context.Request.Headers["Authorization"].ToString();
        if (!string.IsNullOrEmpty(authorization) && authorization.StartsWith("Bearer "))
            return JwtBearerDefaults.AuthenticationScheme;
        
        return Microsoft.AspNetCore.Authentication.Cookies.CookieAuthenticationDefaults.AuthenticationScheme;
    };
});

builder.Services.AddAuthorization();

// Register services
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IBlobStorageService, BlobStorageService>();
builder.Services.AddScoped<IRatingService, RatingService>();
builder.Services.Configure<FeaturedFeedOptions>(builder.Configuration.GetSection("FeaturedFeed"));
builder.Services.AddScoped<IAnnonceFeedService, AnnonceFeedService>();

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
// Force en-US culture for consistent number parsing (decimal points)
var supportedCultures = new[] { "en-US" };
var localizationOptions = new RequestLocalizationOptions()
    .SetDefaultCulture(supportedCultures[0])
    .AddSupportedCultures(supportedCultures)
    .AddSupportedUICultures(supportedCultures);

app.UseRequestLocalization(localizationOptions);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseStaticFiles(); // For local image storage
app.UseAntiforgery(); // Required for Blazor forms

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapRazorPages();
app.MapHub<MarketplaceApi.Hubs.ChatHub>("/chatHub");

// Map Blazor Admin routes
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Apply pending migrations on startup (dev only)
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    db.Database.EnsureCreated();
    
    // Seed wilayas and communes
    LocationSeedData.SeedLocations(db);
    
    // Seed categories
    CategorySeedData.SeedCategories(db);
    
    // Seed admin user if not exists
    if (!db.Users.Any(u => u.Role == MarketplaceApi.Models.UserRole.Admin))
    {
        // Use Alger (wilaya 16) and Alger Centre (commune 1 of Alger) as default
        var algerWilaya = db.Wilayas.FirstOrDefault(w => w.Code == "16");
        var algerCommune = db.Communes.FirstOrDefault(c => c.WilayaId == algerWilaya!.Id);
        
        db.Users.Add(new MarketplaceApi.Models.User
        {
            Email = "admin@marketplace.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
            Name = "Administrateur",
            Phone = "0600000000",
            WilayaId = algerWilaya!.Id,
            CommuneId = algerCommune!.Id,
            Role = MarketplaceApi.Models.UserRole.Admin,
            CreatedAt = DateTime.UtcNow
        });
        db.SaveChanges();
    }
}

app.Run();

