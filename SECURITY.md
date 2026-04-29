# Guide de Sécurité Novadis CRI

Ce document décrit les meilleures pratiques à suivre pour sécuriser l'application en production.

## 🔑 Gestion des Secrets

**Ne commitez jamais de secrets dans le code source.**

### Recommandations Immédiates :
1.  **Variables d'Environnement** : En production, les secrets dans `appsettings.json` doivent être remplacés par des variables d'environnement.
    *   `ConnectionStrings__DefaultConnection`
    *   `Jwt__SecretKey`
    *   `Email__Password`
2.  **Azure Key Vault / AWS Secrets Manager** : Pour une sécurité maximale, utilisez un service de gestion de secrets cloud.

## 🌐 Réseau et API

1.  **CORS** : ✅ Restreint via `appsettings.json` → `Cors:AllowedOrigins`. Modifier la liste si un nouveau domaine doit accéder à l'API.
2.  **HTTPS** : ✅ `UseHttpsRedirection` actif en production. Cloudflare doit être configuré en mode `Full (Strict)` et non `Flexible` pour un chiffrement bout-en-bout.
3.  **Rate limiting** : ✅ Activé sur `/api/auth/*` (5 req/min/IP) + global (100 req/min/IP).
4.  **OTP** : ✅ Généré via `RandomNumberGenerator` (cryptographique). Code log uniquement en `#if DEBUG`.
5.  **Headers de sécurité** : ✅ `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `HSTS` (prod).
6.  **Swagger** : ✅ Désactivé en production (uniquement `IsDevelopment`).
7.  **Hachage** : Le hachage des codes de connexion utilise un sel applicatif. En cas de changement, les anciens codes en base deviendront invalides.

## 📱 Mobile

1.  **Obfuscation** : ✅ Script `build_android.sh` utilise `--obfuscate --split-debug-info=build/debug-info-android`. Conserver ce dossier pour désobfusquer les stack traces.
2.  **Certificat Pinning** : Pour les environnements hautement sensibles, envisagez le pinning de certificat SSL pour empêcher les attaques MITM.

## 🌍 Web (Flutter Web)

1.  **Tree-shake icons** : ✅ `--tree-shake-icons` retire les icônes Material/Cupertino non utilisées (réduit la taille du bundle).
2.  **Pas de source maps** : ✅ `--no-source-maps` empêche la fuite du code source en production.
3.  **debugPrint neutralisé** : ✅ `main.dart` annule tous les `debugPrint` en `kReleaseMode` (perf + RGPD).

---
**Audit réalisé en Février 2026**
