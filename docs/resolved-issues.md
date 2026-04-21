# Problèmes Résolus — Base de Connaissances

> Ce fichier documente les bugs et erreurs résolus pour éviter de les répéter.
> Format : Problème → Cause → Solution → Règle de prévention.

---

## 001 — Erreur de collation SQL à l'import de BDD

- **Problème** : Import de `BDD.sql` échoue avec `Unknown collation: 'utf8mb4_uca1400_ai_ci'`.
- **Cause** : Le dump SQL provenait d'un MariaDB récent (10.10+) utilisant une collation non supportée par le serveur cible (MySQL / MariaDB plus ancien).
- **Solution** : Remplacer toutes les occurrences de `utf8mb4_uca1400_ai_ci` par `utf8mb4_general_ci` dans le fichier `.sql` avant import.
- **Règle de prévention** : Toujours vérifier la compatibilité des collations entre l'environnement d'export et l'environnement cible. Privilégier `utf8mb4_general_ci` pour la portabilité.

---

## 002 — Signatures manquantes dans l'export PDF CRI

- **Problème** : Les signatures n'apparaissent pas dans les PDF exportés (CRI Projet et CRI Service).
- **Cause** : Le template PDF ne récupérait pas les données de signature depuis le DOM/state au moment de la génération.
- **Solution** : Correction du template de génération PDF pour inclure les blocs de signatures.
- **Règle de prévention** : Après chaque modification du formulaire CRI, vérifier systématiquement que l'export PDF reflète tous les champs visibles à l'écran.

---

## 003 — Injection SQL via f-strings Python

- **Problème** : Requêtes SQL construites avec des f-strings, vulnérables à l'injection SQL.
- **Cause** : Concaténation directe des entrées utilisateur dans les requêtes sans échappement.
- **Solution** : Remplacement de toutes les f-strings SQL par des requêtes paramétrées (`cursor.execute(query, params)`).
- **Règle de prévention** : Ne jamais insérer de variables utilisateur directement dans une chaîne SQL. Toujours utiliser des requêtes paramétrées.

---

## 004 — Erreurs d'import de modules Python (WoW Killer)

- **Problème** : `ModuleNotFoundError` au lancement de `main.py` depuis la racine du projet.
- **Cause** : Imports relatifs incorrects ; le script attendait d'être lancé depuis un sous-dossier.
- **Solution** : Restructuration des imports pour fonctionner depuis la racine du projet.
- **Règle de prévention** : Toujours tester le lancement d'un projet Python depuis sa racine. Utiliser des imports absolus basés sur le package racine.

---

## 005 — Bandeau d'avertissement jaune/noir sur page CRI Projet

- **Problème** : Bandeau warning jaune/noir indésirable affiché sur la page de création CRI Projet.
- **Cause** : Élément CSS de debug/warning laissé dans le template de production.
- **Solution** : Suppression des éléments HTML et styles CSS du bandeau warning.
- **Règle de prévention** : Nettoyer tous les éléments de debug/dev (banners, console.log, etc.) avant de considérer une fonctionnalité comme terminée.
