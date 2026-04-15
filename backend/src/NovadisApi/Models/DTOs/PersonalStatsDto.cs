namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Statistiques personnelles d'un technicien
    /// </summary>
    public class PersonalStatsDto
    {
        public int CriCeMois { get; set; }
        public int CriEnCours { get; set; }
        public int CriEnAttente { get; set; }

        // Stats enrichies Phase 1
        public double? DureeMoyenneMinutes { get; set; }
        public int TotalResolu { get; set; }
        public int TotalNonResolu { get; set; }
        public int TotalRecurrenceRequise { get; set; }
    }
}
