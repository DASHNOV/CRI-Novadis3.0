using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace NovadisApi.Models
{
    [Table("CRIPhotos")]
    public class CRIPhoto
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid CRIFormId { get; set; }

        [Required]
        [MaxLength(500)]
        [JsonIgnore]
        public string StoragePath { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? OriginalFileName { get; set; }

        [MaxLength(100)]
        public string? MimeType { get; set; }

        public long FileSize { get; set; }

        [MaxLength(255)]
        public string? Description { get; set; }

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        // Relations
        [ForeignKey("CRIFormId")]
        public virtual CRIForm? CRIForm { get; set; }
    }
}
