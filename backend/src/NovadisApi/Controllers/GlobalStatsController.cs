using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Attributes;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Security.Claims;

namespace NovadisApi.Controllers
{
    /// <summary>
    /// 🌐 Endpoints globaux - Dashboard et statistiques globales
    /// ⚠️ Accessible uniquement par les Admin
    /// </summary>
    [ApiController]
    [Route("api/global")]
    [Authorize]
    [RoleAuthorize("Admin")]
    public class GlobalStatsController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<GlobalStatsController> _logger;

        public GlobalStatsController(NovadisDbContext context, ILogger<GlobalStatsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 📊 GET /api/global/stats - Statistiques globales (admin uniquement)
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<GlobalStatsDto>>> GetGlobalStats()
        {
            try
            {
                var now = DateTime.UtcNow;
                var startOfMonth = new DateTime(now.Year, now.Month, 1);
                var thirtyDaysAgo = now.AddDays(-30);

                var stats = new GlobalStatsDto
                {
                    TotalCeMois = await _context.CRIForms
                        .CountAsync(c => c.CreatedAt >= startOfMonth),

                    TotalSignes = await _context.CRIForms
                        .CountAsync(c => c.ClientSignature != null),

                    TotalEnAttente = await _context.CRIForms
                        .CountAsync(c => c.ClientSignature == null),

                    TechniciensActifs = await _context.CRIForms
                        .Where(c => c.CreatedAt >= thirtyDaysAgo)
                        .Select(c => c.TechnicianId)
                        .Distinct()
                        .CountAsync()
                };

                return Ok(ApiResponse<GlobalStatsDto>.SuccessResponse(stats));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving global stats");
                return StatusCode(500, ApiResponse<GlobalStatsDto>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques globales."));
            }
        }

        /// <summary>
        /// 📋 GET /api/global/cris - Tous les CRI avec info technicien (admin uniquement)
        /// </summary>
        [HttpGet("cris")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIWithTechnicianDto>>>> GetAllCRIsWithTechnician(
            [FromQuery] Guid? technicienId = null,
            [FromQuery] string filter = "all",
            [FromQuery] string? searchId = null)
        {
            try
            {
                var query = _context.CRIForms
                    .Include(c => c.Technician)
                    .AsQueryable();

                // Filtre par technicien
                if (technicienId.HasValue)
                {
                    query = query.Where(c => c.TechnicianId == technicienId.Value);
                }

                // Filtre par ID exact
                if (!string.IsNullOrWhiteSpace(searchId) && Guid.TryParse(searchId, out var searchGuid))
                {
                    query = query.Where(c => c.Id == searchGuid);
                }

                // Filtre par statut
                query = filter.ToLower() switch
                {
                    "signed" => query.Where(c => c.ClientSignature != null),
                    "pending" => query.Where(c => c.ClientSignature == null),
                    _ => query // "all"
                };

                var cris = await query
                    .OrderByDescending(c => c.CreatedAt)
                    .Select(c => new CRIWithTechnicianDto
                    {
                        Id = c.Id,
                        TechnicianId = c.TechnicianId,
                        InterventionType = c.InterventionType,
                        Category = c.Category,
                        InterventionDate = c.InterventionDate,
                        ClientName = c.ClientName,
                        ClientAddress = c.ClientAddress,
                        ClientSite = c.ClientSite,
                        ClientPhone = c.ClientPhone,
                        ClientEmail = c.ClientEmail,
                        WorkDescription = c.WorkDescription,
                        MaterialsUsed = c.MaterialsUsed,
                        Duration = c.Duration,
                        Status = c.Status,
                        Data = c.Data,
                        TechnicianSignature = c.TechnicianSignature,
                        ClientSignature = c.ClientSignature,
                        CreatedAt = c.CreatedAt,
                        UpdatedAt = c.UpdatedAt,
                        SubmittedAt = c.SubmittedAt,
                        TechnicianFirstName = c.Technician != null ? c.Technician.FirstName ?? "" : "",
                        TechnicianLastName = c.Technician != null ? c.Technician.LastName ?? "" : "",
                        TechnicianEmail = c.Technician != null ? c.Technician.Email : ""
                    })
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<CRIWithTechnicianDto>>.SuccessResponse(cris));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all CRIs with technician info");
                return StatusCode(500, ApiResponse<IEnumerable<CRIWithTechnicianDto>>.ErrorResponse(
                    "Erreur lors de la récupération des CRI."));
            }
        }

        /// <summary>
        /// 👥 GET /api/global/activity - Activité de tous les techniciens (admin uniquement)
        /// </summary>
        [HttpGet("activity")]
        public async Task<ActionResult<ApiResponse<IEnumerable<TechnicianActivityDto>>>> GetTechnicianActivity()
        {
            try
            {
                var now = DateTime.UtcNow;
                var sevenDaysAgo = now.AddDays(-7);
                var thirtyDaysAgo = now.AddDays(-30);

                var activity = await _context.Users
                    .Where(u => u.IsActive && (u.Role == "Technician" || u.Role == "Technicien" || u.Role == "Admin"))
                    .Select(u => new TechnicianActivityDto
                    {
                        Id = u.Id,
                        FirstName = u.FirstName ?? "",
                        LastName = u.LastName ?? "",
                        NbCriTotal = u.CRIForms.Count,
                        NbCri7j = u.CRIForms.Count(c => c.CreatedAt >= sevenDaysAgo),
                        NbCri30j = u.CRIForms.Count(c => c.CreatedAt >= thirtyDaysAgo)
                    })
                    .OrderByDescending(a => a.NbCri30j)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<TechnicianActivityDto>>.SuccessResponse(activity));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving technician activity");
                return StatusCode(500, ApiResponse<IEnumerable<TechnicianActivityDto>>.ErrorResponse(
                    "Erreur lors de la récupération de l'activité des techniciens."));
            }
        }

        /// <summary>
        /// 📈 GET /api/global/activity-chart - Données pour graphique d'activité (7 derniers jours)
        /// </summary>
        [HttpGet("activity-chart")]
        public async Task<ActionResult<ApiResponse<IEnumerable<DailyActivityDto>>>> GetActivityChartData()
        {
            try
            {
                var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

                var dailyActivity = await _context.CRIForms
                    .Where(c => c.CreatedAt >= sevenDaysAgo)
                    .GroupBy(c => c.CreatedAt.Date)
                    .Select(g => new DailyActivityDto
                    {
                        Jour = g.Key,
                        Nb = g.Count()
                    })
                    .OrderBy(d => d.Jour)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<DailyActivityDto>>.SuccessResponse(dailyActivity));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving activity chart data");
                return StatusCode(500, ApiResponse<IEnumerable<DailyActivityDto>>.ErrorResponse(
                    "Erreur lors de la récupération des données du graphique."));
            }
        }

        /// <summary>
        /// 👥 GET /api/global/technicians - Liste des techniciens pour dropdown filtre
        /// </summary>
        [HttpGet("technicians")]
        public async Task<ActionResult<ApiResponse<IEnumerable<UserDto>>>> GetTechnicians()
        {
            try
            {
                var technicians = await _context.Users
                    .Where(u => u.IsActive)
                    .OrderBy(u => u.LastName)
                    .ThenBy(u => u.FirstName)
                    .Select(u => new UserDto
                    {
                        Id = u.Id,
                        Email = u.Email,
                        FirstName = u.FirstName ?? "",
                        LastName = u.LastName ?? "",
                        Role = u.Role,
                        IsActive = u.IsActive,
                        LastLoginAt = u.LastLoginAt
                    })
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<UserDto>>.SuccessResponse(technicians));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving technicians list");
                return StatusCode(500, ApiResponse<IEnumerable<UserDto>>.ErrorResponse(
                    "Erreur lors de la récupération des techniciens."));
            }
        }
    }
}
