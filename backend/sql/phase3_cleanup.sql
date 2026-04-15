-- ============================================================================
-- Phase 3 : Nettoyage des objets morts et corrections de sécurité
-- ============================================================================
-- Ce script :
--   1. Supprime les vues du Système A (ancien schéma français)
--   2. Supprime les procédures stockées obsolètes
--   3. Supprime les tables du Système A (ordre FK respecté)
--   4. Supprime la colonne PlainCode (faille sécurité)
--   5. Corrige les permissions de CRI_App_User (retire db_owner)
-- ============================================================================

-- ── Étape 1 : Suppression des vues ──

IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_InterventionsCompletes')
BEGIN
    DROP VIEW dbo.vw_InterventionsCompletes;
    PRINT 'Vue vw_InterventionsCompletes supprimée.';
END
GO

IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_StatistiquesTechniciens')
BEGIN
    DROP VIEW dbo.vw_StatistiquesTechniciens;
    PRINT 'Vue vw_StatistiquesTechniciens supprimée.';
END
GO

-- ── Étape 2 : Suppression des procédures stockées métier ──
-- (on garde les sp_*diagram* qui sont des utilitaires SSMS)

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GenererNumeroIntervention')
    DROP PROCEDURE sp_GenererNumeroIntervention;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetAllCRIsWithTechnician')
    DROP PROCEDURE sp_GetAllCRIsWithTechnician;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetDailyActivity')
    DROP PROCEDURE sp_GetDailyActivity;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetDashboardTechnicien')
    DROP PROCEDURE sp_GetDashboardTechnicien;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetGlobalStats')
    DROP PROCEDURE sp_GetGlobalStats;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetPersonalCRIs')
    DROP PROCEDURE sp_GetPersonalCRIs;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetPersonalStats')
    DROP PROCEDURE sp_GetPersonalStats;
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_GetTechnicianActivity')
    DROP PROCEDURE sp_GetTechnicianActivity;

PRINT '8 procédures stockées supprimées.';
GO

-- ── Étape 3 : Suppression des tables du Système A ──
-- Ordre : enfants d'abord (FK), puis parents

-- 3a. Tables enfants (dépendent d'Interventions)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Photos')
BEGIN
    DROP TABLE Photos;
    PRINT 'Table Photos supprimée.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Signatures')
BEGIN
    DROP TABLE Signatures;
    PRINT 'Table Signatures supprimée.';
END
GO

-- 3b. Table HistoriqueModifications (dépend d'Utilisateurs)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HistoriqueModifications')
BEGIN
    DROP TABLE HistoriqueModifications;
    PRINT 'Table HistoriqueModifications supprimée.';
END
GO

-- 3c. Table Interventions (dépend de Clients, Utilisateurs, Statuts, TypesIntervention)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Interventions')
BEGIN
    DROP TABLE Interventions;
    PRINT 'Table Interventions supprimée.';
END
GO

-- 3d. Tables référencées (plus aucune dépendance)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Clients')
BEGIN
    DROP TABLE Clients;
    PRINT 'Table Clients (ancienne) supprimée.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Utilisateurs')
BEGIN
    DROP TABLE Utilisateurs;
    PRINT 'Table Utilisateurs supprimée.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Statuts')
BEGIN
    DROP TABLE Statuts;
    PRINT 'Table Statuts supprimée.';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TypesIntervention')
BEGIN
    DROP TABLE TypesIntervention;
    PRINT 'Table TypesIntervention supprimée.';
END
GO

-- ── Étape 4 : Colonne PlainCode (sécurité) ──
-- PlainCode stocke le code d'authentification en clair.
-- Utilisé en DEV uniquement (gardes #if DEBUG dans le code C#).
-- ⚠️ DÉCOMMENTER pour la mise en PRODUCTION :
/*
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AuthAttempts') AND name = 'PlainCode')
BEGIN
    ALTER TABLE AuthAttempts DROP COLUMN PlainCode;
    PRINT 'Colonne PlainCode supprimée de AuthAttempts.';
END
*/
PRINT 'PlainCode conservé (environnement DEV).';
GO

-- ── Étape 5 : Correction des permissions ──
-- CRI_App_User a db_owner (accès total) → on ne garde que datareader + datawriter + ddladmin

-- Retirer db_owner
IF IS_ROLEMEMBER('db_owner', 'CRI_App_User') = 1
BEGIN
    ALTER ROLE db_owner DROP MEMBER CRI_App_User;
    PRINT 'Rôle db_owner retiré de CRI_App_User.';
END

-- Ajouter db_ddladmin pour permettre les migrations EF (CREATE/ALTER TABLE)
IF IS_ROLEMEMBER('db_ddladmin', 'CRI_App_User') = 0
BEGIN
    ALTER ROLE db_ddladmin ADD MEMBER CRI_App_User;
    PRINT 'Rôle db_ddladmin ajouté à CRI_App_User.';
END
GO

-- ── Vérification finale ──

PRINT '';
PRINT '=== Vérification Phase 3 ===';

SELECT 'Tables restantes' AS Info, COUNT(*) AS Nb FROM sys.tables
WHERE name NOT LIKE '__EF%' AND name != 'sysdiagrams';

SELECT 'Vues restantes' AS Info, COUNT(*) AS Nb FROM sys.views
WHERE name NOT IN ('syssegments','sysconstraints');

SELECT 'SP custom restantes' AS Info, COUNT(*) AS Nb FROM sys.procedures
WHERE name NOT LIKE 'sp_%diagram%';

SELECT 'PlainCode existe' AS Info,
    CASE WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AuthAttempts') AND name = 'PlainCode')
    THEN 'OUI (ERREUR)' ELSE 'NON (OK)' END AS Statut;

SELECT 'CRI_App_User db_owner' AS Info,
    CASE WHEN IS_ROLEMEMBER('db_owner', 'CRI_App_User') = 1
    THEN 'OUI (ERREUR)' ELSE 'NON (OK)' END AS Statut;
GO
