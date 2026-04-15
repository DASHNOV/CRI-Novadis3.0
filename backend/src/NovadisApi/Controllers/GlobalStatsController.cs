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
        /// Filtre les CRI par période (en jours). 0 = tout.
        /// </summary>
        private IQueryable<CRIForm> FilterByPeriod(IQueryable<CRIForm> query, int? periodDays)
        {
            if (periodDays.HasValue && periodDays.Value > 0)
            {
                var startDate = DateTime.UtcNow.AddDays(-periodDays.Value);
                query = query.Where(c => c.InterventionDate >= startDate);
            }
            return query;
        }

        /// <summary>
        /// GET /api/global/stats?period=30 - Statistiques globales (admin uniquement)
        /// period : nombre de jours (1, 7, 30, 90, 365). Omis = tout.
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<GlobalStatsDto>>> GetGlobalStats(
            [FromQuery] int? period = null)
        {
            try
            {
                var baseQuery = FilterByPeriod(_context.CRIForms, period);

                var stats = new GlobalStatsDto
                {
                    TotalCeMois = await baseQuery.CountAsync(),

                    TotalSignes = await baseQuery
                        .CountAsync(c => c.ClientSignature != null),

                    TotalEnAttente = await baseQuery
                        .CountAsync(c => c.ClientSignature == null),

                    TechniciensActifs = await baseQuery
                        .Select(c => c.TechnicianId)
                        .Distinct()
                        .CountAsync(),

                    DureeMoyenneMinutes = await baseQuery
                        .Where(c => c.DureeMinutes != null && c.DureeMinutes > 0)
                        .AverageAsync(c => (double?)c.DureeMinutes),

                    TotalProjets = await baseQuery
                        .CountAsync(c => c.InterventionType == "Project"),

                    TotalServices = await baseQuery
                        .CountAsync(c => c.InterventionType == "Service"),

                    TotalResolu = await baseQuery
                        .CountAsync(c => c.ResolutionStatus == "resolu"),

                    TotalNonResolu = await baseQuery
                        .CountAsync(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu"),

                    TotalRecurrenceRequise = await baseQuery
                        .CountAsync(c => c.AdditionalInterventionRequired == true)
                };

                // Répartition par priorité
                var priorityStats = await baseQuery
                    .Where(c => c.Priority != null)
                    .GroupBy(c => c.Priority!)
                    .Select(g => new { Priority = g.Key, Count = g.Count() })
                    .ToListAsync();
                stats.RepartitionParPriorite = priorityStats.ToDictionary(p => p.Priority, p => p.Count);

                // Top 10 villes
                var villeStats = await baseQuery
                    .Where(c => c.Ville != null)
                    .GroupBy(c => c.Ville!)
                    .Select(g => new { Ville = g.Key, Count = g.Count() })
                    .OrderByDescending(g => g.Count)
                    .Take(10)
                    .ToListAsync();
                stats.RepartitionParVille = villeStats.ToDictionary(v => v.Ville, v => v.Count);

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
                    .Include(c => c.Site)
                    .Include(c => c.Client)
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
                        // Colonnes extraites
                        HeureDebut = c.HeureDebut,
                        HeureFin = c.HeureFin,
                        DureeMinutes = c.DureeMinutes,
                        Ville = c.Ville,
                        CodePostal = c.CodePostal,
                        Pays = c.Pays,
                        ClientContact = c.ClientContact,
                        TicketNumber = c.TicketNumber,
                        Priority = c.Priority,
                        ResolutionStatus = c.ResolutionStatus,
                        AdditionalInterventionRequired = c.AdditionalInterventionRequired,
                        ProjectName = c.ProjectName,
                        ProjectNumber = c.ProjectNumber,
                        ProjectPhase = c.ProjectPhase,
                        ProjectStatus = c.ProjectStatus,
                        // Relations normalisées
                        SiteID = c.SiteID,
                        SiteNom = c.Site != null ? c.Site.NomDuSite : null,
                        ClientID = c.ClientID,
                        ClientRaisonSociale = c.Client != null ? c.Client.RaisonSociale : null,
                        // Info technicien
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

        /// <summary>
        /// GET /api/global/stats/by-site?period=30 - Statistiques par site
        /// </summary>
        [HttpGet("stats/by-site")]
        public async Task<ActionResult<ApiResponse<IEnumerable<SiteStatsDto>>>> GetStatsBySite(
            [FromQuery] int? period = null)
        {
            try
            {
                var baseQuery = FilterByPeriod(_context.CRIForms, period);

                // Grouper par site (utilise SiteID normalisé, fallback sur ClientSite texte)
                var criList = await baseQuery
                    .Include(c => c.Site)
                    .Where(c => c.ClientSite != null && c.ClientSite != "")
                    .Select(c => new
                    {
                        c.SiteID,
                        SiteNom = c.Site != null ? c.Site.NomDuSite : c.ClientSite!,
                        SiteVille = c.Site != null ? c.Site.Ville : c.Ville,
                        ClientNom = c.Client != null ? c.Client.RaisonSociale : c.ClientName,
                        c.InterventionType,
                        c.Category,
                        c.DureeMinutes,
                        c.ResolutionStatus,
                        c.AdditionalInterventionRequired,
                        c.Priority,
                        c.TechnicianId,
                        c.InterventionDate
                    })
                    .ToListAsync();

                var grouped = criList.GroupBy(c => c.SiteNom);

                var result = grouped.Select(g =>
                {
                    var total = g.Count();
                    var resolu = g.Count(c => c.ResolutionStatus == "resolu");
                    var nonResolu = g.Count(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu");
                    var recurrence = g.Count(c => c.AdditionalInterventionRequired == true);

                    // Top catégorie
                    var categories = g
                        .Where(c => !string.IsNullOrEmpty(c.Category))
                        .GroupBy(c => c.Category)
                        .OrderByDescending(cg => cg.Count())
                        .FirstOrDefault();

                    // Répartition par catégorie
                    var repartitionCat = g
                        .Where(c => !string.IsNullOrEmpty(c.Category))
                        .GroupBy(c => c.Category)
                        .ToDictionary(cg => cg.Key!, cg => cg.Count());

                    // Répartition par priorité
                    var repartitionPrio = g
                        .Where(c => !string.IsNullOrEmpty(c.Priority))
                        .GroupBy(c => c.Priority)
                        .ToDictionary(pg => pg.Key!, pg => pg.Count());

                    return new SiteStatsDto
                    {
                        SiteID = g.First().SiteID,
                        SiteNom = g.Key,
                        ClientNom = g.First().ClientNom,
                        Ville = g.First().SiteVille,
                        TotalInterventions = total,
                        DureeMoyenneMinutes = g.Where(c => c.DureeMinutes > 0).Select(c => (double?)c.DureeMinutes).DefaultIfEmpty().Average(),
                        TotalServices = g.Count(c => c.InterventionType == "Service"),
                        TotalProjets = g.Count(c => c.InterventionType == "Project"),
                        TotalResolu = resolu,
                        TotalNonResolu = nonResolu,
                        TotalRecurrenceRequise = recurrence,
                        TauxResolution = total > 0 ? Math.Round((double)resolu / total * 100, 1) : 0,
                        TauxRecurrence = total > 0 ? Math.Round((double)recurrence / total * 100, 1) : 0,
                        TopCategorie = categories?.Key,
                        TopCategorieCount = categories?.Count() ?? 0,
                        DerniereIntervention = g.Max(c => c.InterventionDate),
                        TechniciensDistincts = g.Select(c => c.TechnicianId).Distinct().Count(),
                        RepartitionParCategorie = repartitionCat.Count > 0 ? repartitionCat : null,
                        RepartitionParPriorite = repartitionPrio.Count > 0 ? repartitionPrio : null
                    };
                })
                .OrderByDescending(s => s.TotalInterventions)
                .ToList();

                return Ok(ApiResponse<IEnumerable<SiteStatsDto>>.SuccessResponse(result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stats by site");
                return StatusCode(500, ApiResponse<IEnumerable<SiteStatsDto>>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques par site."));
            }
        }

        /// <summary>
        /// GET /api/global/stats/by-technician?period=30 - Statistiques par technicien
        /// </summary>
        [HttpGet("stats/by-technician")]
        public async Task<ActionResult<ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>>> GetStatsByTechnician(
            [FromQuery] int? period = null)
        {
            try
            {
                var baseQuery = FilterByPeriod(_context.CRIForms, period);

                var criList = await baseQuery
                    .Include(c => c.Technician)
                    .Select(c => new
                    {
                        c.TechnicianId,
                        TechPrenom = c.Technician != null ? c.Technician.FirstName ?? "" : "",
                        TechNom = c.Technician != null ? c.Technician.LastName ?? "" : "",
                        c.InterventionType,
                        c.Category,
                        c.DureeMinutes,
                        c.ResolutionStatus,
                        c.AdditionalInterventionRequired,
                        SiteNom = c.ClientSite ?? "",
                        ClientNom = c.ClientName ?? "",
                        c.InterventionDate
                    })
                    .ToListAsync();

                var grouped = criList.GroupBy(c => c.TechnicianId);

                var result = grouped.Select(g =>
                {
                    var total = g.Count();
                    var resolu = g.Count(c => c.ResolutionStatus == "resolu");
                    var nonResolu = g.Count(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu");
                    var recurrence = g.Count(c => c.AdditionalInterventionRequired == true);

                    // Résolution premier passage = résolu ET pas de récurrence
                    var resoluSansRecurrence = g.Count(c =>
                        c.ResolutionStatus == "resolu" && c.AdditionalInterventionRequired != true);

                    // Durées
                    var durees = g.Where(c => c.DureeMinutes > 0).Select(c => c.DureeMinutes ?? 0).ToList();
                    var totalHeures = durees.Sum() / 60.0;

                    // Top 5 sites
                    var topSites = g
                        .Where(c => !string.IsNullOrEmpty(c.SiteNom))
                        .GroupBy(c => c.SiteNom)
                        .OrderByDescending(sg => sg.Count())
                        .Take(5)
                        .Select(sg => sg.Key)
                        .ToList();

                    // Répartition par type
                    var repartitionType = new Dictionary<string, int>();
                    var services = g.Count(c => c.InterventionType == "Service");
                    var projets = g.Count(c => c.InterventionType == "Project");
                    if (services > 0) repartitionType["Service"] = services;
                    if (projets > 0) repartitionType["Projet"] = projets;

                    // Ajouter catégories
                    var categories = g
                        .Where(c => !string.IsNullOrEmpty(c.Category))
                        .GroupBy(c => c.Category)
                        .ToDictionary(cg => cg.Key!, cg => cg.Count());
                    foreach (var cat in categories)
                        repartitionType[cat.Key] = cat.Value;

                    var first = g.First();
                    return new TechnicianDetailedStatsDto
                    {
                        Id = g.Key,
                        Prenom = first.TechPrenom,
                        Nom = first.TechNom,
                        TotalInterventions = total,
                        SitesDistincts = g.Where(c => !string.IsNullOrEmpty(c.SiteNom)).Select(c => c.SiteNom).Distinct().Count(),
                        ClientsDistincts = g.Where(c => !string.IsNullOrEmpty(c.ClientNom)).Select(c => c.ClientNom).Distinct().Count(),
                        DureeMoyenneMinutes = durees.Count > 0 ? Math.Round(durees.Average(), 1) : null,
                        TotalHeures = Math.Round(totalHeures, 1),
                        TotalServices = services,
                        TotalProjets = projets,
                        TotalResolu = resolu,
                        TotalNonResolu = nonResolu,
                        TotalRecurrenceRequise = recurrence,
                        TauxResolution = total > 0 ? Math.Round((double)resolu / total * 100, 1) : 0,
                        TauxResolutionPremierPassage = total > 0 ? Math.Round((double)resoluSansRecurrence / total * 100, 1) : 0,
                        DerniereIntervention = g.Max(c => c.InterventionDate),
                        TopSites = topSites,
                        RepartitionParType = repartitionType.Count > 0 ? repartitionType : null
                    };
                })
                .OrderByDescending(t => t.TotalInterventions)
                .ToList();

                return Ok(ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>.SuccessResponse(result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stats by technician");
                return StatusCode(500, ApiResponse<IEnumerable<TechnicianDetailedStatsDto>>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques par technicien."));
            }
        }

        /// <summary>
        /// GET /api/global/stats/distribution?period=30 - Statistiques croisées
        /// </summary>
        [HttpGet("stats/distribution")]
        public async Task<ActionResult<ApiResponse<DistributionStatsDto>>> GetDistributionStats(
            [FromQuery] int? period = null)
        {
            try
            {
                var baseQuery = FilterByPeriod(_context.CRIForms, period);

                var criList = await baseQuery
                    .Include(c => c.Technician)
                    .Select(c => new
                    {
                        SiteNom = c.ClientSite ?? "(non renseigné)",
                        c.Category,
                        c.InterventionType,
                        c.Priority,
                        c.ResolutionStatus,
                        c.DureeMinutes,
                        c.Ville,
                        TechNom = c.Technician != null
                            ? (c.Technician.FirstName ?? "") + " " + (c.Technician.LastName ?? "")
                            : "Inconnu",
                        c.InterventionDate
                    })
                    .ToListAsync();

                var result = new DistributionStatsDto();

                // Catégorie par site (top 20 sites, top 5 catégories chacun)
                result.CategorieParSite = criList
                    .Where(c => !string.IsNullOrEmpty(c.Category) && c.SiteNom != "(non renseigné)")
                    .GroupBy(c => new { c.SiteNom, c.Category })
                    .Select(g => new CrossTabEntry
                    {
                        Ligne = g.Key.SiteNom,
                        Colonne = g.Key.Category!,
                        Valeur = g.Count()
                    })
                    .OrderByDescending(e => e.Valeur)
                    .Take(100)
                    .ToList();

                // Technicien par site
                result.TechnicienParSite = criList
                    .Where(c => c.SiteNom != "(non renseigné)")
                    .GroupBy(c => new { c.SiteNom, c.TechNom })
                    .Select(g => new CrossTabEntry
                    {
                        Ligne = g.Key.SiteNom,
                        Colonne = g.Key.TechNom,
                        Valeur = g.Count()
                    })
                    .OrderByDescending(e => e.Valeur)
                    .Take(100)
                    .ToList();

                // Priorité par résolution
                result.PrioriteParResolution = criList
                    .Where(c => !string.IsNullOrEmpty(c.Priority))
                    .GroupBy(c => c.Priority!)
                    .Select(g =>
                    {
                        var total = g.Count();
                        var resolu = g.Count(c => c.ResolutionStatus == "resolu");
                        var nonResolu = g.Count(c => c.ResolutionStatus == "nonResolu" || c.ResolutionStatus == "partiellementResolu");
                        return new PrioriteResolutionEntry
                        {
                            Priorite = g.Key,
                            Total = total,
                            Resolu = resolu,
                            NonResolu = nonResolu,
                            TauxResolution = total > 0 ? Math.Round((double)resolu / total * 100, 1) : 0,
                            DureeMoyenneMinutes = g.Where(c => c.DureeMinutes > 0)
                                .Select(c => (double?)c.DureeMinutes).DefaultIfEmpty().Average()
                        };
                    })
                    .OrderByDescending(p => p.Total)
                    .ToList();

                // Évolution mensuelle (12 derniers mois)
                var monthNames = new[] { "", "Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc" };
                result.EvolutionMensuelle = criList
                    .GroupBy(c => new { c.InterventionDate.Year, c.InterventionDate.Month })
                    .Select(g => new EvolutionMensuelleEntry
                    {
                        Annee = g.Key.Year,
                        Mois = g.Key.Month,
                        Label = $"{monthNames[g.Key.Month]} {g.Key.Year}",
                        TotalInterventions = g.Count(),
                        Services = g.Count(c => c.InterventionType == "Service"),
                        Projets = g.Count(c => c.InterventionType == "Project"),
                        Resolu = g.Count(c => c.ResolutionStatus == "resolu"),
                        DureeMoyenneMinutes = g.Where(c => c.DureeMinutes > 0)
                            .Select(c => (double?)c.DureeMinutes).DefaultIfEmpty().Average()
                    })
                    .OrderBy(e => e.Annee).ThenBy(e => e.Mois)
                    .ToList();

                // Répartition par ville
                result.RepartitionParVille = criList
                    .Where(c => !string.IsNullOrEmpty(c.Ville))
                    .GroupBy(c => c.Ville!)
                    .ToDictionary(g => g.Key, g => g.Count())
                    .OrderByDescending(kv => kv.Value)
                    .Take(20)
                    .ToDictionary(kv => kv.Key, kv => kv.Value);

                // Répartition par catégorie
                result.RepartitionParCategorie = criList
                    .Where(c => !string.IsNullOrEmpty(c.Category))
                    .GroupBy(c => c.Category!)
                    .ToDictionary(g => g.Key, g => g.Count())
                    .OrderByDescending(kv => kv.Value)
                    .ToDictionary(kv => kv.Key, kv => kv.Value);

                return Ok(ApiResponse<DistributionStatsDto>.SuccessResponse(result));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving distribution stats");
                return StatusCode(500, ApiResponse<DistributionStatsDto>.ErrorResponse(
                    "Erreur lors de la récupération des statistiques de distribution."));
            }
        }
    }
}
