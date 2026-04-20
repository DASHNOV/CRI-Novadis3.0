namespace NovadisApi.Services.Storage
{
    /// <summary>
    /// Abstraction pour le stockage des fichiers exportés (PDF/XLSX).
    /// Implémentation actuelle: filesystem local. MinIO peut être branché plus tard.
    /// </summary>
    public interface IObjectStorageService
    {
        /// <summary>Stocke un fichier et renvoie la clé d'accès.</summary>
        Task<string> UploadAsync(string objectKey, byte[] bytes, string contentType, CancellationToken ct = default);

        /// <summary>Récupère le contenu d'un fichier stocké.</summary>
        Task<(byte[] Bytes, string ContentType)> DownloadAsync(string objectKey, CancellationToken ct = default);

        /// <summary>Supprime un fichier du stockage.</summary>
        Task DeleteAsync(string objectKey, CancellationToken ct = default);

        /// <summary>Indique si un objet existe.</summary>
        Task<bool> ExistsAsync(string objectKey, CancellationToken ct = default);
    }
}
