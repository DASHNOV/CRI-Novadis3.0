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
    }
}
