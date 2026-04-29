using Microsoft.AspNetCore.Diagnostics;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Middleware
{
    /// <summary>
    /// Handler global pour toute exception non-catchée. Log l'erreur, retourne
    /// une réponse JSON normalisée sans fuite de stacktrace.
    /// </summary>
    public class GlobalExceptionHandler : IExceptionHandler
    {
        private readonly ILogger<GlobalExceptionHandler> _logger;
        private readonly IHostEnvironment _env;

        public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger, IHostEnvironment env)
        {
            _logger = logger;
            _env = env;
        }

        public async ValueTask<bool> TryHandleAsync(
            HttpContext httpContext,
            Exception exception,
            CancellationToken cancellationToken)
        {
            var traceId = httpContext.TraceIdentifier;
            _logger.LogError(exception,
                "Unhandled exception on {Method} {Path} (TraceId={TraceId})",
                httpContext.Request.Method, httpContext.Request.Path, traceId);

            var (statusCode, message) = exception switch
            {
                UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "Non autorisé."),
                KeyNotFoundException        => (StatusCodes.Status404NotFound, "Ressource introuvable."),
                ArgumentException           => (StatusCodes.Status400BadRequest, "Requête invalide."),
                InvalidOperationException   => (StatusCodes.Status400BadRequest, "Opération invalide."),
                _                           => (StatusCodes.Status500InternalServerError, "Une erreur est survenue.")
            };

            httpContext.Response.StatusCode = statusCode;
            httpContext.Response.ContentType = "application/json";

            var errors = _env.IsDevelopment()
                ? new List<string> { exception.Message }
                : null;

            var body = ApiResponse<object>.ErrorResponse(
                $"{message} (Réf: {traceId})",
                errors);

            await httpContext.Response.WriteAsJsonAsync(body, cancellationToken);
            return true;
        }
    }
}
