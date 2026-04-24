# Architecture

## Monorepo
```
CRI_Novadis2.0/
├── frontend/          # Flutter app (web + mobile)
├── backend/           # ASP.NET Core API
├── database/          # SQL migrations manuelles
├── CLAUDE.md          # Point d'entrée LLM
└── SECURITY.md        # Pratiques sécurité prod
```

## Frontend — `frontend/lib/`
```
lib/
├── main.dart                 # Bootstrap (ProviderScope, MaterialApp.router)
├── core/
│   ├── config/
│   │   ├── app_router.dart   # GoRouter — toutes les routes
│   │   └── api_config.dart   # Base URL (dart-define > .env > fallback)
│   ├── network/
│   │   ├── dio_provider.dart # Dio singleton (JWT interceptor, refresh auto)
│   │   └── isolate_transformer.dart
│   ├── providers/            # main_nav_provider.dart
│   ├── storage/              # SharedPreferences / SecureStorage
│   ├── theme/                # AppTheme (design tokens, light/dark, Inter)
│   ├── utils/                # file_utils_web.dart
│   ├── constants/
│   └── widgets/              # responsive_scaffold, content_container, protected_route
├── data/
│   ├── models/               # CriProjetModel, CriServiceModel, SiteModel
│   ├── local/                # Drift (SQLite) tables — offline-first
│   └── repositories/         # cri_remote_repository, site_summary_repository
├── features/                 # Feature-based modules
│   ├── auth/                 # LoginScreen, OtpVerificationScreen
│   ├── home/                 # HomePage (post-login landing)
│   ├── dashboard/            # MainDashboardPage, SiteDashboardPage, TechnicianDashboardPage
│   ├── cri_form/             # CriFormScreen, CriProjetFormPage, CriServiceFormPage
│   ├── history/              # HistoryScreen (perso + global)
│   ├── documents/            # DocumentsPage, CriSelectionPage
│   ├── export/               # Export PDF/XLSX
│   └── admin/                # AdminScreen
├── screens/                  # RoleHomeScreen (routing par rôle), admin/, technician/
├── models/                   # Stats DTOs (global, personal, site, technician, distribution)
├── services/                 # stats_api_service.dart
└── utils/                    # permissions.dart
```

## Backend — `backend/src/NovadisApi/`
```
NovadisApi/
├── Program.cs                # Bootstrap (DB, JWT, CORS, Swagger, CSV import, middleware)
├── Controllers/              # API endpoints (10 controllers)
│   ├── AuthController        # login, verify, refresh, logout, me
│   ├── CRIController         # CRUD CRI, search clients/sites, signature
│   ├── GlobalStatsController # Stats globales, par site, par technicien, distribution (Admin)
│   ├── PersonalStatsController # Stats personnelles du technicien connecté
│   ├── ExportController      # Export XLSX (CRI unitaire, par période)
│   ├── ExportedDocumentsController # Historique des exports
│   ├── SitesController       # Recherche sites NovaDIS
│   ├── SiteSummaryController # Résumé par site
│   ├── UsersController       # Liste techniciens
│   └── HealthController      # Health check + diagnostic DB
├── Models/                   # Entités EF Core (CRIForm, User, Site, Client, etc.)
│   └── DTOs/                 # Objets de transfert (Auth, CRI, Stats)
├── Services/
│   ├── Auth/                 # JwtService, CodeGeneratorService
│   ├── Email/                # EmailService (SMTP)
│   ├── Export/               # XlsxExportService
│   └── Storage/              # LocalFileObjectStorage (MinIO-ready)
├── Data/                     # NovadisDbContext + Migrations (EF Core)
└── Attributes/               # RoleAuthorizeAttribute
```

## Flux de données
```
Flutter App
  ├─ Dio (JWT auto-refresh) → ASP.NET Core API → SQL Server
  ├─ Drift (SQLite local)   → Offline-first cache
  └─ Riverpod providers     → State management
```

## Routes frontend (GoRouter)
| Route | Screen |
|-------|--------|
| `/login` | LoginScreen |
| `/verify-otp` | OtpVerificationScreen |
| `/home` | RoleHomeScreen |
| `/dashboard` | MainDashboardPage |
| `/dashboard/site/:siteId` | SiteDashboardPage |
| `/dashboard/technician/:techId` | TechnicianDashboardPage |
| `/cri-form` | CriFormScreen (choix type) |
| `/cri/new/projet` | CriProjetFormPage |
| `/cri/new/service` | CriServiceFormPage |
| `/cri/edit/:id?type=` | CriProjetFormPage / CriServiceFormPage |
| `/cri/view/:id?type=` | (lecture seule — redirige edit) |
| `/history` | HistoryScreen |
| `/documents` | DocumentsPage |
| `/documents/selection` | CriSelectionPage |
| `/admin` | AdminScreen |

## Rôles
- **Admin** : accès global (stats, tous CRI, gestion users)
- **Technician** : accès perso (ses CRI, stats perso, dashboard perso)

## Déploiement & CI/CD

### Frontend (Vercel)
- Trigger : push sur `master` → GitHub Actions → Vercel
- Build : `flutter build web`
- Hébergement : `https://cri-novadis.tech`

### Backend (Serveur interne Windows)
- Trigger : push sur `dev` → GitHub Actions
- Build : `dotnet publish -c Release`
- Déploiement : SCP vers `C:\temp\` → SSH → déploiement sur `C:\novadis-api`
- Service : `NovadisApi` (PowerShell service)
- Workflow : `.github/workflows/deploy-api.yml`
  - Arrête service → remplace fichiers (preserve `.env`) → redémarre service
  - Credentials : SSH key + username ("Administrateur") en GitHub Secrets
