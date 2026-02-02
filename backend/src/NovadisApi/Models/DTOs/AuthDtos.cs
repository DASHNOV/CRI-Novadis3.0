using System.ComponentModel.DataAnnotations;

namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Requête pour demander un code de connexion
    /// </summary>
    public class LoginRequestDto
    {
        [Required(ErrorMessage = "L'email est requis")]
        [EmailAddress(ErrorMessage = "Format d'email invalide")]
        public string Email { get; set; } = string.Empty;

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        [MaxLength(255)]
        public string? DeviceInfo { get; set; }
    }

    /// <summary>
    /// Requête pour vérifier le code reçu
    /// </summary>
    public class VerifyCodeRequestDto
    {
        [Required(ErrorMessage = "L'email est requis")]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Le code est requis")]
        [StringLength(6, MinimumLength = 6, ErrorMessage = "Le code doit contenir 6 chiffres")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Le code doit contenir uniquement des chiffres")]
        public string Code { get; set; } = string.Empty;

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        [MaxLength(255)]
        public string? DeviceInfo { get; set; }
    }

    /// <summary>
    /// Requête pour rafraîchir le token
    /// </summary>
    public class RefreshTokenRequestDto
    {
        [Required(ErrorMessage = "Le refresh token est requis")]
        public string RefreshToken { get; set; } = string.Empty;

        [MaxLength(45)]
        public string? IpAddress { get; set; }

        [MaxLength(255)]
        public string? DeviceInfo { get; set; }
    }

    /// <summary>
    /// Réponse après authentification réussie
    /// </summary>
    public class AuthResponseDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public UserDto User { get; set; } = null!;
    }

    /// <summary>
    /// Informations utilisateur
    /// </summary>
    public class UserDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string FullName => $"{FirstName} {LastName}";
        public string Role { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime? LastLoginAt { get; set; }
    }

    /// <summary>
    /// Réponse générique d'API
    /// </summary>
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; }
        public List<string>? Errors { get; set; }

        public static ApiResponse<T> SuccessResponse(T data, string message = "Opération réussie")
        {
            return new ApiResponse<T>
            {
                Success = true,
                Message = message,
                Data = data
            };
        }

        public static ApiResponse<T> ErrorResponse(string message, List<string>? errors = null)
        {
            return new ApiResponse<T>
            {
                Success = false,
                Message = message,
                Errors = errors
            };
        }
    }
}
