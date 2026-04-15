using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    /// <summary>
    /// Client normalisé — dédupliqué depuis les CRI.
    /// Permet les statistiques par client (top clients, récurrence, historique).
    /// </summary>
    [Table("ClientsNormalises")]
    public class Client
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(255)]
        public string RaisonSociale { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? Contact { get; set; }

        [MaxLength(20)]
        public string? Telephone { get; set; }

        [EmailAddress]
        [MaxLength(255)]
        public string? Email { get; set; }

        [MaxLength(500)]
        public string? Adresse { get; set; }

        [MaxLength(10)]
        public string? CodePostal { get; set; }

        [MaxLength(100)]
        public string? Ville { get; set; }

        [MaxLength(100)]
        public string? Pays { get; set; }

        public bool Actif { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Relations
        public virtual ICollection<CRIForm> CRIForms { get; set; } = new List<CRIForm>();
    }
}
