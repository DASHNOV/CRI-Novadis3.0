-- ============================================================================
-- Script 01: Ajouter la colonne 'role' à la table Users (si elle n'existe pas)
-- Base: CRI_NovadisDB_Dev
-- Instance: 192.169.200.205\CRI_NOVADIS (port 1435)
-- ⚠️ NE PAS supprimer la table CRI ni ses données existantes
-- ============================================================================

USE CRI_NovadisDB_Dev;
GO

-- Vérifier si la colonne 'Role' existe déjà dans la table Users
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Users' 
    AND COLUMN_NAME = 'Role'
)
BEGIN
    ALTER TABLE Users ADD Role NVARCHAR(50) NOT NULL DEFAULT 'Technician';
    PRINT '✅ Colonne Role ajoutée à la table Users avec la valeur par défaut "Technician"';
END
ELSE
BEGIN
    PRINT 'ℹ️ La colonne Role existe déjà dans la table Users - aucune modification';
END
GO

-- Vérifier le résultat
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'Role';
GO
