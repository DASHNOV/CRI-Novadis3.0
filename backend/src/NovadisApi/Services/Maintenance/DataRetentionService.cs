using Microsoft.EntityFrameworkCore;
using NovadisApi.Data;

namespace NovadisApi.Services.Maintenance
{
    /// <summary>
    /// Service en arrière-plan : purge périodique des données expirées (RGPD).
    /// - AuditLog       : conservation N jours (config Retention:AuditLogDays, défaut 365)
    /// - AuthAttempt    : conservation N jours (config Retention:AuthAttemptDays, défaut 30)
    /// - UserToken      : tokens révoqués/expirés depuis plus de N jours (défaut 30)
    /// </summary>
    public class DataRetentionService : BackgroundService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<DataRetentionService> _logger;
        private readonly IConfiguration _config;

        public DataRetentionService(
            IServiceProvider services,
            ILogger<DataRetentionService> logger,
            IConfiguration config)
        {
            _services = services;
            _logger = logger;
            _config = config;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Délai initial : laisser l'API démarrer proprement
            await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await PurgeAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "DataRetentionService: erreur lors de la purge");
                }

                // Tourner toutes les 24h
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
        }

        private async Task PurgeAsync(CancellationToken ct)
        {
            using var scope = _services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();

            var auditDays = _config.GetValue("Retention:AuditLogDays", 365);
            var authDays = _config.GetValue("Retention:AuthAttemptDays", 30);
            var tokenDays = _config.GetValue("Retention:RevokedTokenDays", 30);

            var auditCutoff = DateTime.UtcNow.AddDays(-auditDays);
            var authCutoff = DateTime.UtcNow.AddDays(-authDays);
            var tokenCutoff = DateTime.UtcNow.AddDays(-tokenDays);

            var auditDeleted = await db.AuditLogs
                .Where(a => a.CreatedAt < auditCutoff)
                .ExecuteDeleteAsync(ct);

            var authDeleted = await db.AuthAttempts
                .Where(a => a.CreatedAt < authCutoff)
                .ExecuteDeleteAsync(ct);

            var tokenDeleted = await db.UserTokens
                .Where(t => (t.IsRevoked || t.ExpiresAt < DateTime.UtcNow) && t.CreatedAt < tokenCutoff)
                .ExecuteDeleteAsync(ct);

            _logger.LogInformation(
                "Purge RGPD : {Audit} AuditLogs, {Auth} AuthAttempts, {Tokens} UserTokens supprimés",
                auditDeleted, authDeleted, tokenDeleted);
        }
    }
}
