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
    /// 👤 Endpoints personnels - Statistiques et CRI du technicien connecté
    /// Accessible par Technician ET Admin (chacun voit SES propres données)
    /// </summary>
    [ApiController]
    [Route("api/personal")]
    [Authorize]
    [RoleAuthorize("Technicien", "Technician", "Admin")]
    public class PersonalStatsController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<PersonalStatsController> _logger;

        public PersonalStatsController(NovadisDbContext context, ILogger<PersonalStatsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Récupère l'ID de l'utilisateur connecté depuis le JWT
        /// </summary>
        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            if (Guid.TryParse(userIdStr, out var userId))
                return userId;
            return null;
        }

        /// <summary>
        /// 📊 GET /api/personal/stats - Statistiques personnelles du technicien connecté
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<PersonalStatsDto>>> GetPersonalStats()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<PersonalStatsDto>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var now = DateTime.UtcNow;
                var startOfMonth = new DateTime(now.Year, now.Month, 1);

                var stats = new PersonalStatsDto
                {
                    CriCeMois = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.CreatedAt >= startOfMonth),

                    CriEnCours = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.Status == "Draft"),

                    CriEnAttente = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.ClientSignature == null),

                    // Stats enrichies Phase 1
                    DureeMoyenneMinutes = await _context.CRIForms
                        .Where(c => c.TechnicianId == userId && c.DureeMinutes != null && c.DureeMinutes > 0)
                        .AverageAsync(c => (double?)c.DureeMinutes),

                    TotalResolu = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.ResolutionStatus == "resolu"),

                    TotalNonResolu = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && (c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu")),

                    TotalRecurrenceRequise = await _context.CRIForms
                        .CountAsync(c => c.TechnicianId == userId && c.AdditionalInterventionRequired == true)
                };

                return Ok(ApiResponse<PersonalStatsDto>.SuccessResponse(stats));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving personal stats for user {UserId}", userId);
                return StatusCode(500, ApiResponse<PersonalStatsDto>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques personnelles."));
            }
        }

        /// <summary>
        /// 📋 GET /api/personal/cris - CRI personnels avec filtre
        /// </summary>
        [HttpGet("cris")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetPersonalCRIs(
            [FromQuery] string filter = "all")
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                IQueryable<CRIForm> query = _context.CRIForms
                    .Where(c => c.TechnicianId == userId);

                query = filter.ToLower() switch
                {
                    "pending" => query.Where(c => c.ClientSignature == null),
                    "signed" => query.Where(c => c.ClientSignature != null),
                    "in_progress" => query.Where(c => c.Status == "Draft"),
                    _ => query // "all"
                };

                var cris = await query
                    .OrderByDescending(c => c.CreatedAt)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(cris));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving personal CRIs for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<CRIForm>>.ErrorResponse(
                    "Erreur lors de la récupération des CRI personnels."));
            }
        }

        /// <summary>
        /// 🕐 GET /api/personal/recent - 5 derniers CRI du technicien
        /// </summary>
        [HttpGet("recent")]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetRecentCRIs()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var recentCris = await _context.CRIForms
                    .Where(c => c.TechnicianId == userId)
                    .OrderByDescending(c => c.CreatedAt)
                    .Take(5)
                    .ToListAsync();

                return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(recentCris));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving recent CRIs for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<CRIForm>>.ErrorResponse(
                    "Erreur lors de la récupération des CRI récents."));
            }
        }

        /// <summary>
        /// 📈 GET /api/personal/monthly-stats - Activité mensuelle sur les 6 derniers mois
        /// </summary>
        [HttpGet("monthly-stats")]
        public async Task<ActionResult<ApiResponse<IEnumerable<object>>>> GetMonthlyStats()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<object>>.ErrorResponse("Utilisateur non identifié"));

            try
            {
                var now = DateTime.UtcNow;
                var sixMonthsAgo = new DateTime(now.Year, now.Month, 1).AddMonths(-5);

                var monthlyCounts = await _context.CRIForms
                    .Where(c => c.TechnicianId == userId && c.CreatedAt >= sixMonthsAgo)
                    .GroupBy(c => new { c.CreatedAt.Year, c.CreatedAt.Month })
                    .Select(g => new { annee = g.Key.Year, mois = g.Key.Month, nb = g.Count() })
                    .ToListAsync();

                // Garantir les 6 mois même si nb = 0
                var result = Enumerable.Range(0, 6)
                    .Select(i => {
                        var d = new DateTime(now.Year, now.Month, 1).AddMonths(-5 + i);
                        var found = monthlyCounts.FirstOrDefault(m => m.annee == d.Year && m.mois == d.Month);
                        return new { annee = d.Year, mois = d.Month, nb = found?.nb ?? 0 };
                    })
                    .ToList();

                return Ok(ApiResponse<IEnumerable<object>>.SuccessResponse(result.Cast<object>()));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving monthly stats for user {UserId}", userId);
                return StatusCode(500, ApiResponse<IEnumerable<object>>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques mensuelles."));
            }
        }
    }
}
