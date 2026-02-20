using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NovadisApi.Models.DTOs;
using NovadisApi.Services;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/sites")]
    [Authorize]
    public class SiteSummaryController : ControllerBase
    {
        private readonly ISiteSummaryService _service;

        public SiteSummaryController(ISiteSummaryService service)
        {
            _service = service;
        }

        [HttpGet("summary")]
        public async Task<ActionResult<ApiResponse<SiteSummaryDto>>> GetSummary([FromQuery] string siteName)
        {
            if (string.IsNullOrWhiteSpace(siteName))
            {
                return BadRequest(ApiResponse<SiteSummaryDto>.ErrorResponse("Le nom du site est requis"));
            }

            var summary = await _service.GetSummaryAsync(siteName);
            return Ok(ApiResponse<SiteSummaryDto>.SuccessResponse(summary));
        }
    }
}
