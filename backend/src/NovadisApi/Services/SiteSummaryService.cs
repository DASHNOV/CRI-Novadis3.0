using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace NovadisApi.Services
{
    public class SiteSummaryService : ISiteSummaryService
    {
        private readonly NovadisDbContext _context;

        public SiteSummaryService(NovadisDbContext context)
        {
            _context = context;
        }

        public async Task<SiteSummaryDto> GetSummaryAsync(string siteName)
        {
            var summary = new SiteSummaryDto { SiteName = siteName };

            // 1. Fetch CRIs for the site
            // We fetch the latest 50 to avoid loading too much data, assuming that's enough for history
            var cris = await _context.CRIForms
                .Where(c => c.ClientSite == siteName)
                .OrderByDescending(c => c.InterventionDate)
                .Take(50)
                .ToListAsync();

            if (!cris.Any())
            {
                return summary;
            }

            var processedCris = new List<ProcessedCri>();

            foreach (var cri in cris)
            {
                if (string.IsNullOrEmpty(cri.Data)) continue;

                try
                {
                    var json = JsonNode.Parse(cri.Data);
                    if (json == null) continue;

                    processedCris.Add(new ProcessedCri
                    {
                        Date = cri.InterventionDate,
                        TechnicianName = GetJsonString(json, "technicianName") ?? "Inconnu",
                        IdentifiedCause = GetJsonString(json, "identifiedCause"),
                        ReplacedParts = GetJsonString(json, "replacedParts"),
                        Recommendations = GetJsonString(json, "recommendations"),
                        CybersecurityRecommendations = GetJsonString(json, "cybersecurityRecommendations"),
                        Priority = GetJsonString(json, "priority") ?? "normale",
                        ResolutionStatus = GetJsonString(json, "resolutionStatus") ?? "nonResolu"
                    });
                }
                catch
                {
                    // Ignore malformed JSON
                }
            }

            if (!processedCris.Any()) return summary;

            // A. Flash Info
            // Status de la dernière visite
            var lastCri = processedCris.First();
            summary.LastVisitStatus = MapResolutionStatus(lastCri.ResolutionStatus);

            // Récurrence (6 derniers mois)
            var sixMonthsAgo = DateTime.Now.AddMonths(-6);
            summary.RecurrenceLast6Months = processedCris.Count(c => c.Date >= sixMonthsAgo);

            // Urgence: Tickets haute priorité non soldés
            // Priority: haute, critique
            // Status: != resolu
            summary.HasUrgentPendingTickets = processedCris.Any(c => 
                (c.Priority == "haute" || c.Priority == "critique") && 
                c.ResolutionStatus != "resolu");

            // B. Timeline Critique (3 derniers événements)
            summary.Timeline = processedCris.Take(3).Select(c => new SiteTimelineEventDto
            {
                Date = c.Date,
                IdentifiedCause = c.IdentifiedCause ?? "Non spécifié",
                ReplacedParts = c.ReplacedParts ?? "-",
                TechnicianName = c.TechnicianName,
                Status = MapResolutionStatus(c.ResolutionStatus)
            }).ToList();

            // C. Héritage Technique
            var recommendations = processedCris
                .Where(c => !string.IsNullOrWhiteSpace(c.Recommendations))
                .Select(c => c.Recommendations!)
                .Take(2)
                .ToList();

            var cyberRecs = processedCris
                .Where(c => !string.IsNullOrWhiteSpace(c.CybersecurityRecommendations))
                .Select(c => "Cyber: " + c.CybersecurityRecommendations!)
                .Take(1)
                .ToList();
            
            summary.Recommendations.AddRange(recommendations);
            summary.Recommendations.AddRange(cyberRecs);

            // D. Analyse de Chronicité
            // Identical identifiedCause > 2 times in 3 months
            var threeMonthsAgo = DateTime.Now.AddMonths(-3);
            var recentCauses = processedCris
                .Where(c => c.Date >= threeMonthsAgo && !string.IsNullOrWhiteSpace(c.IdentifiedCause))
                .GroupBy(c => c.IdentifiedCause!.Trim().ToLowerInvariant())
                .Where(g => g.Count() > 2)
                .Select(g => g.First().IdentifiedCause)
                .FirstOrDefault();

            if (recentCauses != null)
            {
                summary.ChronicityAlert = true;
                summary.ChronicProblemDescription = recentCauses;
            }

            return summary;
        }

        private string? GetJsonString(JsonNode json, string propertyName)
        {
            return json[propertyName]?.GetValue<string>();
        }

        private string MapResolutionStatus(string status)
        {
            return status switch
            {
                "resolu" => "Résolu",
                "partiellementResolu" => "Partiel",
                "nonResolu" => "Non Résolu",
                "enAttentePieces" => "Non Résolu (Pièces)",
                "escaladeNiveau2" => "Non Résolu (Escalade)",
                _ => "Inconnu"
            };
        }

        private class ProcessedCri
        {
            public DateTime Date { get; set; }
            public string TechnicianName { get; set; } = string.Empty;
            public string? IdentifiedCause { get; set; }
            public string? ReplacedParts { get; set; }
            public string? Recommendations { get; set; }
            public string? CybersecurityRecommendations { get; set; }
            public string Priority { get; set; } = string.Empty;
            public string ResolutionStatus { get; set; } = string.Empty;
        }
    }
}
