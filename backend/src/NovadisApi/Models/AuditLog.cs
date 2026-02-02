using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("AuditLogs")]
    public class AuditLog
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid? UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Action { get; set; } = string.Empty; // Login, CreateCRI, UpdateCRI, etc.

        [MaxLength(100)]
        public string? EntityType { get; set; } // User, CRIForm, etc.

        public Guid? EntityId { get; set; }

        public string? Details { get; set; } // JSON avec les détails

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        [MaxLength(500)]
        public string? UserAgent { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Relations
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
