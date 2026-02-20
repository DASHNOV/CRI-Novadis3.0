namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques globales (admin uniquement)
    /// </summary>
    public class GlobalStatsDto
    {
        public int TotalCeMois { get; set; }
        public int TotalSignes { get; set; }
        public int TotalEnAttente { get; set; }
        public int TechniciensActifs { get; set; }
    }
}
