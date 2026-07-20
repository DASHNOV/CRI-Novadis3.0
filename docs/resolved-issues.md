# Incidents résolus — Novadis CRI 2.0

> Journal des bugs complexes et erreurs de logique résolus.
> **À consulter avant toute nouvelle correction** (cf. `CLAUDE.md`).
> Style télégraphique, entrée la plus récente en haut.

## Format d'une entrée

```
## [AAAA-MM-JJ] Titre court du problème
- **Symptôme** : ce qui était observé (erreur, comportement).
- **Cause** : la vraie cause racine identifiée.
- **Correctif** : ce qui a été changé (fichiers / logique).
- **Prévention** : règle à suivre pour éviter la régression.
```

---

<!-- Ajouter les incidents résolus ci-dessous, du plus récent au plus ancien. -->

## [2026-07-20] Lot d'évolutions CRI : logiciel « Autre », édition post-soumission, signature unique, nommage auto, validation email
- **Contexte** : 5 demandes fonctionnelles / vérifications de cohérence.
- **Logiciel « Autre » (CRI Projet)** : ajout du membre `autre` à `enum ProjetSoftware` + champ `customName` sur `SoftwareEntry` (`cri_projet_table.dart`). Saisie manuelle conditionnelle dans `_buildSoftwaresSection` (`cri_projet_form_page.dart`), validée (nom requis si « Autre » coché). Rendu PDF via `SoftwareEntry.displayName` (`pdf_builder_common.dart`). Aucun changement DB (transite par colonne JSON `Data`).
- **Édition d'un CRI soumis** : autorisée **au seul propriétaire**. Back : garde ajoutée dans `CRIController.UpdateCRI` — si `Status == "Submitted"`, refuser sauf propriétaire (pas de dérogation Admin) ; `UpdatedAt` sert de trace. Front : bouton « Modifier » dans `CriDetailsDialog` (`canEdit`/`onEdit`) affiché si propriétaire ; bannière d'avertissement dans les 2 form pages quand `!isDraft` ; `loadCri` fait désormais un **fallback serveur** (`CriRemoteRepository.fetchCriById`) car un CRI soumis peut ne pas exister en base locale.
- **Signature unique multi-techniciens** (option retenue : une seule signature suffit) : suppression du `SignaturePadWidget` par technicien dans la boucle ; un unique pad après la liste des noms (`cri_service_form_page.dart`, `cri_projet_form_page.dart`). Liste `technicianNames` conservée. PDF : noms empilés + une seule signature (`_buildSignatureBlock`). Back inchangé (déjà un seul `TechnicianSignature`).
- **Nommage auto numéro de commande** : si `ticketNumber`/`projectNumber` vide à la soumission → génération `CRI<AAAAMMJJ>_<acronymeSite><nomClient>` (`core/utils/cri_reference.dart`, acronyme dérivé du nom du site, mots vides ignorés). Appliqué dans les `submit()` des 2 contrôleurs, **sans écraser** une saisie manuelle.
- **Validation email** : regex durcie (TLD ≥ 2, pas de points consécutifs ni en bordure) alignée front (`form_validators.dart`) **et** back (`[RegularExpression]` sur `CRIForm.ClientEmail`, remplace `[EmailAddress]` trop permissif).
- **Prévention** :
  - Toute liste à choix fermés destinée à évoluer doit prévoir un membre `autre` + champ libre (pattern `ProjetInterventionType`).
  - Front et back doivent partager **la même** regex de validation (éviter la divergence `[EmailAddress]` .NET « loose » vs regex front).
  - `loadCri` ne doit jamais supposer la présence locale d'un CRI soumis — toujours prévoir le fallback serveur.
  - Ne jamais écraser une valeur saisie par l'utilisateur lors d'une génération automatique (garde `isNotEmpty`).

## [2026-07-16] CRI soumis hors-ligne invisible dans « Tous les CRI » / « Mes Documents »
- **Symptôme** : soumission d'un CRI sans réseau → message orange OK, CRI bien en base locale (visible à l'export, PDF exportable), mais **absent** de « Tous les CRI » (admin) et « Mes Documents » (technicien). Les listes n'affichaient que les CRI serveur de la dernière session en ligne.
- **Cause** : dans les deux écrans d'historique, la fusion des CRI locaux `pending` était placée **après** l'appel serveur dans le **même flux** — `global_history_screen` via un `Future.wait([getAllCRIsWithTechnician, getTechnicians, drafts, pending])`, `personal_history_screen` via `getPersonalCRIs` puis fusion. `getAllCRIsWithTechnician` / `getPersonalCRIs` lèvent une `DioException` hors-ligne (cf. `stats_api_service.dart`) → `Future.wait` rejette / le `try` part au `catch` **avant** la fusion locale, qui n'est donc jamais atteinte. La visibilité du local était de fait **conditionnée à la réussite de l'appel serveur**.
- **Correctif** :
  - `global_history_screen.dart` : charger les CRI locaux (drafts + pending) **toujours** en premier ; appel serveur rendu *best-effort* dans son propre `try/catch` (fallback = affichage local + snackbar « Hors ligne… »).
  - `personal_history_screen.dart` : même schéma — `getPersonalCRIs` best-effort, fusion locale indépendante du réseau.
- **Prévention** : **ne jamais placer une fusion/lecture de données locales derrière un appel réseau dans le même `Future.wait` ou le même `try`** — le local doit se charger indépendamment, le réseau être *best-effort*. Corollaire de la règle du 2026-07-10 : tout état `pending` local doit rester visible **même quand le serveur est injoignable**.
- **Note test (Flutter Web dev)** : tester hors-ligne en **coupant le backend** (`Ctrl+C` sur `dotnet run`), pas via DevTools « Offline » : en debug il n'y a pas de service worker, « Offline » bloque aussi le serveur de dev (`:60997`) → un F5 casse l'app (dino game / `ERR_INTERNET_DISCONNECTED`). Couper le backend laisse `:60997` up (F5 possible) et ne tombe que l'API (`:5200`). Export PDF hors-ligne = normal (rendu client depuis la base locale).

## [2026-07-16] Connexion impossible en local — requêtes `login` annulées à 10 s
- **Symptôme** : en dev web (Chrome), « Une erreur est survenue. Veuillez réessayer. » à la connexion. Onglet Network : requêtes `login` en `(canceled)` à ~10.01 s, `Preflight` en `(pending)`. Backend pourtant démarré.
- **Cause** : `frontend/.env` figeait `API_URL=http://192.168.200.214:5200/api`, mais le DHCP avait réattribué l'IP de la machine (passée à `192.168.200.202`). L'ancienne IP LAN était injoignable → timeout au bout du `connectTimeout` Dio (10 s, cf. `core/network/dio_provider.dart`) → requête annulée.
- **Correctif** : `frontend/.env` → `API_URL=http://localhost:5200/api` (backend sur la même machine). Nécessite un **redémarrage complet** de `flutter run` car `dotenv` charge le `.env` au démarrage (le hot reload ne suffit pas).
- **Prévention** : ne pas figer d'IP LAN dans `.env` pour le dev web — utiliser `localhost`, robuste face aux changements d'IP DHCP. L'IP LAN n'est nécessaire que pour tester sur un device mobile physique (à remettre ponctuellement dans ce cas). Devant un timeout à ~10 s pile sur `login`, suspecter d'abord une `API_URL` injoignable avant la logique applicative.

## [2026-07-10] CRI soumis sur site invisible dans « Tous les CRI » / « Mes Documents »
- **Symptôme** : soumission d'un CRI sur site client → message « enregistré avec succès », mais CRI absent de « Tous les CRI » et « Mes Documents ». Jamais reproduit au bureau.
- **Cause** : échec réseau (pare-feu site, portail captif, 4G faible) sur `POST /CRI` → `submit()` marquait le CRI `syncStatus: 'pending'` en local mais **retournait `true`** ; la page affichait un faux succès (branche `success` ignorait `errorMessage`). Aucun code ne relisait les CRI `pending` pour les repousser, et les listes lisaient uniquement le serveur.
- **Correctif** :
  - `services/sync_service.dart` (nouveau) : repousse les CRI `pending` non-brouillons au démarrage, au retour de connectivité (mobile) et avant chargement des listes.
  - Contrôleurs service/projet : message hors-ligne explicite ; pages formulaire : snackbar orange « enregistré sur l'appareil » au lieu du faux succès vert.
  - `personal_history_screen` + `global_history_screen` : fusion des CRI locaux `pending` (badge « Non synchronisé », dédup par id serveur).
- **Prévention** : jamais retourner « succès » à l'UI quand un push distant échoue silencieusement ; tout état `pending` local doit avoir un mécanisme de resynchronisation ET être visible dans l'UI.
