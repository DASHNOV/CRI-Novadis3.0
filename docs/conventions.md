# Conventions de code

## Langages
- **Frontend** : Dart (Flutter)
- **Backend** : C# (ASP.NET Core)

## Nommage

### Dart (Frontend)
- Fichiers : `snake_case.dart`
- Classes : `PascalCase` (ex: `CriProjetModel`, `CriRemoteRepository`)
- Variables/méthodes : `camelCase`
- Constantes : `camelCase` (convention Dart, pas SCREAMING_CASE)
- Providers Riverpod : `camelCaseProvider` (ex: `criRemoteRepositoryProvider`)
- Enums : `PascalCase` pour le type, `camelCase` pour les valeurs
- Préfixe `_` pour les membres privés

### C# (Backend)
- Fichiers : `PascalCase.cs`
- Classes/Méthodes : `PascalCase`
- Variables locales : `camelCase`
- Champs privés : `_camelCase` (ex: `_context`, `_logger`)
- Interfaces : `IPascalCase` (ex: `IJwtService`)
- Controllers : `[Entité]Controller`
- DTOs : `[Nom]Dto`

## Architecture patterns

### Frontend
- **Feature-based** : `features/[nom]/` contient screens + widgets + pages
- **State** : Riverpod (hooks_riverpod) — `Provider`, `StateProvider`
- **Navigation** : GoRouter — routes déclarées dans `AppRouter`
- **Réseau** : Dio singleton via `dioProvider` — interceptor JWT auto-refresh
- **Offline** : Drift (SQLite) — tables dans `data/local/tables/`
- **Modèles** : `toJson()` / `fromJson()` — sérialisation manuelle (pas code-gen)
- **Widgets** : `const` constructors systématiques, `super.key`

### Backend
- **MVC** : Controllers → Services (interface + impl) → DbContext
- **DI** : `AddScoped<IService, Service>()` dans `Program.cs`
- **Réponse API** : `ApiResponse<T>.SuccessResponse(data, message?)` / `ErrorResponse(msg)`
- **Auth** : `[Authorize]` + `[RoleAuthorize("Admin")]` — JWT claims
- **Erreurs** : try/catch dans chaque action → `_logger.LogError` + `StatusCode(500, ...)`
- **User ID** : extrait via `ClaimTypes.NameIdentifier` → `GetCurrentUserId()` helper

## Thème / Design System (Frontend)
- Police : **Inter** (Google Fonts)
- Tokens dans `AppTheme` (classe statique) : couleurs, spacing, radius, shadows
- Spacing base 4px : `space4` à `space64`
- Radius : `radiusSm(6)`, `radiusMd(8)`, `radiusLg(12)`, `radiusXl(16)`
- Ombres : `shadowSm`, `shadowMd`, `shadowLg` (adaptatifs light/dark)
- Transitions : `animFast(150ms)`, `animNormal(250ms)`, `animSlow(350ms)`
- Support light/dark avec interpolation `themeT` (0.0 → 1.0)

## Gestion des erreurs

### Frontend
- Les repositories retournent des types Dart (pas de Response brut)
- `DioException` → `_handleError()` → extrait `message` du body JSON
- Erreurs silencieuses avec `debugPrint` pour les recherches non-critiques
- Pas de crash — fallback gracieux (listes vides, modèles par défaut)

### Backend
- Chaque endpoint wrappé dans `try/catch`
- Log structuré : `_logger.LogError(ex, "message {Param}", param)`
- Réponse erreur : jamais de stacktrace au client (sauf SMTP debug temporaire)
- Audit trail : `AuditLog` pour actions auth

## Conventions API
- Toutes les réponses : `{ success: bool, data: T?, message: string? }`
- Base route : `/api/[controller]`
- Filtres : query params (`?period=30`, `?q=search`, `?filter=signed`)
- IDs : Guid
- Dates : ISO 8601 UTC
- Pas de pagination (volumes faibles — ~centaines de CRI)

## Commentaires
- Backend : XML doc (`/// <summary>`) sur les endpoints publics
- Frontend : `///` doc comments uniquement sur classes/méthodes publiques complexes
- Commentaires inline en français
- Émojis dans les commentaires backend (📧, ✅, ⚠️) pour repérage visuel

## Git
- Branches : `feature/xxx`, `fix/xxx`, `doc_xxx`
- Messages : pas de convention stricte observée
