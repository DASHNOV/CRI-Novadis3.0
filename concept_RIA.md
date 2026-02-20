# Concept de Fonctionnalité : Résumé d'Intervention Automatisé (RIA)

## 1. Objectif Fonctionnel
L'objectif est d'offrir au technicien une "vue d'aigle" instantanée sur l'état d'un site avant d'entamer son intervention. Plutôt que de parcourir manuellement l'historique complet des documents, le système génère une synthèse intelligente des éléments critiques.

### Bénéfices :
- **Gain de temps** : Lecture en moins de 30 secondes.
- **Efficacité accrue** : Identification des outils ou pièces nécessaires avant même le diagnostic.
- **Continuité de service** : Meilleure prise en compte des recommandations de ses collègues.

---

## 2. Logique de Synthèse (Algorithme métier)
Le RIA agrège les données des derniers CRI (Service et Projet) liés au site sélectionné. Il se décompose en 4 piliers :

### A. Le "Flash Info" (Indicateurs clés)
- **Status de la dernière visite** : Résolu, Partiel ou Non Résolu.
- **Récurrence** : Fréquence des interventions sur les 6 derniers mois.
- **Urgence** : Présence de tickets "Haute Priorité" non soldés.

### B. La Ligne de Temps Critique (Timeline)
Affichage des 3 derniers événements majeurs avec un focus sur :
- `identifiedCause` : Quelle était la source du problème ?
- `replacedParts` : Quelles pièces ont été changées récemment ?

### C. L'Héritage Technique (Le Savoir-Faire)
Extraction intelligente des champs `recommendations` et `cybersecurityRecommendations`. 
*Exemple : "Attention, l'alimentation du rack B est capricieuse. Prévoir un testeur de tension."*

### D. Analyse de Chronicité (Heuristique)
Le système détecte si une même `identifiedCause` apparaît plus de 2 fois en 3 mois et place une alerte orange **"Problème Chronique Détecté"**.

---

## 3. Parcours Utilisateur & UX (Interface Mobile)

### Étape 1 : Le Déclencheur (Trigger)
Dans l'écran de création d'un nouveau CRI, dès que le technicien sélectionne un **Site**, un bouton flottant ou une carte "Résumé Flash" apparaît en haut du formulaire.

### Étape 2 : L'Écran RIA (Vue Synthétique)
L'interface doit être optimisée pour le terrain :
- **Design Card-Based** : Utilisation de cartes avec codes couleurs (Rouge = Critique, Jaune = Attention, Vert = OK).
- **Mode Sombre / Haute Visibilité** : Pour une lecture en plein soleil ou en local technique sombre.
- **Interaction Swip** : Passer d'une section à l'autre d'un simple geste du pouce.

### Étape 3 : Actions Rapides
En bas du RIA, deux boutons d'action :
1. **"Démarrer avec ces infos"** : Ferme le résumé et pré-remplit certains champs du nouveau CRI (comme le numéro de ticket si c'est un suivi).
2. **"Voir l'historique complet"** : Redirige vers la liste détaillée de tous les anciens documents.

---

## 4. Architecture Technique (Haut Niveau)

- **Backend (.NET)** : Création d'un endpoint `GET /api/sites/{siteId}/summary` qui effectue les calculs d'agrégation et de détection de chronicité.
- **Frontend (Flutter)** :
    - Un composant `SummaryCard` réutilisable.
    - Utilisation du cache local (SQLite via Drift) pour garantir l'accès hors-ligne (Offline-First).
- **Stockage** : Les données de synthèse sont recalculées à chaque synchronisation des données pour rester à jour.

---

## 5. Maquette Conceptuelle (Visualisation)

```text
+---------------------------------------+
|  [X] RÉSUMÉ DU SITE : NOVADIS HQ      |
+---------------------------------------+
|  (!) ALERTE : Problème chronique      |
|      sur la Centrale Incendie Zone A  |
+---------------------------------------+
|  ÉTAT DES LIEUX :                     |
|  - Dernière visite : 15/02 (Partielle)|
|  - Pièce changée : Capteur Optique-X  |
+---------------------------------------+
|  CONSEIL TECH (Hugo D.) :             |
|  "Prévoir une échelle de 3m pour le   |
|  détecteur du hall."                  |
+---------------------------------------+
|  [ DÉMARRER ]     [ HISTORIQUE ]      |
+---------------------------------------+
```

---

## 6. Évolutions Futures
- **IA Générative** : Utilisation d'un LLM pour transformer les notes brutes des techniciens en un paragraphe de synthèse fluide et poli.
- **Photos Flash** : Affichage des 2 dernières photos "après intervention" pour montrer l'état attendu du site.
