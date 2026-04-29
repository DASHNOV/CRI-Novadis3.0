using NovadisApi.Models.DTOs;

namespace NovadisApi.Services.Auth;

/// <summary>
/// Logique métier d'authentification (magic-link OTP + JWT + appareils de confiance).
/// </summary>
public interface IAuthService
{
    Task<AuthResult<LoginResponse>> RequestLoginCodeAsync(LoginRequestDto request, CancellationToken ct = default);
    Task<AuthResult<AuthResponseDto>> VerifyCodeAsync(VerifyCodeRequestDto request, CancellationToken ct = default);
    Task<AuthResult<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request, CancellationToken ct = default);
    Task<AuthResult<bool>> LogoutAsync(Guid userId, RefreshTokenRequestDto request, CancellationToken ct = default);
    Task<AuthResult<UserDto>> GetCurrentUserAsync(Guid userId, CancellationToken ct = default);
    Task<AuthResult<AuthResponseDto>> VerifyTrustedDeviceAsync(VerifyDeviceRequestDto request, CancellationToken ct = default);
}

public sealed record LoginResponse(int ExpiresIn);
