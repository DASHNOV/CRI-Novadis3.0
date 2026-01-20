# Page d'Accueil - Documentation

## Vue d'ensemble

Une nouvelle page d'accueil ergonomique a été ajoutée à l'application Novadis CRI. Cette page s'affiche après l'authentification et sert de point d'entrée principal pour accéder aux fonctionnalités de l'application.

## Objectif

La page d'accueil a été conçue pour :
- **Guider l'utilisateur** vers les fonctionnalités principales de l'application
- **Mettre en avant** la fonctionnalité principale : créer des comptes rendus d'intervention (CRI)
- **Simplifier la navigation** avec une interface claire et intuitive
- **Améliorer l'expérience utilisateur** avec un design moderne et ergonomique

## Structure de la page

### 1. En-tête de bienvenue
- Icône représentant l'activité technique
- Message de bienvenue
- Description succincte de l'application

### 2. Action principale (CTA)
**Nouveau Compte Rendu** - Carte mise en avant avec :
- Design premium avec gradient
- Icône claire et visible
- Accès direct à la sélection du type de CRI (Projet ou Service)

### 3. Actions secondaires
Grille de 4 cartes d'accès rapide :
- **Tableau de Bord** : Visualiser les statistiques et KPIs
- **Historique** : Consulter les CRI précédents
- **Statistiques** : Voir les statistiques par technicien
- **Administration** : Gérer les paramètres et utilisateurs

### 4. Accès rapides
Section avec liens directs vers :
- Créer un CRI Projet
- Créer un CRI Service

## Navigation

### Flux de navigation mis à jour

```
Login → Page d'Accueil → [Fonctionnalités]
```

**Avant :**
```
Login → Dashboard
```

**Après :**
```
Login → Page d'Accueil → Dashboard (via action secondaire)
                      → Nouveau CRI (action principale)
                      → Historique
                      → Statistiques
                      → Administration
```

## Fichiers modifiés

1. **Nouveau fichier créé :**
   - `lib/features/home/home_page.dart` - Page d'accueil complète

2. **Fichiers modifiés :**
   - `lib/core/config/app_router.dart` - Ajout de la route `/home`
   - `lib/features/auth/login_screen.dart` - Redirection vers `/home` au lieu de `/dashboard`

## Routes disponibles

| Route | Description |
|-------|-------------|
| `/login` | Page de connexion |
| `/home` | **Page d'accueil (nouvelle)** |
| `/dashboard` | Tableau de bord avec statistiques |
| `/cri-form` | Sélection du type de CRI |
| `/cri/new/projet` | Formulaire CRI Projet |
| `/cri/new/service` | Formulaire CRI Service |
| `/history` | Historique des CRI |
| `/dashboard/technician-stats` | Statistiques par technicien |
| `/admin` | Administration |

## Design et UX

### Principes de design appliqués

1. **Hiérarchie visuelle claire**
   - L'action principale (Nouveau CRI) est la plus visible
   - Les actions secondaires sont organisées en grille équilibrée

2. **Design moderne**
   - Utilisation de gradients pour l'action principale
   - Cards avec élévation et bordures arrondies
   - Icônes colorées pour différencier les actions

3. **Ergonomie**
   - Zones de touch optimisées pour mobile
   - Feedback visuel sur les interactions (InkWell)
   - Navigation intuitive

4. **Accessibilité**
   - Textes lisibles avec hiérarchie typographique
   - Contraste suffisant entre texte et fond
   - Icônes accompagnées de labels

## Utilisation

### Pour l'utilisateur

1. **Connexion** : Entrer son email sur la page de login
2. **Accueil** : Arrivée sur la page d'accueil
3. **Action rapide** : Cliquer sur "Nouveau Compte Rendu" pour créer un CRI
4. **Navigation** : Utiliser les cartes d'actions secondaires pour accéder aux autres fonctionnalités

### Pour le développeur

```dart
// Naviguer vers la page d'accueil
context.go(AppRouter.home);

// Ou avec push
context.push(AppRouter.home);
```

## Améliorations futures possibles

- [ ] Afficher des statistiques en temps réel (nombre de CRI du jour, etc.)
- [ ] Ajouter un carrousel de CRI récents
- [ ] Personnaliser le message de bienvenue avec le nom de l'utilisateur
- [ ] Ajouter des notifications ou alertes importantes
- [ ] Implémenter un mode sombre
- [ ] Ajouter des animations de transition entre les pages

## Notes techniques

- **Framework** : Flutter avec go_router pour la navigation
- **State Management** : Pas de state management complexe nécessaire (page stateless)
- **Responsive** : Design adaptatif avec SingleChildScrollView
- **Performance** : Widgets légers, pas de calculs lourds
