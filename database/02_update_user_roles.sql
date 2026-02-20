-- ============================================================================
-- Script 02: Mettre à jour les rôles des utilisateurs existants
-- Base: CRI_NovadisDB_Dev
-- ⚠️ Adapter les emails des administrateurs selon votre configuration
-- ============================================================================

USE CRI_NovadisDB_Dev;
GO

-- Vérification de l'état actuel
PRINT '--- État AVANT mise à jour ---';
SELECT Id, Email, FirstName, LastName, Role, IsActive
FROM Users
ORDER BY Role, LastName;
GO

-- Assigner le rôle Admin aux administrateurs identifiés
-- ⚠️ ADAPTER ces emails pour correspondre à vos vrais administrateurs
UPDATE Users 
SET Role = 'Admin' 
WHERE Email IN (
    'admin@novadis.local',          -- Admin système (seed data)
    'admin1@novadis.fr',            -- Admin 1
    'admin2@novadis.fr',            -- Admin 2
    'admin3@novadis.fr'             -- Admin 3
);

PRINT '✅ Rôles Admin assignés';

-- S'assurer que tous les autres utilisateurs sont "Technician"
UPDATE Users 
SET Role = 'Technician' 
WHERE Role IS NULL OR Role = '' OR Role NOT IN ('Admin', 'Technician');

PRINT '✅ Rôles Technician assignés aux utilisateurs sans rôle';

-- Vérification de l'état final
PRINT '--- État APRÈS mise à jour ---';
SELECT Id, Email, FirstName, LastName, Role, IsActive
FROM Users
ORDER BY Role, LastName;
GO

-- Résumé
SELECT Role, COUNT(*) AS NbUtilisateurs
FROM Users
GROUP BY Role;
GO
