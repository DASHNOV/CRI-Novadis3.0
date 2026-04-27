using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Services;
using NovadisApi.Services.Auth;
using NovadisApi.Services.Email;
using NovadisApi.Services.Export;
using NovadisApi.Services.Storage;
using System.Globalization;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Charger les variables d'environnement depuis le fichier .env (secrets)
var envPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (File.Exists(envPath))
{
    foreach (var line in File.ReadAllLines(envPath))
    {
        if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#')) continue;
        var separatorIndex = line.IndexOf('=');
        if (separatorIndex <= 0) continue;
        var key = line[..separatorIndex].Trim();
        var value = line[(separatorIndex + 1)..].Trim();
        Environment.SetEnvironmentVariable(key, value);
    }
}

// Recharger la configuration pour inclure les variables d'environnement
builder.Configuration.AddEnvironmentVariables();

// ========================================
// 1️⃣ CONFIGURATION DE LA BASE DE DONNÉES
// ========================================
builder.Services.AddDbContext<NovadisDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorNumbersToAdd: null
        )
    )
);

// ========================================
// 2️⃣ CONFIGURATION JWT
// ========================================
var jwtSecretKey = builder.Configuration["Jwt:SecretKey"] 
    ?? throw new InvalidOperationException("JWT SecretKey not configured");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero // Pas de tolérance sur l'expiration
    };

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
            {
                context.Response.Headers.Append("Token-Expired", "true");
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("TechnicianOrAdmin", policy => 
        policy.RequireRole("Technician", "Admin"));
});

// ========================================
// 3️⃣ CONFIGURATION CORS
// ========================================
builder.Services.AddCors(options => {
    // Politique pour le développement local
    options.AddPolicy("DevCorsPolicy", policy => {
        policy
            .WithOrigins(
                "http://localhost:50900",      // Expo Web
                "http://localhost:8081",       // Expo Metro Bundler
                "http://localhost:19006",      // Expo Web (autre port)
                "http://10.0.2.2:50900",       // Android Emulator
                "http://192.168.1.10:50900"    // Device Physique (IP à adapter)
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });

    // ✅ Politique restreinte pour l'application mobile et web Vercel
    options.AddPolicy("AllowMobileApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader()
              .WithExposedHeaders("Token-Expired", "Content-Disposition", "ngrok-skip-browser-warning");
    });
});

// ========================================
// 4️⃣ INJECTION DES SERVICES
// ========================================
// Services d'authentification
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<ICodeGeneratorService, CodeGeneratorService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<ISiteSummaryService, SiteSummaryService>();
builder.Services.AddScoped<IXlsxExportService, XlsxExportService>();

// Stockage des exports (filesystem local, MinIO-ready)
builder.Services.AddSingleton<IObjectStorageService, LocalFileObjectStorage>();

// Services métier (à ajouter plus tard)
// builder.Services.AddScoped<ICRIService, CRIService>();
// builder.Services.AddScoped<IUserService, UserService>();

// ========================================
// 5️⃣ CONFIGURATION SWAGGER
// ========================================
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Novadis CRI API",
        Version = "v1",
        Description = "API de gestion des Comptes Rendus d'Intervention",
        Contact = new OpenApiContact
        {
            Name = "Novadis Support",
            Email = "support@novadis.fr"
        }
    });

    // Configuration pour JWT dans Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
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

// ========================================
// 6️⃣ CONFIGURATION DES LOGS
// ========================================
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

if (builder.Environment.IsProduction())
{
    // En production, ajouter Application Insights ou autre
    // builder.Services.AddApplicationInsightsTelemetry();
}

// ========================================
// 7️⃣ CONFIGURATION RÉSEAU & HEALTH CHECKS
// ========================================
// ✅ Forcer l'écoute sur toutes les interfaces pour l'accès réseau local
builder.WebHost.UseUrls("http://0.0.0.0:5200");

// ✅ Ajouter les health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// ✅ Middleware de configuration Ngrok et logging
app.Use(async (context, next) =>
{
    // Skip ngrok browser warning
    context.Response.Headers.Append("ngrok-skip-browser-warning", "true");
    
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogInformation($"Requête entrante: {context.Request.Method} {context.Request.Path} depuis {context.Connection.RemoteIpAddress}");
    await next.Invoke();
    logger.LogInformation($"Réponse: {context.Response.StatusCode}");
});

// ========================================
// 8️⃣ MIDDLEWARE PIPELINE
// ========================================

// Swagger (toujours actif pour faciliter les tests)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Novadis CRI API v1");
    c.RoutePrefix = string.Empty; // Swagger à la racine (/)
});

// HTTPS Redirection désactivée : Cloudflare gère le HTTPS (SSL Flexible)
// app.UseHttpsRedirection();

// ✅ Activer CORS (AVANT UseAuthorization)
app.UseCors("AllowMobileApp");

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// Controllers
app.MapControllers();

// ✅ Endpoint de santé
app.MapHealthChecks("/api/health");

// ========================================
// 9️⃣ MIGRATION AUTOMATIQUE (DEV ONLY)
// ========================================
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
    
    try
    {
        app.Logger.LogInformation("Skipping automatic migrations (already handled manually)...");
        // dbContext.Database.Migrate();
        // app.Logger.LogInformation("Database migrations applied successfully");

        // Feature "Trusted Device" désactivée : CRI_App_User n'a pas les droits ALTER TABLE.
        // Pour réactiver : faire appliquer la migration 20260427100000_AddTrustedDeviceToken
        // par un compte admin (sa/dba), puis retirer [NotMapped] sur UserToken.TrustedDeviceToken.
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "An error occurred while migrating the database");
    }
}

// ========================================
// 🔟 IMPORT DES SITES CSV (au démarrage)
// ========================================
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        // Créer la table Sites si elle n'existe pas
        dbContext.Database.ExecuteSqlRaw(@"
            IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sites')
            BEGIN
                CREATE TABLE Sites (
                    Numero int NOT NULL PRIMARY KEY,
                    NomDuSite nvarchar(500) NOT NULL,
                    Adresse nvarchar(500) NULL,
                    Ville nvarchar(255) NULL,
                    CodePostal nvarchar(20) NULL,
                    Pays nvarchar(100) NULL,
                    ResponsableDorigine nvarchar(255) NULL,
                    DateDeCreation datetime2 NULL
                );
                CREATE INDEX IX_Sites_NomDuSite ON Sites(NomDuSite);
                CREATE INDEX IX_Sites_Ville ON Sites(Ville);
                CREATE INDEX IX_Sites_CodePostal ON Sites(CodePostal);
            END");

        // Importer le CSV seulement si la table est vide
        var siteCount = dbContext.Sites.Count();
        if (siteCount == 0)
        {
            var csvPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..",
                "Liste Sites NovaDIS - extract Gx 20260318.csv");
            if (!File.Exists(csvPath))
                csvPath = Path.Combine(Directory.GetCurrentDirectory(),
                    "Liste Sites NovaDIS - extract Gx 20260318.csv");

            if (File.Exists(csvPath))
            {
                var lines = File.ReadAllLines(csvPath, Encoding.Latin1);
                var imported = 0;
                for (int i = 1; i < lines.Length; i++)
                {
                    var line = lines[i].Trim();
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var fields = line.Split(';');
                    if (fields.Length < 8 || !int.TryParse(fields[0].Trim(), out var numero)) continue;

                    dbContext.Sites.Add(new Site
                    {
                        Numero = numero,
                        NomDuSite = fields[1].Trim(),
                        Adresse = string.IsNullOrWhiteSpace(fields[2].Trim()) ? null : fields[2].Trim(),
                        Ville = string.IsNullOrWhiteSpace(fields[3].Trim()) ? null : fields[3].Trim(),
                        CodePostal = string.IsNullOrWhiteSpace(fields[4].Trim()) ? null : fields[4].Trim(),
                        Pays = string.IsNullOrWhiteSpace(fields[5].Trim()) ? null : fields[5].Trim(),
                        ResponsableDorigine = string.IsNullOrWhiteSpace(fields[6].Trim()) ? null : fields[6].Trim(),
                        DateDeCreation = DateTime.TryParseExact(fields[7].Trim(), "dd/MM/yyyy",
                            CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null
                    });
                    imported++;
                }
                dbContext.SaveChanges();
                logger.LogInformation("Imported {Count} sites from CSV", imported);
            }
            else
            {
                logger.LogWarning("CSV file not found, skipping site import");
            }
        }
        else
        {
            logger.LogInformation("Sites table already contains {Count} entries, skipping import", siteCount);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error during site import");
    }
}

// ========================================
// 🔟 DÉMARRAGE
// ========================================
app.Logger.LogInformation("Novadis CRI API starting...");
app.Logger.LogInformation("Environment: {Environment}", app.Environment.EnvironmentName);
app.Logger.LogInformation("Swagger UI: {Url}", app.Environment.IsDevelopment() ? "http://localhost:5200" : "");

app.Run();
