# API Summary

Base : `/api`  
Auth : JWT Bearer (sauf endpoints marqués `[AllowAnonymous]`)  
Format réponse : `{ success: bool, data: T?, message: string? }`

## Auth — `/api/auth`
| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| POST | `/login` | ❌ | Envoi OTP par email |
| POST | `/verify` | ❌ | Vérification OTP → JWT (access + refresh) |
| POST | `/refresh` | ❌ | Renouvellement access token |
| POST | `/logout` | ✅ | Révocation refresh token |
| GET | `/me` | ✅ | User connecté (UserDto) |
| GET | `/dev/get-code/{email}` | ❌ | [DEV ONLY] Récupérer OTP en clair |

## CRI — `/api/cri`
| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| GET | `/` | ✅ | Tous | Mes CRI (admin = tous) |
| GET | `/{id}` | ✅ | Owner/Admin | Détail CRI + photos |
| POST | `/` | ✅ | Tous | Créer CRI (Project/Service) |
| PUT | `/{id}` | ✅ | Owner/Admin | Modifier CRI |
| PATCH | `/{id}/signature` | ✅ | Owner only | Mettre à jour signature client |
| DELETE | `/{id}` | ✅ | Owner/Admin | Supprimer CRI |
| GET | `/clients/search?q=` | ✅ | Tous | Autocomplete clients |
| GET | `/sites/search?q=&client=` | ✅ | Tous | Autocomplete sites CRI |

## Stats globales — `/api/global` (Admin only)
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/stats?period=` | KPI globaux (compteurs, moyennes, répartitions) |
| GET | `/cris?technicienId=&filter=&searchId=` | Tous les CRI avec info technicien |
| GET | `/activity` | Activité techniciens (nb CRI 7j/30j/total) |
| GET | `/activity-chart` | Graphique activité quotidienne (7 jours) |
| GET | `/technicians` | Liste users pour dropdown |
| GET | `/stats/by-site?period=` | Stats agrégées par site |
| GET | `/stats/by-technician?period=` | Stats agrégées par technicien |
| GET | `/stats/distribution?period=` | Stats croisées (catégorie×site, évolution mensuelle) |

## Stats perso — `/api/personal`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/stats` | Stats du technicien connecté |

## Sites — `/api/sites`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/search?q=` | Recherche sites NovaDIS (base CSV importée) |
| GET | `/{numero}` | Détail site par numéro |

## Export — `/api/export`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/cri/{id}.xlsx` | Export XLSX d'un CRI |
| GET | `/period.xlsx?range=&date=` | Export XLSX par période (day/week/month/year) |

## Documents — `/api/exported-documents`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/` | Liste des exports de l'utilisateur |
| GET | `/{id}/download` | Télécharger un export |
| DELETE | `/{id}` | Supprimer un export |

## Site Summary — `/api/site-summary`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/{siteId}` | Résumé d'un site |

## Users — `/api/users`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/technicians` | Liste techniciens (nom complet) |

## Health — `/api/health-check`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/` | Health check détaillé (DB, perfs) |

## Modèle CRI principal (CRIForm)
- `Id` (Guid), `TechnicianId`, `InterventionType` ("Project"/"Service")
- `Category`, `InterventionDate`, `ClientName`, `ClientSite`, `ClientAddress`
- `WorkDescription`, `MaterialsUsed`, `Duration`, `Status` ("Draft"/"Submitted")
- `Data` (JSON complet du formulaire Dart sérialisé)
- `TechnicianSignature`, `ClientSignature` (base64 ou null)
- Champs extraits de Data : `HeureDebut/Fin`, `DureeMinutes`, `Ville`, `TicketNumber`, `Priority`, `ProjectName/Number/Phase/Status`
- Relations normalisées : `SiteID` (→ Sites), `ClientID` (→ ClientsNormalises)
