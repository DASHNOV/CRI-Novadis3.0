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

1.  **CORS** : La politique CORS `AllowMobileApp` doit être restreinte aux domaines réels utilisés en production.
2.  **HTTPS** : Assurez-vous que l'API est exposée uniquement via HTTPS avec un certificat valide.
3.  **Hachage** : Le hachage des codes de connexion a été renforcé avec un sel. En cas de changement, les anciens codes en base deviendront invalides.

## 📱 Mobile

1.  **Obfuscation** : Activez l'obfuscation du code lors du build Flutter (`flutter build apk --obfuscate --split-debug-info=...`).
2.  **Certificat Pinning** : Pour les environnements hautement sensibles, envisagez le pinning de certificat SSL pour empêcher les attaques MITM.

---
**Audit réalisé en Février 2026**
