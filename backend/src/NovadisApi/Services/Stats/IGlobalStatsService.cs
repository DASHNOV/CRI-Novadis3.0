using NovadisApi.Models.DTOs;

namespace NovadisApi.Services.Stats;

/// <summary>
/// Logique métier pour les statistiques globales (dashboard admin).
/// </summary>
public interface IGlobalStatsService
{
    Task<GlobalStatsDto> GetGlobalStatsAsync(int? periodDays, CancellationToken ct = default);

    Task<IReadOnlyList<CRIWithTechnicianDto>> GetAllCRIsWithTechnicianAsync(
        Guid? technicienId, string filter, string? searchId, CancellationToken ct = default);

    Task<IReadOnlyList<TechnicianActivityDto>> GetTechnicianActivityAsync(CancellationToken ct = default);

    Task<IReadOnlyList<DailyActivityDto>> GetActivityChartDataAsync(CancellationToken ct = default);

    Task<IReadOnlyList<UserDto>> GetTechniciansAsync(CancellationToken ct = default);

    Task<IReadOnlyList<SiteStatsDto>> GetStatsBySiteAsync(int? periodDays, CancellationToken ct = default);

    Task<IReadOnlyList<TechnicianDetailedStatsDto>> GetStatsByTechnicianAsync(int? periodDays, CancellationToken ct = default);

    Task<DistributionStatsDto> GetDistributionStatsAsync(int? periodDays, CancellationToken ct = default);
}
