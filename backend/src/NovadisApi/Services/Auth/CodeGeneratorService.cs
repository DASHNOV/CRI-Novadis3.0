using System.Security.Cryptography;

namespace NovadisApi.Services.Auth
{
    public interface ICodeGeneratorService
    {
        string GenerateCode(int length = 6);
        string HashCode(string code);
        bool VerifyCode(string code, string hash);
    }

    public class CodeGeneratorService : ICodeGeneratorService
    {
        /// <summary>
        /// Génère un code numérique aléatoire
        /// </summary>
        public string GenerateCode(int length = 6)
        {
            var random = new Random();
            var code = string.Empty;

            for (int i = 0; i < length; i++)
            {
                code += random.Next(0, 10).ToString();
            }

            return code;
        }

        /// <summary>
        /// Hash un code avec SHA256 et un sel pour stockage sécurisé
        /// </summary>
        public string HashCode(string code)
        {
            // Note: En production réelle, on utiliserait un sel stocké en base par utilisateur.
            // Pour des codes à 6 chiffres éphémères, un sel constant applicatif est un premier rempart.
            const string internalSalt = "Novadis_Security_Salt_2025_!";
            using var sha256 = SHA256.Create();
            var bytes = System.Text.Encoding.UTF8.GetBytes(code + internalSalt);
            var hash = sha256.ComputeHash(bytes);
            return Convert.ToBase64String(hash);
        }

        /// <summary>
        /// Vérifie si un code correspond au hash stocké
        /// </summary>
        public bool VerifyCode(string code, string hash)
        {
            var codeHash = HashCode(code);
            return codeHash == hash;
        }
    }
}
