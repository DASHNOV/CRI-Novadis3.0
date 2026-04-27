using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using NovadisApi.Services.Auth;
using NovadisApi.Services.Email;
using System.Security.Claims;
using System.Security.Cryptography;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ICodeGeneratorService _codeGenerator;
        private readonly IJwtService _jwtService;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthController> _logger;
        private readonly IConfiguration _configuration;

        public AuthController(
            NovadisDbContext context,
            ICodeGeneratorService codeGenerator,
            IJwtService jwtService,
            IEmailService emailService,
            ILogger<AuthController> logger,
            IConfiguration configuration)
        {
            _context = context;
            _codeGenerator = codeGenerator;
            _jwtService = jwtService;
            _emailService = emailService;
            _logger = logger;
            _configuration = configuration;
        }

        /// <summary>
        /// 📧 POST /api/auth/login - Demander un code de connexion
        /// </summary>
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<object>>> Login([FromBody] LoginRequestDto request)
        {
            try
            {
                _logger.LogInformation("Login attempt for email: {Email}", request.Email);

                // 1️⃣ Vérifier si l'utilisateur existe
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());

                if (user == null || !user.IsActive)
                {
                    _logger.LogWarning("Login failed: User not found or inactive - {Email}", request.Email);
                    return BadRequest(ApiResponse<object>.ErrorResponse(
                        "Aucun compte associé à cette adresse email."
                    ));
                }

                // 2️⃣ Vérifier le nombre de tentatives récentes
                var recentAttempts = await _context.AuthAttempts
                    .Where(a => a.Email.ToLower() == request.Email.ToLower() 
                        && a.CreatedAt > DateTime.UtcNow.AddMinutes(-30))
                    .CountAsync();

                var maxAttempts = _configuration.GetValue<int>("Auth:MaxFailedAttempts", 5);

                if (recentAttempts >= maxAttempts)
                {
                    _logger.LogWarning("Too many login attempts for {Email}", request.Email);
                    return BadRequest(ApiResponse<object>.ErrorResponse(
                        "Trop de tentatives. Veuillez réessayer dans 30 minutes."
                    ));
                }

                // 3️⃣ Générer un code à 6 chiffres
                var code = _codeGenerator.GenerateCode(6);
                var codeHash = _codeGenerator.HashCode(code);

                // 4️⃣ Créer une tentative d'authentification
                var codeExpiry = _configuration.GetValue<int>("Auth:CodeExpiryMinutes", 10);
                var authAttempt = new AuthAttempt
                {
                    Email = user.Email,
                    CodeHash = codeHash,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(codeExpiry),
                    IpAddress = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString(),
#if DEBUG
                    PlainCode = code // ⚠️ Stockage temporaire en DEV
#endif
                };

                _context.AuthAttempts.Add(authAttempt);
                await _context.SaveChangesAsync();

                // 🔍 LOG LE CODE POUR LE DÉVELOPPEMENT LOCAL
                _logger.LogInformation("🔐 [DEV] Code de connexion pour {Email}: {Code}", request.Email, code);

                // 5️⃣ Envoyer l'email avec le code
                var emailBody = $@"
                    <html>
                    <body style='font-family: Arial, sans-serif;'>
                        <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
                            <h2 style='color: #2563eb;'>Connexion à Novadis CRI</h2>
                            <p>Bonjour {user.FirstName},</p>
                            <p>Voici votre code de vérification pour vous connecter :</p>
                            <div style='background: #f3f4f6; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;'>
                                <h1 style='color: #1f2937; font-size: 36px; letter-spacing: 8px; margin: 0;'>{code}</h1>
                            </div>
                            <p style='color: #6b7280;'>Ce code expire dans {codeExpiry} minutes.</p>
                            <p style='color: #6b7280; font-size: 12px;'>Si vous n'avez pas demandé ce code, ignorez cet email.</p>
                            <hr style='border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;'>
                            <p style='color: #9ca3af; font-size: 12px;'>© {DateTime.UtcNow.Year} Novadis - Tous droits réservés</p>
                        </div>
                    </body>
                    </html>
                ";

                await _emailService.SendEmailAsync(
                    user.Email,
                    "Code de connexion Novadis CRI",
                    emailBody
                );

                // 6️⃣ Logger l'action
                var auditLog = new AuditLog
                {
                    UserId = user.Id,
                    Action = "LOGIN_REQUEST",
                    EntityType = "Auth",
                    Details = $"Code de connexion envoyé à {user.Email}",
                    IpAddress = request.IpAddress
                };
                _context.AuditLogs.Add(auditLog);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Login code sent successfully to {Email}", request.Email);

                return Ok(ApiResponse<object>.SuccessResponse(
                    new { expiresIn = codeExpiry },
                    "Un code de vérification a été envoyé à votre adresse email."
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login for {Email}", request.Email);
                
                // Return detailed error in logs or dev mode if needed, but for now just tell user it failed
                // If it's an email failure, it might be helpful to know
                var message = "Une erreur est survenue. Veuillez réessayer.";
                if (ex.Message.Contains("SMTP") || ex.Source?.Contains("Net.Mail") == true)
                {
                     message = "Erreur lors de l'envoi de l'email. Vérifiez la configuration SMTP.";
                }

                return StatusCode(500, ApiResponse<object>.ErrorResponse(
                   $"{message} (Détail: {ex.Message})"
                ));
            }
        }

        /// <summary>
        /// ✅ POST /api/auth/verify - Vérifier le code et obtenir un token JWT
        /// </summary>
        [HttpPost("verify")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyCode([FromBody] VerifyCodeRequestDto request)
        {
            try
            {
                _logger.LogInformation("Code verification attempt for {Email}", request.Email);

                // 1️⃣ Récupérer l'utilisateur
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());

                if (user == null || !user.IsActive)
                {
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        "Email ou code invalide."
                    ));
                }

                // 2️⃣ Récupérer la dernière tentative non utilisée et non expirée
                var authAttempt = await _context.AuthAttempts
                    .Where(a => a.Email.ToLower() == request.Email.ToLower()
                        && !a.IsUsed
                        && a.ExpiresAt > DateTime.UtcNow)
                    .OrderByDescending(a => a.CreatedAt)
                    .FirstOrDefaultAsync();

                if (authAttempt == null)
                {
                    _logger.LogWarning("No valid auth attempt found for {Email}", request.Email);
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        "Code expiré ou invalide. Veuillez demander un nouveau code."
                    ));
                }

                // 3️⃣ Vérifier le code
                if (!_codeGenerator.VerifyCode(request.Code, authAttempt.CodeHash))
                {
                    authAttempt.FailedAttempts++;
                    await _context.SaveChangesAsync();

                    _logger.LogWarning("Invalid code attempt for {Email} - Attempt {Count}",
                        request.Email, authAttempt.FailedAttempts);

                    var maxAttempts = _configuration.GetValue<int>("Auth:MaxFailedAttempts", 5);
                    if (authAttempt.FailedAttempts >= maxAttempts)
                    {
                        authAttempt.IsUsed = true;
                        await _context.SaveChangesAsync();

                        return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                            "Trop de tentatives échouées. Veuillez demander un nouveau code."
                        ));
                    }

                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        $"Code invalide. {maxAttempts - authAttempt.FailedAttempts} tentatives restantes."
                    ));
                }

                // 4️⃣ Marquer la tentative comme utilisée
                authAttempt.IsUsed = true;
                await _context.SaveChangesAsync();

                // 5️⃣ Générer les tokens JWT
                var accessToken = _jwtService.GenerateAccessToken(user);
                var refreshToken = _jwtService.GenerateRefreshToken();

                // 6️⃣ Stocker le refresh token + générer le token appareil de confiance
                var refreshExpiry = _configuration.GetValue<int>("Jwt:RefreshExpiryDays", 7);
                var trustedDeviceToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
                var userToken = new UserToken
                {
                    UserId = user.Id,
                    RefreshToken = refreshToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiry),
                    DeviceInfo = request.DeviceInfo,
                    IpAddress = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString(),
                    TrustedDeviceToken = trustedDeviceToken
                };

                _context.UserTokens.Add(userToken);

                // 7️⃣ Mettre à jour la date de dernière connexion
                user.LastLoginAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // 8️⃣ Logger l'action
                var auditLog = new AuditLog
                {
                    UserId = user.Id,
                    Action = "LOGIN_SUCCESS",
                    EntityType = "Auth",
                    Details = $"Connexion réussie pour {user.Email}",
                    IpAddress = request.IpAddress
                };
                _context.AuditLogs.Add(auditLog);
                await _context.SaveChangesAsync();

                _logger.LogInformation("User {Email} logged in successfully", user.Email);

                // 9️⃣ Retourner la réponse
                var expiryMinutes = _configuration.GetValue<int>("Jwt:ExpiryMinutes", 60);
                var response = new AuthResponseDto
                {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
                    TrustedDeviceToken = trustedDeviceToken,
                    User = new UserDto
                    {
                        Id = user.Id,
                        Email = user.Email,
                        FirstName = user.FirstName,
                        LastName = user.LastName,
                        Role = user.Role,
                        IsActive = user.IsActive,
                        LastLoginAt = user.LastLoginAt
                    }
                };

                return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(
                    response,
                    "Connexion réussie"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during code verification for {Email}", request.Email);
                return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse(
                    "Une erreur est survenue. Veuillez réessayer."
                ));
            }
        }

        /// <summary>
        /// 🔄 POST /api/auth/refresh - Rafraîchir le token d'accès
        /// </summary>
        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> RefreshToken([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                _logger.LogInformation("Token refresh attempt");

                // 1️⃣ Vérifier le refresh token
                var userToken = await _context.UserTokens
                    .Include(t => t.User)
                    .FirstOrDefaultAsync(t => t.RefreshToken == request.RefreshToken
                        && !t.IsRevoked
                        && t.ExpiresAt > DateTime.UtcNow);

                if (userToken == null)
                {
                    _logger.LogWarning("Invalid or expired refresh token");
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        "Token invalide ou expiré."
                    ));
                }

                var user = userToken.User;
                if (!user.IsActive)
                {
                    _logger.LogWarning("User {Email} is inactive", user.Email);
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        "Compte désactivé."
                    ));
                }

                // 2️⃣ Révoquer l'ancien token
                userToken.IsRevoked = true;

                // 3️⃣ Générer de nouveaux tokens
                var newAccessToken = _jwtService.GenerateAccessToken(user);
                var newRefreshToken = _jwtService.GenerateRefreshToken();

                // 4️⃣ Créer un nouveau refresh token
                var refreshExpiry = _configuration.GetValue<int>("Jwt:RefreshExpiryDays", 7);
                var newUserToken = new UserToken
                {
                    UserId = user.Id,
                    RefreshToken = newRefreshToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiry),
                    DeviceInfo = request.DeviceInfo,
                    IpAddress = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString()
                };

                _context.UserTokens.Add(newUserToken);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Token refreshed successfully for user {Email}", user.Email);

                // 5️⃣ Retourner la réponse
                var expiryMinutes = _configuration.GetValue<int>("Jwt:ExpiryMinutes", 60);
                var response = new AuthResponseDto
                {
                    AccessToken = newAccessToken,
                    RefreshToken = newRefreshToken,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
                    User = new UserDto
                    {
                        Id = user.Id,
                        Email = user.Email,
                        FirstName = user.FirstName,
                        LastName = user.LastName,
                        Role = user.Role,
                        IsActive = user.IsActive,
                        LastLoginAt = user.LastLoginAt
                    }
                };

                return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(
                    response,
                    "Token rafraîchi avec succès"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during token refresh");
                return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse(
                    "Une erreur est survenue. Veuillez réessayer."
                ));
            }
        }

        /// <summary>
        /// 🚪 POST /api/auth/logout - Se déconnecter (révoquer le refresh token)
        /// </summary>
        [HttpPost("logout")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<object>>> Logout([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                _logger.LogInformation("Logout attempt for user {UserId}", userId);

                // 1️⃣ Révoquer le refresh token spécifique
                var userToken = await _context.UserTokens
                    .FirstOrDefaultAsync(t => t.RefreshToken == request.RefreshToken && !t.IsRevoked);

                if (userToken != null)
                {
                    userToken.IsRevoked = true;
                    await _context.SaveChangesAsync();
                }

                // 2️⃣ Logger l'action
                if (Guid.TryParse(userId, out var userGuid))
                {
                    var auditLog = new AuditLog
                    {
                        UserId = userGuid,
                        Action = "LOGOUT",
                        EntityType = "Auth",
                        Details = "Déconnexion réussie",
                        IpAddress = request.IpAddress
                    };
                    _context.AuditLogs.Add(auditLog);
                    await _context.SaveChangesAsync();
                }

                _logger.LogInformation("User {UserId} logged out successfully", userId);

                return Ok(ApiResponse<object>.SuccessResponse(
                    null,
                    "Déconnexion réussie"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during logout");
                return StatusCode(500, ApiResponse<object>.ErrorResponse(
                    "Une erreur est survenue lors de la déconnexion."
                ));
            }
        }

        /// <summary>
        /// 👤 GET /api/auth/me - Récupérer les informations de l'utilisateur connecté
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<ApiResponse<UserDto>>> GetCurrentUser()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponse<UserDto>.ErrorResponse("Token invalide"));
                }

                var user = await _context.Users.FindAsync(userGuid);

                if (user == null || !user.IsActive)
                {
                    return Unauthorized(ApiResponse<UserDto>.ErrorResponse("Utilisateur introuvable"));
                }

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role,
                    IsActive = user.IsActive,
                    LastLoginAt = user.LastLoginAt
                };

                return Ok(ApiResponse<UserDto>.SuccessResponse(userDto));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving current user");
                return StatusCode(500, ApiResponse<UserDto>.ErrorResponse(
                    "Une erreur est survenue."
                ));
            }
        }

        /// <summary>
        /// 📱 POST /api/auth/verify-device - Connexion via appareil de confiance (skip OTP)
        /// </summary>
        [HttpPost("verify-device")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<AuthResponseDto>>> VerifyDevice([FromBody] VerifyDeviceRequestDto request)
        {
            try
            {
                _logger.LogInformation("Trusted device login attempt for {Email}", request.Email);

                var userToken = await _context.UserTokens
                    .Include(t => t.User)
                    .FirstOrDefaultAsync(t =>
                        t.TrustedDeviceToken == request.TrustedDeviceToken
                        && t.User!.Email.ToLower() == request.Email.ToLower()
                        && !t.IsRevoked
                        && t.ExpiresAt > DateTime.UtcNow);

                if (userToken == null)
                {
                    _logger.LogWarning("Trusted device not recognized for {Email}", request.Email);
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(
                        "Appareil non reconnu ou session expirée."
                    ));
                }

                var user = userToken.User!;
                if (!user.IsActive)
                {
                    return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse("Compte désactivé."));
                }

                // Révoquer l'ancien token, créer un nouveau avec rotation du trusted device token
                userToken.IsRevoked = true;
                userToken.RevokedReason = "trusted_device_rotation";

                var accessToken = _jwtService.GenerateAccessToken(user);
                var refreshToken = _jwtService.GenerateRefreshToken();
                var newTrustedDeviceToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));

                var refreshExpiry = _configuration.GetValue<int>("Jwt:RefreshExpiryDays", 7);
                var newUserToken = new UserToken
                {
                    UserId = user.Id,
                    RefreshToken = refreshToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiry),
                    DeviceInfo = request.DeviceInfo ?? userToken.DeviceInfo,
                    IpAddress = request.IpAddress ?? HttpContext.Connection.RemoteIpAddress?.ToString(),
                    TrustedDeviceToken = newTrustedDeviceToken
                };

                _context.UserTokens.Add(newUserToken);
                user.LastLoginAt = DateTime.UtcNow;

                _context.AuditLogs.Add(new AuditLog
                {
                    UserId = user.Id,
                    Action = "LOGIN_TRUSTED_DEVICE",
                    EntityType = "Auth",
                    Details = $"Connexion via appareil de confiance pour {user.Email}",
                    IpAddress = request.IpAddress
                });

                await _context.SaveChangesAsync();

                _logger.LogInformation("Trusted device login successful for {Email}", user.Email);

                var expiryMinutes = _configuration.GetValue<int>("Jwt:ExpiryMinutes", 60);
                var response = new AuthResponseDto
                {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
                    TrustedDeviceToken = newTrustedDeviceToken,
                    User = new UserDto
                    {
                        Id = user.Id,
                        Email = user.Email,
                        FirstName = user.FirstName,
                        LastName = user.LastName,
                        Role = user.Role,
                        IsActive = user.IsActive,
                        LastLoginAt = user.LastLoginAt
                    }
                };

                return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(response, "Connexion réussie"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during trusted device verification for {Email}", request.Email);
                return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse(
                    "Une erreur est survenue. Veuillez réessayer."
                ));
            }
        }

        /// <summary>
        /// 🔧 GET /api/auth/dev/get-code/{email} - [DEV ONLY] Récupérer le dernier code généré
        /// ⚠️ À SUPPRIMER EN PRODUCTION
        /// </summary>
        [HttpGet("dev/get-code/{email}")]
        [AllowAnonymous]
#if !DEBUG
        [ApiExplorerSettings(IgnoreApi = true)] // Masquer en production
#endif
        public async Task<ActionResult<ApiResponse<object>>> GetLastCode(string email)
        {
#if !DEBUG
            return NotFound(); // Désactivé en production
#else
            try
            {
                _logger.LogWarning("⚠️ DEV ENDPOINT CALLED: get-code for {Email}", email);

                var lastAttempt = await _context.AuthAttempts
                    .Where(a => a.Email.ToLower() == email.ToLower()
                        && !a.IsUsed
                        && a.ExpiresAt > DateTime.UtcNow)
                    .OrderByDescending(a => a.CreatedAt)
                    .FirstOrDefaultAsync();

                if (lastAttempt == null)
                {
                    return NotFound(ApiResponse<object>.ErrorResponse(
                        "Aucun code actif trouvé. Demandez d'abord un code via /api/auth/login"
                    ));
                }

                // ⚠️ EN DEV UNIQUEMENT : Retourner le code en clair

                return Ok(ApiResponse<object>.SuccessResponse(
                    new
                    {
                        email = lastAttempt.Email,
                        code = lastAttempt.PlainCode,
                        expiresAt = lastAttempt.ExpiresAt,
                        expiresIn = (int)(lastAttempt.ExpiresAt - DateTime.UtcNow).TotalMinutes,
                        createdAt = lastAttempt.CreatedAt,
                        warning = "⚠️ Cet endpoint est disponible uniquement en développement"
                    },
                    "Code récupéré (DEV MODE)"
                ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving dev code for {Email}", email);
                return StatusCode(500, ApiResponse<object>.ErrorResponse(
                    "Erreur lors de la récupération du code"
                ));
            }
#endif
        }
    }
}
