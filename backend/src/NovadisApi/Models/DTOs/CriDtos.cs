namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Payload pour PATCH /api/cri/{id}/signature.
    /// `null` remet le CRI en statut "En attente", toute autre valeur le marque "Signé".
    /// La constante <c>ManualValidationMarker</c> est utilisée par le front pour les
    /// validations manuelles (sans capture de signature).
    /// </summary>
    public class UpdateSignatureDto
    {
        public const string ManualValidationMarker = "MANUAL_VALIDATION";

        public string? ClientSignature { get; set; }
    }
}
