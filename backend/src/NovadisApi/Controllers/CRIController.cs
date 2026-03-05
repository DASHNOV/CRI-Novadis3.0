using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;
using NovadisApi.Models;
using NovadisApi.Models.DTOs;
using System.Security.Claims;

namespace NovadisApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CRIController : ControllerBase
    {
        private readonly NovadisDbContext _context;
        private readonly ILogger<CRIController> _logger;

        public CRIController(NovadisDbContext context, ILogger<CRIController> logger)
        {
            _context = context;
            _logger = logger;
        }

        private Guid? GetCurrentUserId()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("userId")?.Value;
            if (Guid.TryParse(userIdStr, out var userId))
                return userId;
            return null;
        }

        [HttpGet]
        public async Task<ActionResult<ApiResponse<IEnumerable<CRIForm>>>> GetMyCRIs()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<IEnumerable<CRIForm>>.ErrorResponse("Utilisateur non identifié"));

            IQueryable<CRIForm> query = _context.CRIForms;
            
            // Si ce n'est pas un admin, on ne montre que ses propres CRIs
            if (!User.IsInRole("Admin"))
            {
                query = query.Where(c => c.TechnicianId == userId.Value);
            }

            var cris = await query
                .OrderByDescending(c => c.CreatedAt)
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<CRIForm>>.SuccessResponse(cris));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<CRIForm>>> GetCRI(Guid id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms
                .Include(c => c.Photos)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (cri == null)
                return NotFound(ApiResponse<CRIForm>.ErrorResponse("CRI introuvable"));

            // Les admins peuvent tout voir, les techniciens seulement les leurs
            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            return Ok(ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        [HttpPost]
        public async Task<ActionResult<ApiResponse<CRIForm>>> CreateCRI([FromBody] CRIForm cri)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            cri.Id = cri.Id == Guid.Empty ? Guid.NewGuid() : cri.Id;
            cri.TechnicianId = userId.Value;
            cri.CreatedAt = DateTime.UtcNow;

            _context.CRIForms.Add(cri);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCRI), new { id = cri.Id }, ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<ApiResponse<CRIForm>>> UpdateCRI(Guid id, [FromBody] CRIForm criUpdate)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<CRIForm>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);

            if (cri == null)
                return NotFound(ApiResponse<CRIForm>.ErrorResponse("CRI introuvable"));

            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            // Mise à jour des champs
            cri.InterventionType = criUpdate.InterventionType;
            cri.Category = criUpdate.Category;
            cri.InterventionDate = criUpdate.InterventionDate;
            cri.ClientName = criUpdate.ClientName;
            cri.ClientAddress = criUpdate.ClientAddress;
            cri.ClientPhone = criUpdate.ClientPhone;
            cri.ClientEmail = criUpdate.ClientEmail;
            cri.WorkDescription = criUpdate.WorkDescription;
            cri.MaterialsUsed = criUpdate.MaterialsUsed;
            cri.Duration = criUpdate.Duration;
            cri.Status = criUpdate.Status;
            cri.TechnicianSignature = criUpdate.TechnicianSignature;
            cri.ClientSignature = criUpdate.ClientSignature;
            cri.UpdatedAt = DateTime.UtcNow;

            if (cri.Status == "Submitted" && cri.SubmittedAt == null)
            {
                cri.SubmittedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(ApiResponse<CRIForm>.SuccessResponse(cri));
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult<ApiResponse<object>>> DeleteCRI(Guid id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(ApiResponse<object>.ErrorResponse("Utilisateur non identifié"));

            var cri = await _context.CRIForms.FindAsync(id);

            if (cri == null)
                return NotFound(ApiResponse<object>.ErrorResponse("CRI introuvable"));

            if (cri.TechnicianId != userId.Value && !User.IsInRole("Admin"))
                return Forbid();

            _context.CRIForms.Remove(cri);
            await _context.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "CRI supprimé avec succès"));
        }

        [HttpGet("clients/search")]
        public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> SearchClients([FromQuery] string q)
        {
            if (string.IsNullOrWhiteSpace(q))
                return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(new List<string>()));
            
            var query = q.ToLower();
            var clients = await _context.CRIForms
                .Where(c => c.ClientName != null && c.ClientName.ToLower().Contains(query))
                .Select(c => c.ClientName)
                .Distinct()
                .Take(20)
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(clients!));
        }

        [HttpGet("sites/search")]
        public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> SearchSites([FromQuery] string? client, [FromQuery] string q)
        {
            var queryDb = _context.CRIForms.AsQueryable();

            if (!string.IsNullOrWhiteSpace(client))
            {
               var loweredClient = client.ToLower();
               queryDb = queryDb.Where(c => c.ClientName != null && c.ClientName.ToLower() == loweredClient);
            }

            if (!string.IsNullOrWhiteSpace(q))
            {
               var loweredQ = q.ToLower();
               queryDb = queryDb.Where(c => c.ClientSite != null && c.ClientSite.ToLower().Contains(loweredQ));
            }

            var sites = await queryDb
                .Where(c => c.ClientSite != null)
                .Select(c => c.ClientSite)
                .Distinct()
                .Take(20)
                .ToListAsync();

            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(sites!));
        }
    }
}
