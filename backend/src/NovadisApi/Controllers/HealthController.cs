using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// Controller pour vérifier la santé de l'API
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class HealthController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<HealthController> _logger;

        public HealthController(
            NovadisDbContext context,
            ILogger<HealthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Vérification basique de l'état de l'API
        /// </summary>
        /// <returns>Informations sur l'état de l'API et de la base de données</returns>
        [HttpGet]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Get()
        {
            try
            {
                _logger.LogInformation("Health check requested");

                // Tester la connexion à la base de données
                var canConnect = await _context.Database.CanConnectAsync();
                
                // Compter les utilisateurs (pour vérifier que les données existent)
                var userCount = 0;
                if (canConnect)
                {
                    userCount = await _context.Users.CountAsync();
                }

                var response = new
                {
                    status = canConnect ? "healthy" : "degraded",
                    database = new
                    {
                        connected = canConnect,
                        provider = "SQL Server",
                        usersCount = userCount
                    },
                    api = new
                    {
                        version = "1.0.0",
                        environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"
                    },
                    server = new
                    {
                        machineName = Environment.MachineName,
                        osVersion = Environment.OSVersion.ToString(),
                        dotnetVersion = Environment.Version.ToString()
                    },
                    timestamp = DateTime.UtcNow
                };

                _logger.LogInformation("Health check passed: Database {Status}", canConnect ? "Connected" : "Disconnected");

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");

                return StatusCode(500, new
                {
                    status = "unhealthy",
                    error = ex.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }

        /// <summary>
        /// Récupère la liste des utilisateurs (pour test)
        /// </summary>
        /// <returns>Liste des utilisateurs sans informations sensibles</returns>
        [HttpGet("users")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> GetUsers()
        {
            try
            {
                _logger.LogInformation("Fetching users for health check");

                var users = await _context.Users
                    .Select(u => new
                    {
                        u.Id,
                        u.Email,
                        u.Role,
                        u.FirstName,
                        u.LastName,
                        u.IsActive,
                        u.CreatedAt,
                        u.LastLoginAt
                    })
                    .ToListAsync();

                return Ok(new
                {
                    count = users.Count,
                    users = users,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch users");

                return StatusCode(500, new
                {
                    error = ex.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }

        /// <summary>
        /// Teste la création et suppression d'un enregistrement (test write)
        /// </summary>
        [HttpGet("test-write")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> TestWrite()
        {
            try
            {
                _logger.LogInformation("Testing database write operations");

                // Créer un log de test
                var testLog = new NovadisApi.Models.AuditLog
                {
                    Action = "HealthCheckTest",
                    Details = "Test de connexion en écriture",
                    IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    CreatedAt = DateTime.UtcNow
                };

                _context.AuditLogs.Add(testLog);
                await _context.SaveChangesAsync();

                var logId = testLog.Id;

                // Supprimer immédiatement
                _context.AuditLogs.Remove(testLog);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Database write test successful, created and deleted log {LogId}", logId);

                return Ok(new
                {
                    status = "success",
                    message = "Test d'écriture réussi",
                    testLogId = logId,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database write test failed");

                return StatusCode(500, new
                {
                    status = "failed",
                    error = ex.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }

        /// <summary>
        /// Statistiques détaillées de la base de données
        /// </summary>
        [HttpGet("stats")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> GetStats()
        {
            try
            {
                var stats = new
                {
                    users = await _context.Users.CountAsync(),
                    criForms = await _context.CRIForms.CountAsync(),
                    photos = await _context.CRIPhotos.CountAsync(),
                    auditLogs = await _context.AuditLogs.CountAsync(),
                    criByStatus = await _context.CRIForms
                        .GroupBy(c => c.Status)
                        .Select(g => new { status = g.Key, count = g.Count() })
                        .ToListAsync(),
                    recentCris = await _context.CRIForms
                        .OrderByDescending(c => c.CreatedAt)
                        .Take(5)
                        .Select(c => new
                        {
                            c.Id,
                            c.ClientName,
                            c.InterventionType,
                            c.Status,
                            c.CreatedAt
                        })
                        .ToListAsync(),
                    timestamp = DateTime.UtcNow
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch stats");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}
