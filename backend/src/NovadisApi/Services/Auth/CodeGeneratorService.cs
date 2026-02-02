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
        /// Hash un code avec SHA256 pour stockage sécurisé
        /// </summary>
        public string HashCode(string code)
        {
            using var sha256 = SHA256.Create();
            var bytes = System.Text.Encoding.UTF8.GetBytes(code);
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
