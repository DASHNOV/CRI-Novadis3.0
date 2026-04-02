# Prompt de Refonte UI — Novadis CRI 2.0

## Contexte

Tu travailles sur **Novadis CRI 2.0**, une application Flutter (web + desktop) de gestion de comptes rendus d'intervention pour des techniciens terrain. L'app utilise Flutter avec Riverpod, GoRouter, fl_chart, flutter_form_builder, Drift (SQLite offline-first), et un backend ASP.NET Core (qu'on ne touche PAS).

## Contrainte absolue

**Ne toucher qu'au frontend Flutter (lib/, widgets, thème, layouts).** Aucune modification du backend, de la base de données, des modèles de données, des providers Riverpod existants, ni des appels API. Les fonctionnalités, routes, et la logique métier restent identiques. Seul le rendu visuel, les layouts, les animations et l'ergonomie changent.

## Objectif

Refondre entièrement le design pour obtenir une interface **moderne, épurée, professionnelle et ergonomique**, inspirée des meilleures applications SaaS/B2B de 2025-2026 (Linear, Notion, Vercel Dashboard, Raycast, Arc Browser, Figma, Stripe Dashboard, Supabase Dashboard). L'app doit être aussi agréable à utiliser sur un écran 27" que sur une tablette.

---

## 1. Direction Artistique & Design System

### Palette de couleurs
Remplacer la palette actuelle (#0B4F7C / #083A5E / #1C84C6 / #E6EEF4 / #C0392B) par un système de couleurs moderne :
- **Mode clair** : fond légèrement teinté (pas blanc pur — un gris très léger type `#FAFAFA` ou `#F8F9FB`), surfaces blanches avec des ombres subtiles
- Couleur primaire : un bleu plus contemporain et saturé (style `#2563EB` ou `#3B82F6`), utilisé avec parcimonie pour les actions principales
- Couleur d'accent : une teinte complémentaire (violet, teal, ou indigo) pour les éléments interactifs secondaires
- Sémantique : vert pour succès/validé, ambre pour attention/en cours, rouge doux pour erreurs, gris slate pour le texte secondaire
- Surfaces : hiérarchie claire avec des nuances de gris (cartes blanches sur fond gris léger, ou cartes gris léger sur fond blanc)

### Typographie
- Utiliser **Inter** ou **Geist** (Google Fonts) comme police principale
- Hiérarchie claire : titres en semibold/bold, corps en regular, labels en medium
- Tailles : 28-32px pour les titres de page, 18-20px pour les titres de section, 14-15px pour le corps, 12-13px pour les labels
- Line-height généreux (1.5-1.6 pour le corps)
- Espacement des lettres légèrement négatif sur les titres (-0.02em)

### Spacing & Layout
- Système de spacing basé sur 4px (4, 8, 12, 16, 20, 24, 32, 40, 48, 64)
- Padding généreux : 24-32px dans les cartes, 32-48px pour les marges de page
- Espacement entre les sections : 32-48px
- Border-radius : 12-16px pour les cartes, 8-10px pour les boutons et inputs, 6px pour les badges/chips

### Ombres & Élévation
- Abandonner les ombres lourdes. Utiliser :
  - Ombres très subtiles (`0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)`)
  - Ou des bordures fines (`1px solid rgba(0,0,0,0.06)`) style Notion/Linear
- Hover states avec élévation légère ou changement de fond subtil

### Animations & Micro-interactions
- Transitions douces sur tous les changements d'état (200-300ms, ease-out)
- Animations d'entrée subtiles sur les cartes et listes (fade + slide up, staggered)
- Skeleton loaders animés (shimmer) pendant les chargements
- Feedback haptique/visuel immédiat sur les interactions (boutons, toggles)
- Transitions de page fluides (shared element transitions si possible)

---

## 2. Navigation & Layout Principal

### Sidebar (remplace NavigationRail + BottomNavigationBar)

**Desktop/Web (>900px)** : Sidebar fixe à gauche, style Linear/Notion :
- Largeur : 240-260px (collapsible à 64px avec icônes seules)
- En-tête : logo Novadis compact + nom de l'utilisateur connecté
- Items de navigation : icône + label, avec indicateur actif (fond teinté + barre latérale ou pill)
- Espacement vertical entre items : 4-8px
- Séparateurs visuels entre groupes (ex: "Principal" / "Gestion" / "Paramètres")
- Bouton de collapse/expand en bas ou en haut
- Badge de notification sur "Mes CRI" pour les CRI en attente

**Tablette (600-900px)** : Sidebar collapsée par défaut (icônes seules, 64px), expandable au hover ou tap

**Mobile (<600px)** : Bottom navigation bar minimaliste (4-5 items max), icônes avec labels courts, style iOS/Material 3

### Zone de contenu
- Max-width : 1200-1400px, centrée
- Padding latéral : 32-48px sur desktop, 16-24px sur mobile
- Header de page consistant : titre + sous-titre + actions contextuelles (boutons à droite)
- Breadcrumbs discrets sur les pages profondes (Site Dashboard, Technician Dashboard)

---

## 3. Écrans à Redesigner

### 3.1 — Écran de Login (`login_screen.dart`)
- Layout split-screen sur desktop : illustration/branding à gauche (60%), formulaire à droite (40%)
- Formulaire centré verticalement : logo, titre "Connexion", champ email avec icône, bouton pleine largeur
- Fond avec un gradient subtil ou un pattern géométrique côté branding
- Sur mobile : formulaire centré, logo en haut, fond sobre

### 3.2 — Écran OTP (`otp_verification_screen.dart`)
- Design similaire au login (cohérence)
- Affichage de l'email avec possibilité de revenir en arrière
- Inputs OTP : 6 cases individuelles (style pin code), auto-focus sur la suivante
- Timer de renvoi du code
- Animation de validation (check animé) avant redirection

### 3.3 — Home / Dashboard Personnel (`personal_home_screen.dart`)
- En-tête : greeting personnalisé ("Bonjour, [Prénom]") + date du jour + avatar
- Section statistiques : 3 cartes KPI en ligne (CRI ce mois, En cours, En attente) avec icônes, valeurs grandes, et trend indicators
- Section "CRI Récents" :
  - Grid responsive (1 col mobile, 2 cols tablette, 3 cols desktop)
  - Cartes avec : badge de statut coloré (pill), nom du client en bold, catégorie, date relative ("il y a 2h")
  - Hover effect subtil (élévation + scale 1.01)
- Bouton flottant "Nouveau CRI" bien visible (coin inférieur droit ou dans le header)

### 3.4 — Formulaire CRI Projet (`cri_projet_form_page.dart`) & Service (`cri_service_form_page.dart`)
- Remplacer le Stepper Material classique par un **stepper horizontal moderne** :
  - Barre de progression en haut avec étapes numérotées, labels, et états (complété ✓, actif, à venir)
  - Style : cercles connectés par des lignes, couleur primaire pour complété/actif, gris pour à venir
  - Sur mobile : stepper horizontal scrollable ou indicateur compact (ex: "Étape 3/6")
- Chaque section dans une carte blanche avec titre de section
- Inputs : style moderne (label flottant ou label au-dessus, bordures fines, focus state avec couleur primaire)
- **Site Selector** : redesigner en combobox moderne avec dropdown riche (icône de recherche, items avec sous-texte pour l'adresse)
- **Spare Parts Widget** : table inline épurée avec lignes alternées, bouton "+" discret
- **Photo Picker** : grille de thumbnails avec overlay de suppression, zone de drop/upload en pointillés
- **Signature Pad** : cadre avec coins arrondis, boutons "Effacer" et "Valider" en dessous, instruction textuelle au-dessus
- **Boutons de navigation** : "Précédent" (outlined) à gauche, "Suivant" (filled) à droite, sticky en bas de la carte
- **Bouton de soumission final** : pleine largeur, couleur d'accent, avec icône

### 3.5 — Historique Personnel (`personal_history_screen.dart`) & Global (`global_history_screen.dart`)
- Barre de filtres en haut : chips/pills modernes (All, En attente, Signés, En cours) avec compteurs
- Barre de recherche intégrée (toujours visible sur desktop, toggle sur mobile)
- **Vue liste** (défaut) : lignes de tableau stylisées ou cartes compactes avec :
  - Nom du client (bold), type d'intervention, date, statut (badge coloré)
  - Actions au hover (voir, éditer, supprimer) — icônes discrètes à droite
- **Vue grille** (toggle) : cartes plus grandes avec plus de détails
- Toggle vue liste/grille en haut à droite
- Pour GlobalHistoryScreen : filtres avancés dans un panel collapsible ou un dropdown, sélecteur de technicien redesigné en combobox

### 3.6 — Dashboard Global (`main_dashboard_page.dart`)
- Layout en grille CSS-like :
  - Row 1 : KPI cards (4 colonnes sur desktop, 2 sur tablette, 1 sur mobile)
  - Row 2 : Graphique principal (trend des interventions) sur toute la largeur
  - Row 3 : 2 colonnes — Distribution par type (gauche) + Top sites (droite)
  - Row 4 : 2 colonnes — Évolution temporelle + Courbe de charge
- Chaque widget dans une carte avec : titre, sous-titre, et menu contextuel (⋮) pour options
- Filtre de période : pills modernes en haut à droite du dashboard (1M, 3M, 6M, 1A)
- Sélecteur de technicien : dropdown/combobox dans le header
- Graphiques : couleurs cohérentes avec la palette, tooltips élégants, animations d'entrée
- Améliorer le contraste et la lisibilité des axes/labels des graphiques

### 3.7 — Dashboard Site (`site_dashboard_page.dart`)
- Header : carte hero avec le nom du site, adresse, client — sur fond avec gradient subtil ou image de fond floue
- Statistiques : cards KPI inline (Total interventions, Temps moyen, Dernier passage)
- Timeline des interventions : redesigner en timeline verticale moderne (points connectés, cartes à droite, dates à gauche)
- Liste des techniciens : avatars circulaires avec nom en dessous, scrollable horizontalement

### 3.8 — Dashboard Technicien (`technician_dashboard_page.dart`)
- Header : avatar du technicien + nom + rôle, dans une carte avec fond teinté
- KPIs : cards sectionnées (Volume, Temps, Qualité) dans une grille propre
- Radar chart : plus grand, avec légende claire, couleurs pastel
- Trend chart : cohérent avec le dashboard global

### 3.9 — Documents (`documents_page.dart`)
- Layout type gestionnaire de fichiers moderne (style Google Drive / Notion) :
  - Toolbar : recherche + tri + vue (liste/grille) + actions groupées
  - Liste : icône de type de fichier (stylisée), nom, date, taille, badge de format
  - Sélection multiple avec checkboxes apparaissant au hover
  - Actions contextuelles : menu "⋮" par document
- Empty state : illustration SVG/Lottie + message + CTA

### 3.10 — Page de sélection CRI pour export (`cri_selection_page.dart`)
- Liste de CRI avec recherche en haut
- Chaque item : checkbox + résumé du CRI (client, site, date, numéro)
- Bouton d'export sticky en bas

### 3.11 — Admin (`admin_screen.dart`)
- Cards de statistiques globales en haut
- Section gestion avec cards d'action (Utilisateurs, Paramètres, etc.)
- Design cohérent avec le reste du dashboard

### 3.12 — Profil (`profile_screen.dart`)
- Avatar large avec initiales ou photo
- Informations du compte dans des cards groupées
- Section "À propos" et "Aide" avec icônes
- Bouton de déconnexion en bas (rouge discret)

### 3.13 — Sélection type CRI (`cri_form_screen.dart`)
- 2 grandes cartes cliquables côte à côte (desktop) ou empilées (mobile)
- Chaque carte : icône illustrative, titre ("CRI Projet" / "CRI Service"), description courte
- Hover : élévation + bordure primaire
- Animation de sélection

---

## 4. Composants Transversaux à Redesigner

### Cartes KPI (`kpi_card_widget.dart`)
- Fond blanc, bordure fine ou ombre très légère
- Icône dans un cercle teinté (fond pastel de la couleur associée)
- Valeur principale en 28-32px semibold
- Label en 12-13px gris
- Trend indicator : flèche + pourcentage en vert/rouge, aligné en bas

### Badges de statut
- Pills arrondis (border-radius full) : "En attente" (ambre), "Signé" (vert), "En cours" (bleu), "Brouillon" (gris)
- Texte 12px medium, padding 4px 12px

### Boutons
- Primary : fond plein couleur primaire, texte blanc, hover darken 10%
- Secondary/Outlined : bordure fine, texte couleur primaire, hover fond très léger
- Ghost : pas de bordure ni fond, texte couleur primaire, hover fond très léger
- Destructive : rouge doux
- Tous : border-radius 8-10px, padding 10-12px 20-24px, transition 150ms

### Inputs
- Label au-dessus du champ (pas flottant)
- Bordure 1px gris léger, border-radius 8px
- Focus : bordure couleur primaire + ring (box-shadow 0 0 0 3px primary/20%)
- Placeholder en gris clair
- Helper text en 12px sous le champ
- Error state : bordure rouge + message rouge sous le champ

### Dialogs / Bottom Sheets
- Border-radius 16-20px en haut
- Handle bar en haut (gris, 40px × 4px, arrondi)
- Padding intérieur généreux (24px)
- Fond légèrement flouté (backdrop blur si performant)

### Skeleton Loaders
- Shimmer effect avec gradient animé
- Formes correspondant aux vrais contenus (cartes, texte, graphiques)

---

## 5. Responsive Design

### Breakpoints
```
Mobile    : < 640px
Tablette  : 640px — 1024px
Desktop   : 1024px — 1440px
Large     : > 1440px
```

### Grille
- Desktop : grille 12 colonnes, gutter 24px
- Tablette : grille 8 colonnes, gutter 16px
- Mobile : grille 4 colonnes, gutter 16px

### Adaptations spécifiques
- **Sidebar** : visible sur desktop, collapsée sur tablette, bottom bar sur mobile
- **KPI cards** : 4 cols → 2 cols → 1 col
- **Graphiques** : pleine largeur sur mobile, 2 colonnes sur desktop
- **Formulaires** : toujours single column, mais inputs côte à côte quand pertinent sur desktop (ex: ville + code postal)
- **Tableaux/listes** : cartes sur mobile, lignes de tableau sur desktop
- **Actions** : boutons texte sur desktop, icônes seules sur mobile

---

## 6. Fichiers à Modifier

### Thème
- `lib/core/theme/app_theme.dart` — Refonte complète (couleurs, typographie, composants)
- `lib/core/theme/responsive.dart` — Nouveaux breakpoints

### Layout principal
- `lib/core/widgets/responsive_scaffold.dart` — Sidebar moderne
- `lib/core/widgets/content_container.dart` — Ajuster max-width et padding

### Écrans (sous `lib/features/` et `lib/screens/`)
- Tous les fichiers listés dans la section 3

### Widgets (sous `lib/features/*/widgets/`)
- Tous les widgets listés dans la section 4
- Les widgets de graphiques (couleurs, styles, tooltips)

### Assets
- Ajouter la police Inter ou Geist via Google Fonts (`google_fonts` package)
- Éventuellement ajouter des illustrations SVG pour les empty states

---

## 7. Packages à Ajouter (si nécessaire)

- `google_fonts` — pour Inter/Geist
- `shimmer` — pour les skeleton loaders
- `flutter_animate` — pour les micro-animations déclaratives
- `flutter_svg` — pour les illustrations (si pas déjà présent)
- `gap` — pour le spacing simplifié (SizedBox alternative)

Ne PAS ajouter de packages qui impliquent des changements backend ou de logique métier.

---

## 8. Critères de Qualité

- [ ] Cohérence visuelle totale entre tous les écrans
- [ ] Responsive parfait de 360px à 2560px
- [ ] Temps de chargement perçu minimal (skeletons, animations)
- [ ] Accessibilité : contraste WCAG AA minimum, touch targets 44px minimum
- [ ] Animations fluides (60fps), pas de jank
- [ ] Aucune régression fonctionnelle — toutes les features existantes marchent identiquement
- [ ] Code propre : styles centralisés dans le thème, pas de valeurs magiques hardcodées
