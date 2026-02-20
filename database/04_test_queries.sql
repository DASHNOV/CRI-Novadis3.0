-- ============================================================================
-- Script 04: Tests de vérification
-- Base: CRI_NovadisDB_Dev
-- Exécuter après les scripts 01, 02, 03
-- ============================================================================

USE CRI_NovadisDB_Dev;
GO

PRINT '================================================================';
PRINT '  TESTS DE VÉRIFICATION DES PROCÉDURES STOCKÉES';
PRINT '================================================================';
PRINT '';

-- ─────────────────────────────────────────────────
-- Test 1: Vérifier la colonne Role dans Users
-- ─────────────────────────────────────────────────
PRINT '--- Test 1: Structure de la table Users ---';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Users';
GO

-- ─────────────────────────────────────────────────
-- Test 2: Vérifier les rôles assignés
-- ─────────────────────────────────────────────────
PRINT '--- Test 2: Rôles des utilisateurs ---';
SELECT Id, Email, FirstName, LastName, Role, IsActive
FROM Users
ORDER BY Role, LastName;
GO

-- ─────────────────────────────────────────────────
-- Test 3: Statistiques personnelles (admin user seed)
-- ─────────────────────────────────────────────────
PRINT '--- Test 3: sp_GetPersonalStats (admin seed) ---';
EXEC sp_GetPersonalStats @technicianId = 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d';
GO

-- ─────────────────────────────────────────────────
-- Test 4: CRI personnels (technicien seed)
-- ─────────────────────────────────────────────────
PRINT '--- Test 4: sp_GetPersonalCRIs (technicien seed) ---';
EXEC sp_GetPersonalCRIs 
    @technicianId = 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e', 
    @filter = 'all';
GO

-- ─────────────────────────────────────────────────
-- Test 5: Statistiques globales
-- ─────────────────────────────────────────────────
PRINT '--- Test 5: sp_GetGlobalStats ---';
EXEC sp_GetGlobalStats;
GO

-- ─────────────────────────────────────────────────
-- Test 6: Tous les CRI avec info technicien
-- ─────────────────────────────────────────────────
PRINT '--- Test 6: sp_GetAllCRIsWithTechnician (tous) ---';
EXEC sp_GetAllCRIsWithTechnician @technicianFilter = NULL, @statusFilter = 'all';
GO

-- ─────────────────────────────────────────────────
-- Test 7: Activité par technicien
-- ─────────────────────────────────────────────────
PRINT '--- Test 7: sp_GetTechnicianActivity ---';
EXEC sp_GetTechnicianActivity;
GO

-- ─────────────────────────────────────────────────
-- Test 8: Activité journalière
-- ─────────────────────────────────────────────────
PRINT '--- Test 8: sp_GetDailyActivity ---';
EXEC sp_GetDailyActivity;
GO

-- ─────────────────────────────────────────────────
-- Test 9: Vérifier les procédures stockées créées
-- ─────────────────────────────────────────────────
PRINT '--- Test 9: Liste des procédures stockées ---';
SELECT name, create_date, modify_date
FROM sys.procedures
WHERE name LIKE 'sp_Get%'
ORDER BY name;
GO

PRINT '';
PRINT '=== Tests terminés ===';
GO
