using NovadisApi.Models.DTOs;

namespace NovadisApi.Services
{
    public interface ISiteSummaryService
    {
        Task<SiteSummaryDto> GetSummaryAsync(string siteName);
    }
}
