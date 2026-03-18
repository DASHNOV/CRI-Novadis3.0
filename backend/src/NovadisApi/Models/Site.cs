using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("Sites")]
    public class Site
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Numero { get; set; }

        [Required]
        [MaxLength(500)]
        public string NomDuSite { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Adresse { get; set; }

        [MaxLength(255)]
        public string? Ville { get; set; }

        [MaxLength(20)]
        public string? CodePostal { get; set; }

        [MaxLength(100)]
        public string? Pays { get; set; }

        [MaxLength(255)]
        public string? ResponsableDorigine { get; set; }

        public DateTime? DateDeCreation { get; set; }
    }
}
