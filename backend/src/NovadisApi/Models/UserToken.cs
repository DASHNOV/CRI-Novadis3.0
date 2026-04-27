using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NovadisApi.Models
{
    [Table("UserTokens")]
    public class UserToken
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [Required]
        public string RefreshToken { get; set; } = string.Empty;

        public string TokenType { get; set; } = "Refresh"; // Refresh, Access, etc.

        [MaxLength(255)]
        public string? DeviceInfo { get; set; }

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpiresAt { get; set; }

        public bool IsRevoked { get; set; } = false;

        public string? RevokedReason { get; set; }

        [MaxLength(128)]
        public string? TrustedDeviceToken { get; set; }
    }
}
