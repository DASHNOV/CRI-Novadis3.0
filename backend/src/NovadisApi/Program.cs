using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using NovadisApi.Data;
using NovadisApi.Services.Auth;
using NovadisApi.Services.Email;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

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

    // ✅ Politique pour l'application mobile sur le réseau local
    options.AddPolicy("AllowMobileApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// ========================================
// 4️⃣ INJECTION DES SERVICES
// ========================================
// Services d'authentification
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<ICodeGeneratorService, CodeGeneratorService>();
builder.Services.AddScoped<IEmailService, EmailService>();

// Services métier (à ajouter plus tard)
// builder.Services.AddScoped<ICRIService, CRIService>();
// builder.Services.AddScoped<IUserService, UserService>();

// ========================================
// 5️⃣ CONFIGURATION SWAGGER
// ========================================
builder.Services.AddControllers();
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
builder.WebHost.UseUrls("http://0.0.0.0:5000", "https://0.0.0.0:5001");

// ✅ Ajouter les health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// ✅ Middleware de logging des requêtes (pour le débogage réseau)
app.Use(async (context, next) =>
{
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

// HTTPS Redirection
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

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
        app.Logger.LogInformation("Applying database migrations...");
        dbContext.Database.Migrate();
        app.Logger.LogInformation("Database migrations applied successfully");
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "An error occurred while migrating the database");
    }
}

// ========================================
// 🔟 DÉMARRAGE
// ========================================
app.Logger.LogInformation("Novadis CRI API starting...");
app.Logger.LogInformation("Environment: {Environment}", app.Environment.EnvironmentName);
app.Logger.LogInformation("Swagger UI: {Url}", app.Environment.IsDevelopment() ? "http://localhost:5000" : "");

app.Run();
