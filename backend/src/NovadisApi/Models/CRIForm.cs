using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("CRIForms")]
    public class CRIForm
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid TechnicianId { get; set; }

        [Required]
        [MaxLength(50)]
        public string InterventionType { get; set; } = string.Empty; // Project, Service

        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty; // Installation, Maintenance, etc.

        [Required]
        public DateTime InterventionDate { get; set; }

        [Required]
        [MaxLength(255)]
        public string ClientName { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? ClientAddress { get; set; }

        [MaxLength(255)]
        public string? ClientSite { get; set; }

        [MaxLength(20)]
        public string? ClientPhone { get; set; }

        [EmailAddress]
        [MaxLength(255)]
        public string? ClientEmail { get; set; }

        public string? WorkDescription { get; set; }

        public string? MaterialsUsed { get; set; }

        public decimal? Duration { get; set; } // En heures

        [MaxLength(50)]
        public string Status { get; set; } = "Draft"; // Draft, Submitted, Validated

        // ✅ Champ pour stocker toutes les données spécifiques (JSON)
        public string? Data { get; set; }

        public string? TechnicianSignature { get; set; } // Base64

        public string? ClientSignature { get; set; } // Base64

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public DateTime? SubmittedAt { get; set; }

        // Relations
        [ForeignKey("TechnicianId")]
        public virtual User? Technician { get; set; }

        public virtual ICollection<CRIPhoto> Photos { get; set; } = new List<CRIPhoto>();
    }
}
