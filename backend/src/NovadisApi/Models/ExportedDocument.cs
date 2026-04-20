using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("ExportedDocuments")]
    public class ExportedDocument
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid UserId { get; set; }

        public Guid? CriId { get; set; }

        [Required]
        [MaxLength(300)]
        public string Filename { get; set; } = string.Empty;

        [Required]
        [MaxLength(10)]
        public string FileType { get; set; } = string.Empty; // pdf, xlsx

        [Required]
        [MaxLength(30)]
        public string ExportType { get; set; } = string.Empty; // cri, period-day, period-week, period-month, period-year

        [Required]
        [MaxLength(500)]
        public string StoragePath { get; set; } = string.Empty;

        public long SizeBytes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? SharedAt { get; set; }

        public DateTime? PeriodStart { get; set; }

        public DateTime? PeriodEnd { get; set; }

        [MaxLength(2000)]
        public string? Metadata { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
