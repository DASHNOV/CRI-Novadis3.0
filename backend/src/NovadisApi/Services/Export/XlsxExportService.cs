using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Services.Export
{
    public enum ExportPeriod { Day, Week, Month, Year }

    public record PeriodRange(DateTime StartUtc, DateTime EndUtcExclusive, string Label);

    public interface IXlsxExportService
    {
        Task<(byte[] Bytes, string Filename)?> GenerateSingleCriAsync(Guid criId, Guid requesterId, bool isAdmin);
        Task<(byte[] Bytes, string Filename)> GeneratePeriodAsync(ExportPeriod period, DateTime referenceDate, Guid requesterId, bool isAdmin);
    }

    /// <summary>
    /// Génère des classeurs Excel (XLSX) professionnels pour les CRI.
    /// Utilise ClosedXML pour un rendu pro (entêtes, styles, autofilter, freeze).
    /// </summary>
    public class XlsxExportService : IXlsxExportService
    {
        private readonly NovadisDbContext _db;

        // Palette Novadis
        private static readonly XLColor HeaderBg = XLColor.FromHtml("#1A1A1A");
        private static readonly XLColor HeaderFg = XLColor.FromHtml("#FFFFFF");
        private static readonly XLColor AccentBg = XLColor.FromHtml("#8BB8E8");
        private static readonly XLColor ZebraBg = XLColor.FromHtml("#F5F6F8");
        private static readonly XLColor LabelBg = XLColor.FromHtml("#EEF1F5");

        public XlsxExportService(NovadisDbContext db)
        {
            _db = db;
        }

        // ──────────────────────────────────────────────────────────
        // Export d'un CRI unique
        // ──────────────────────────────────────────────────────────
        public async Task<(byte[] Bytes, string Filename)?> GenerateSingleCriAsync(Guid criId, Guid requesterId, bool isAdmin)
        {
            var cri = await _db.CRIForms
                .Include(c => c.Technician)
                .Include(c => c.Site)
                .Include(c => c.Client)
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == criId);

            if (cri == null) return null;
            if (!isAdmin && cri.TechnicianId != requesterId) return null;

            using var wb = new XLWorkbook();
            BuildCriDetailSheet(wb, cri);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);

            var typeLabel = string.IsNullOrWhiteSpace(cri.InterventionType) ? "cri" : cri.InterventionType.ToLowerInvariant();
            var filename = $"novadis-{typeLabel}-{cri.InterventionDate:yyyyMMdd}-{cri.Id.ToString()[..8]}.xlsx";
            return (ms.ToArray(), filename);
        }

        private static void BuildCriDetailSheet(XLWorkbook wb, CRIForm cri)
        {
            var ws = wb.Worksheets.Add("Détail CRI");
            ws.ShowGridLines = false;

            // Bandeau titre
            var title = ws.Range("A1:D1").Merge();
            title.Value = cri.InterventionType == "Service" ? "Compte-rendu d'intervention — Service" : "Compte-rendu d'intervention — Projet";
            title.Style.Font.FontSize = 16;
            title.Style.Font.Bold = true;
            title.Style.Font.FontColor = HeaderFg;
            title.Style.Fill.BackgroundColor = HeaderBg;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Left;
            ws.Row(1).Height = 28;

            // Bloc identifiant + date
            var row = 3;
            ws.Cell(row, 1).Value = "Identifiant"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Id.ToString();
            ws.Cell(row, 3).Value = "Statut"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Status;
            row++;

            ws.Cell(row, 1).Value = "Date intervention"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.InterventionDate;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy";
            ws.Cell(row, 3).Value = "Durée"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = FormatDuration(cri);
            row++;

            ws.Cell(row, 1).Value = "Heure début"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.HeureDebut.HasValue ? cri.HeureDebut.Value.ToString(@"hh\:mm") : "-";
            ws.Cell(row, 3).Value = "Heure fin"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.HeureFin.HasValue ? cri.HeureFin.Value.ToString(@"hh\:mm") : "-";
            row++;

            row++;
            SectionHeader(ws, row++, "Technicien");
            ws.Cell(row, 1).Value = "Nom"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Technician != null
                ? $"{cri.Technician.FirstName} {cri.Technician.LastName}".Trim()
                : cri.TechnicianId.ToString();
            ws.Cell(row, 3).Value = "Email"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Technician?.Email ?? "-";
            row += 2;

            SectionHeader(ws, row++, "Client");
            ws.Cell(row, 1).Value = "Nom"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.ClientName;
            ws.Cell(row, 3).Value = "Contact"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.ClientContact ?? "-";
            row++;
            ws.Cell(row, 1).Value = "Téléphone"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.ClientPhone ?? "-";
            ws.Cell(row, 3).Value = "Email"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.ClientEmail ?? "-";
            row++;
            ws.Cell(row, 1).Value = "Adresse"; StyleLabel(ws.Cell(row, 1));
            ws.Range(row, 2, row, 4).Merge().Value = FormatAddress(cri);
            row += 2;

            SectionHeader(ws, row++, "Site");
            ws.Cell(row, 1).Value = "Nom du site"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.Site?.NomDuSite ?? cri.ClientSite ?? "-";
            ws.Cell(row, 3).Value = "Numéro"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Site?.Numero.ToString() ?? "-";
            row += 2;

            SectionHeader(ws, row++, "Intervention");
            ws.Cell(row, 1).Value = "Type"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.InterventionType;
            ws.Cell(row, 3).Value = "Catégorie"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = cri.Category;
            row++;

            if (cri.InterventionType == "Service")
            {
                ws.Cell(row, 1).Value = "Numéro ticket"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.TicketNumber ?? "-";
                ws.Cell(row, 3).Value = "Priorité"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.Priority ?? "-";
                row++;
                ws.Cell(row, 1).Value = "Statut résolution"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ResolutionStatus ?? "-";
                ws.Cell(row, 3).Value = "Nouvelle intervention"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.AdditionalInterventionRequired == true ? "Oui" : "Non";
                row++;
            }
            else if (cri.InterventionType == "Project" || cri.InterventionType == "Projet")
            {
                ws.Cell(row, 1).Value = "Nom projet"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ProjectName ?? "-";
                ws.Cell(row, 3).Value = "Numéro projet"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.ProjectNumber ?? "-";
                row++;
                ws.Cell(row, 1).Value = "Phase"; StyleLabel(ws.Cell(row, 1));
                ws.Cell(row, 2).Value = cri.ProjectPhase ?? "-";
                ws.Cell(row, 3).Value = "Statut projet"; StyleLabel(ws.Cell(row, 3));
                ws.Cell(row, 4).Value = cri.ProjectStatus ?? "-";
                row++;
            }

            row++;
            SectionHeader(ws, row++, "Description des travaux");
            var descr = ws.Range(row, 1, row, 4).Merge();
            descr.Value = cri.WorkDescription ?? "-";
            descr.Style.Alignment.WrapText = true;
            descr.Style.Alignment.Vertical = XLAlignmentVerticalValues.Top;
            ws.Row(row).Height = 60;
            row += 2;

            if (!string.IsNullOrWhiteSpace(cri.MaterialsUsed))
            {
                SectionHeader(ws, row++, "Matériel utilisé");
                var mat = ws.Range(row, 1, row, 4).Merge();
                mat.Value = cri.MaterialsUsed;
                mat.Style.Alignment.WrapText = true;
                mat.Style.Alignment.Vertical = XLAlignmentVerticalValues.Top;
                ws.Row(row).Height = 50;
                row += 2;
            }

            SectionHeader(ws, row++, "Métadonnées");
            ws.Cell(row, 1).Value = "Créé le"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = cri.CreatedAt;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
            ws.Cell(row, 3).Value = "Soumis le"; StyleLabel(ws.Cell(row, 3));
            if (cri.SubmittedAt.HasValue)
            {
                ws.Cell(row, 4).Value = cri.SubmittedAt.Value;
                ws.Cell(row, 4).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
            }
            else
            {
                ws.Cell(row, 4).Value = "-";
            }

            ws.Column(1).Width = 22;
            ws.Column(2).Width = 42;
            ws.Column(3).Width = 22;
            ws.Column(4).Width = 42;
        }

        // ──────────────────────────────────────────────────────────
        // Export période (jour / semaine / mois / année)
        // ──────────────────────────────────────────────────────────
        public async Task<(byte[] Bytes, string Filename)> GeneratePeriodAsync(
            ExportPeriod period, DateTime referenceDate, Guid requesterId, bool isAdmin)
        {
            var range = ComputeRange(period, referenceDate);

            IQueryable<CRIForm> query = _db.CRIForms
                .Include(c => c.Technician)
                .Include(c => c.Site)
                .AsNoTracking()
                .Where(c => c.InterventionDate >= range.StartUtc && c.InterventionDate < range.EndUtcExclusive);

            if (!isAdmin)
            {
                query = query.Where(c => c.TechnicianId == requesterId);
            }

            var cris = await query.OrderBy(c => c.InterventionDate).ToListAsync();

            using var wb = new XLWorkbook();
            BuildSummarySheet(wb, cris, period, range, isAdmin);
            BuildInterventionsSheet(wb, cris);
            if (cris.Count > 0)
            {
                BuildBySiteSheet(wb, cris);
                if (isAdmin)
                {
                    BuildByTechnicianSheet(wb, cris);
                }
            }

            using var ms = new MemoryStream();
            wb.SaveAs(ms);

            var scope = isAdmin ? "global" : "personnel";
            var filename = $"novadis-{PeriodSlug(period)}-{scope}-{range.StartUtc:yyyyMMdd}.xlsx";
            return (ms.ToArray(), filename);
        }

        private static void BuildSummarySheet(XLWorkbook wb, List<CRIForm> cris, ExportPeriod period, PeriodRange range, bool isAdmin)
        {
            var ws = wb.Worksheets.Add("Résumé");
            ws.ShowGridLines = false;

            var title = ws.Range("A1:D1").Merge();
            title.Value = $"Synthèse CRI — {range.Label}";
            title.Style.Font.FontSize = 16;
            title.Style.Font.Bold = true;
            title.Style.Font.FontColor = HeaderFg;
            title.Style.Fill.BackgroundColor = HeaderBg;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(1).Height = 28;

            var row = 3;
            ws.Cell(row, 1).Value = "Période"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = PeriodLabel(period);
            ws.Cell(row, 3).Value = "Portée"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = isAdmin ? "Tous les techniciens" : "Mes CRI";
            row++;

            ws.Cell(row, 1).Value = "Début"; StyleLabel(ws.Cell(row, 1));
            ws.Cell(row, 2).Value = range.StartUtc;
            ws.Cell(row, 2).Style.DateFormat.Format = "dd/MM/yyyy";
            ws.Cell(row, 3).Value = "Fin"; StyleLabel(ws.Cell(row, 3));
            ws.Cell(row, 4).Value = range.EndUtcExclusive.AddDays(-1);
            ws.Cell(row, 4).Style.DateFormat.Format = "dd/MM/yyyy";
            row += 2;

            SectionHeader(ws, row++, "Indicateurs clés");

            var total = cris.Count;
            var soumis = cris.Count(c => c.Status != "Draft");
            var brouillons = cris.Count(c => c.Status == "Draft");
            var services = cris.Count(c => c.InterventionType == "Service");
            var projets = total - services;
            var dureeTotale = cris.Sum(c => c.DureeMinutes ?? 0);
            var dureeMoyenne = total > 0 ? (double)dureeTotale / total / 60.0 : 0.0;
            var sites = cris.Select(c => c.Site?.NomDuSite ?? c.ClientSite ?? "").Where(s => !string.IsNullOrWhiteSpace(s)).Distinct().Count();
            var techniciens = cris.Select(c => c.TechnicianId).Distinct().Count();
            var resolus = cris.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
            var tauxResolution = total > 0 ? (double)resolus / total * 100.0 : 0.0;

            WriteKpi(ws, ref row, "Total CRI", total);
            WriteKpi(ws, ref row, "CRI soumis", soumis);
            WriteKpi(ws, ref row, "Brouillons", brouillons);
            WriteKpi(ws, ref row, "CRI Service", services);
            WriteKpi(ws, ref row, "CRI Projet", projets);
            WriteKpi(ws, ref row, "Durée totale (h)", Math.Round(dureeTotale / 60.0, 2));
            WriteKpi(ws, ref row, "Durée moyenne (h)", Math.Round(dureeMoyenne, 2));
            WriteKpi(ws, ref row, "Sites distincts", sites);
            if (isAdmin)
            {
                WriteKpi(ws, ref row, "Techniciens actifs", techniciens);
            }
            WriteKpi(ws, ref row, "Taux résolution (%)", Math.Round(tauxResolution, 1));

            ws.Column(1).Width = 26;
            ws.Column(2).Width = 22;
            ws.Column(3).Width = 26;
            ws.Column(4).Width = 26;
        }

        private static void BuildInterventionsSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Interventions");

            string[] headers = {
                "Date", "Type", "Catégorie", "Numéro ticket/projet", "Statut",
                "Client", "Site", "Ville", "Technicien", "Priorité",
                "Durée (h)", "Heure début", "Heure fin", "Résolution", "Soumis le"
            };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var r = 2;
            foreach (var cri in cris)
            {
                ws.Cell(r, 1).Value = cri.InterventionDate;
                ws.Cell(r, 1).Style.DateFormat.Format = "dd/MM/yyyy";
                ws.Cell(r, 2).Value = cri.InterventionType;
                ws.Cell(r, 3).Value = cri.Category;
                ws.Cell(r, 4).Value = cri.TicketNumber ?? cri.ProjectNumber ?? "-";
                ws.Cell(r, 5).Value = cri.Status;
                ws.Cell(r, 6).Value = cri.ClientName;
                ws.Cell(r, 7).Value = cri.Site?.NomDuSite ?? cri.ClientSite ?? "-";
                ws.Cell(r, 8).Value = cri.Ville ?? cri.Site?.Ville ?? "-";
                ws.Cell(r, 9).Value = cri.Technician != null
                    ? $"{cri.Technician.FirstName} {cri.Technician.LastName}".Trim()
                    : "-";
                ws.Cell(r, 10).Value = cri.Priority ?? "-";
                ws.Cell(r, 11).Value = cri.DureeMinutes.HasValue ? Math.Round(cri.DureeMinutes.Value / 60.0, 2) : 0;
                ws.Cell(r, 12).Value = cri.HeureDebut?.ToString(@"hh\:mm") ?? "-";
                ws.Cell(r, 13).Value = cri.HeureFin?.ToString(@"hh\:mm") ?? "-";
                ws.Cell(r, 14).Value = cri.ResolutionStatus ?? cri.ProjectStatus ?? "-";
                if (cri.SubmittedAt.HasValue)
                {
                    ws.Cell(r, 15).Value = cri.SubmittedAt.Value;
                    ws.Cell(r, 15).Style.DateFormat.Format = "dd/MM/yyyy HH:mm";
                }
                else
                {
                    ws.Cell(r, 15).Value = "-";
                }

                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }
                r++;
            }

            if (cris.Count == 0)
            {
                var empty = ws.Range(2, 1, 2, headers.Length).Merge();
                empty.Value = "Aucune intervention sur la période";
                empty.Style.Font.Italic = true;
                empty.Style.Font.FontColor = XLColor.FromHtml("#828AA0");
                empty.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            }
            else
            {
                ws.Range(1, 1, r - 1, headers.Length).SetAutoFilter();
            }

            double[] widths = { 12, 12, 16, 18, 12, 22, 22, 16, 22, 12, 12, 12, 12, 20, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }
        }

        private static void BuildBySiteSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Par site");

            string[] headers = { "Site", "Nb interventions", "Durée totale (h)", "Durée moyenne (h)", "Résolus", "Taux résolution (%)" };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var groups = cris
                .GroupBy(c => c.Site?.NomDuSite ?? c.ClientSite ?? "(sans site)")
                .Select(g =>
                {
                    var count = g.Count();
                    var totalMinutes = g.Sum(c => c.DureeMinutes ?? 0);
                    var resolus = g.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
                    return new
                    {
                        Site = g.Key,
                        Count = count,
                        TotalHours = Math.Round(totalMinutes / 60.0, 2),
                        AvgHours = count > 0 ? Math.Round(totalMinutes / (double)count / 60.0, 2) : 0.0,
                        Resolus = resolus,
                        Taux = count > 0 ? Math.Round(resolus / (double)count * 100.0, 1) : 0.0,
                    };
                })
                .OrderByDescending(x => x.Count)
                .ToList();

            var r = 2;
            foreach (var g in groups)
            {
                ws.Cell(r, 1).Value = g.Site;
                ws.Cell(r, 2).Value = g.Count;
                ws.Cell(r, 3).Value = g.TotalHours;
                ws.Cell(r, 4).Value = g.AvgHours;
                ws.Cell(r, 5).Value = g.Resolus;
                ws.Cell(r, 6).Value = g.Taux;
                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }
                r++;
            }

            if (groups.Count > 0)
            {
                ws.Range(1, 1, r - 1, headers.Length).SetAutoFilter();
            }
            double[] widths = { 32, 14, 16, 18, 12, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }
        }

        private static void BuildByTechnicianSheet(XLWorkbook wb, List<CRIForm> cris)
        {
            var ws = wb.Worksheets.Add("Par technicien");

            string[] headers = { "Technicien", "Email", "Nb interventions", "Durée totale (h)", "Durée moyenne (h)", "Résolus", "Taux résolution (%)" };
            for (var i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
            }
            StyleHeader(ws.Range(1, 1, 1, headers.Length));
            ws.SheetView.FreezeRows(1);

            var groups = cris
                .GroupBy(c => new
                {
                    c.TechnicianId,
                    Name = c.Technician != null ? $"{c.Technician.FirstName} {c.Technician.LastName}".Trim() : c.TechnicianId.ToString(),
                    Email = c.Technician?.Email ?? "-"
                })
                .Select(g =>
                {
                    var count = g.Count();
                    var totalMinutes = g.Sum(c => c.DureeMinutes ?? 0);
                    var resolus = g.Count(c => c.ResolutionStatus == "resolu" || c.ProjectStatus == "termine");
                    return new
                    {
                        g.Key.Name,
                        g.Key.Email,
                        Count = count,
                        TotalHours = Math.Round(totalMinutes / 60.0, 2),
                        AvgHours = count > 0 ? Math.Round(totalMinutes / (double)count / 60.0, 2) : 0.0,
                        Resolus = resolus,
                        Taux = count > 0 ? Math.Round(resolus / (double)count * 100.0, 1) : 0.0,
                    };
                })
                .OrderByDescending(x => x.Count)
                .ToList();

            var r = 2;
            foreach (var g in groups)
            {
                ws.Cell(r, 1).Value = g.Name;
                ws.Cell(r, 2).Value = g.Email;
                ws.Cell(r, 3).Value = g.Count;
                ws.Cell(r, 4).Value = g.TotalHours;
                ws.Cell(r, 5).Value = g.AvgHours;
                ws.Cell(r, 6).Value = g.Resolus;
                ws.Cell(r, 7).Value = g.Taux;
                if (r % 2 == 0)
                {
                    ws.Range(r, 1, r, headers.Length).Style.Fill.BackgroundColor = ZebraBg;
                }
                r++;
            }

            if (groups.Count > 0)
            {
                ws.Range(1, 1, r - 1, headers.Length).SetAutoFilter();
            }
            double[] widths = { 28, 28, 16, 18, 18, 12, 18 };
            for (var i = 0; i < widths.Length; i++)
            {
                ws.Column(i + 1).Width = widths[i];
            }
        }

        // ──────────────────────────────────────────────────────────
        // Helpers
        // ──────────────────────────────────────────────────────────
        private static void StyleHeader(IXLRange range)
        {
            range.Style.Font.Bold = true;
            range.Style.Font.FontColor = HeaderFg;
            range.Style.Fill.BackgroundColor = HeaderBg;
            range.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            range.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
            range.Style.Border.BottomBorderColor = AccentBg;
            range.Worksheet.Row(range.RangeAddress.FirstAddress.RowNumber).Height = 22;
        }

        private static void StyleLabel(IXLCell cell)
        {
            cell.Style.Fill.BackgroundColor = LabelBg;
            cell.Style.Font.Bold = true;
            cell.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
        }

        private static void SectionHeader(IXLWorksheet ws, int row, string text)
        {
            var range = ws.Range(row, 1, row, 4).Merge();
            range.Value = text;
            range.Style.Font.Bold = true;
            range.Style.Font.FontColor = HeaderFg;
            range.Style.Fill.BackgroundColor = AccentBg;
            range.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(row).Height = 20;
        }

        private static void WriteKpi(IXLWorksheet ws, ref int row, string label, object value)
        {
            ws.Cell(row, 1).Value = label; StyleLabel(ws.Cell(row, 1));
            var cell = ws.Cell(row, 2);
            switch (value)
            {
                case int i: cell.Value = i; break;
                case double d: cell.Value = d; break;
                default: cell.Value = value?.ToString() ?? "-"; break;
            }
            cell.Style.Font.Bold = true;
            cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
            row++;
        }

        private static string FormatAddress(CRIForm cri)
        {
            var parts = new[]
            {
                cri.ClientAddress,
                cri.CodePostal,
                cri.Ville,
                cri.Pays,
            }.Where(p => !string.IsNullOrWhiteSpace(p));
            var joined = string.Join(", ", parts);
            return string.IsNullOrWhiteSpace(joined) ? "-" : joined;
        }

        private static string FormatDuration(CRIForm cri)
        {
            if (cri.DureeMinutes.HasValue && cri.DureeMinutes.Value > 0)
            {
                var h = cri.DureeMinutes.Value / 60;
                var m = cri.DureeMinutes.Value % 60;
                return $"{h}h{m:D2}";
            }
            if (cri.Duration.HasValue)
            {
                return $"{cri.Duration.Value:0.##}h";
            }
            return "-";
        }

        private static PeriodRange ComputeRange(ExportPeriod period, DateTime referenceDate)
        {
            var date = referenceDate.Date;
            return period switch
            {
                ExportPeriod.Day => new PeriodRange(
                    DateTime.SpecifyKind(date, DateTimeKind.Utc),
                    DateTime.SpecifyKind(date.AddDays(1), DateTimeKind.Utc),
                    $"Journée du {date:dd/MM/yyyy}"),
                ExportPeriod.Week => BuildWeekRange(date),
                ExportPeriod.Month => new PeriodRange(
                    DateTime.SpecifyKind(new DateTime(date.Year, date.Month, 1), DateTimeKind.Utc),
                    DateTime.SpecifyKind(new DateTime(date.Year, date.Month, 1).AddMonths(1), DateTimeKind.Utc),
                    $"Mois de {new DateTime(date.Year, date.Month, 1):MMMM yyyy}"),
                ExportPeriod.Year => new PeriodRange(
                    DateTime.SpecifyKind(new DateTime(date.Year, 1, 1), DateTimeKind.Utc),
                    DateTime.SpecifyKind(new DateTime(date.Year + 1, 1, 1), DateTimeKind.Utc),
                    $"Année {date.Year}"),
                _ => throw new ArgumentOutOfRangeException(nameof(period))
            };
        }

        private static PeriodRange BuildWeekRange(DateTime date)
        {
            // Semaine ISO (lundi = début)
            var diff = ((int)date.DayOfWeek + 6) % 7; // lundi = 0
            var monday = date.AddDays(-diff);
            var nextMonday = monday.AddDays(7);
            return new PeriodRange(
                DateTime.SpecifyKind(monday, DateTimeKind.Utc),
                DateTime.SpecifyKind(nextMonday, DateTimeKind.Utc),
                $"Semaine du {monday:dd/MM/yyyy} au {nextMonday.AddDays(-1):dd/MM/yyyy}");
        }

        private static string PeriodSlug(ExportPeriod period) => period switch
        {
            ExportPeriod.Day => "jour",
            ExportPeriod.Week => "semaine",
            ExportPeriod.Month => "mois",
            ExportPeriod.Year => "annee",
            _ => "periode"
        };

        private static string PeriodLabel(ExportPeriod period) => period switch
        {
            ExportPeriod.Day => "Jour",
            ExportPeriod.Week => "Semaine",
            ExportPeriod.Month => "Mois",
            ExportPeriod.Year => "Année",
            _ => "Période"
        };
    }
}
