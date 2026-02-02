# Novadis CRI - Application Mobile Flutter

Application mobile de gestion des Comptes Rendus d'Intervention (CRI) pour Novadis.

## 📱 Description

Application Flutter pour Android permettant de créer, consulter et gérer des comptes rendus d'intervention de manière simple et efficace.

## 🏗️ Architecture

L'application suit une **architecture feature-based** avec une séparation claire des responsabilités :

```
lib/
├── core/                    # Configuration et ressources partagées
│   ├── config/             # Configuration de l'app (router, etc.)
│   ├── theme/              # Thème Material 3
│   ├── services/           # Services globaux
│   └── utils/              # Utilitaires
│
├── data/                    # Couche de données
│   ├── models/             # Modèles de données
│   ├── local/              # Stockage local
│   └── remote/             # API (non utilisé en mode démo)
│
└── features/                # Fonctionnalités de l'app
    ├── auth/               # Authentification
    ├── dashboard/          # Tableau de bord
    ├── cri_form/           # Formulaire CRI
    ├── history/            # Historique des CRI
    └── admin/              # Administration
```

## 🚀 Fonctionnalités

### ✅ Implémentées

- **Authentification** : Écran de connexion (mock, sans backend)
- **Dashboard** : Vue d'ensemble avec accès aux fonctionnalités principales
- **Création de CRI** : Formulaire complet avec validation
  - Client
  - Site
  - Type d'intervention
  - Description
  - Date
- **Historique** : Liste de tous les CRI avec recherche et filtres
- **Administration** : Statistiques et gestion des données
- **Navigation** : GoRouter pour une navigation fluide
- **Thème** : Material Design 3 avec couleur primaire bleue

### 📊 Données

Mode démonstration avec stockage local en mémoire (pas de backend).

## 🛠️ Technologies

- **Framework** : Flutter 3.10+
- **Langage** : Dart
- **Navigation** : GoRouter
- **State Management** : Flutter Hooks
- **UI** : Material Design 3
- **Localisation** : Français (FR)

## 📦 Dépendances

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  go_router: ^13.0.0          # Navigation
  flutter_hooks: ^0.20.0      # State management
  intl: any                    # Formatage de dates
  cupertino_icons: ^1.0.8     # Icônes iOS
```

## 🏃 Lancement de l'application

### Prérequis

- Flutter SDK 3.10.7 ou supérieur
- Android Studio / VS Code avec extensions Flutter
- Émulateur Android ou appareil physique

### Installation

1. Cloner le projet
2. Installer les dépendances :
   ```bash
   flutter pub get
   ```

### Exécution

```bash
# Mode debug
flutter run

# Mode release
flutter run --release

# Sur un appareil spécifique
flutter run -d <device_id>
```

### Build Android

```bash
# APK
flutter build apk

# App Bundle (pour Google Play)
flutter build appbundle
```

## 📱 Écrans

1. **Login** (`/login`) - Écran de connexion
2. **Dashboard** (`/dashboard`) - Tableau de bord principal
3. **Formulaire CRI** (`/cri-form`) - Création d'un nouveau CRI
4. **Historique** (`/history`) - Liste des CRI
5. **Admin** (`/admin`) - Panneau d'administration

## 🎨 Thème

- **Couleur primaire** : Bleu (`Colors.blue`)
- **Material Design** : Version 3
- **Mode** : Clair uniquement (pour l'instant)

## 📝 Modèle de données CRI

```dart
{
  id: String,
  client: String,
  site: String,
  typeIntervention: String,
  description: String,
  date: DateTime,
  createdAt: DateTime
}
```

## 🔒 Sécurité

⚠️ **Mode démonstration** : Aucune authentification réelle, pas de backend.
Les données sont stockées en mémoire et perdues à la fermeture de l'app.

## 🚧 Évolutions futures

- [ ] Stockage persistant local (SQLite/Hive)
- [ ] Synchronisation avec backend
- [ ] Authentification réelle
- [ ] Export PDF des CRI
- [ ] Photos et signatures
- [ ] Mode hors ligne
- [ ] Notifications
- [ ] Thème sombre

## 📄 Licence

Propriétaire - Novadis © 2026

## 👥 Équipe

Développé pour Novadis

---

**Version** : 1.0.0+1  
**Dernière mise à jour** : Janvier 2026
