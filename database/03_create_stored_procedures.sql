-- ============================================================================
-- Script 03: Créer les procédures stockées pour le dashboard et les statistiques
-- Base: CRI_NovadisDB_Dev
-- Tables utilisées: Users, CRIForms
-- ⚠️ Utilise les vrais noms de colonnes (TechnicianId, CreatedAt, Status, ClientSignature)
-- ============================================================================

USE CRI_NovadisDB_Dev;
GO

-- ============================================================================
-- 1. sp_GetPersonalStats : Statistiques personnelles d'un technicien
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetPersonalStats
    @technicianId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE TechnicianId = @technicianId 
           AND MONTH(CreatedAt) = MONTH(GETDATE()) 
           AND YEAR(CreatedAt) = YEAR(GETDATE())
        ) AS CriCeMois,
        
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE TechnicianId = @technicianId 
           AND Status = 'Draft'
        ) AS CriEnCours,
        
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE TechnicianId = @technicianId 
           AND ClientSignature IS NULL
        ) AS CriEnAttente;
END
GO

PRINT '✅ Procédure sp_GetPersonalStats créée';
GO

-- ============================================================================
-- 2. sp_GetPersonalCRIs : CRI d'un technicien avec filtre
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetPersonalCRIs
    @technicianId UNIQUEIDENTIFIER,
    @filter NVARCHAR(20) = 'all'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM CRIForms
    WHERE TechnicianId = @technicianId
      AND (
          @filter = 'all'
          OR (@filter = 'pending' AND ClientSignature IS NULL)
          OR (@filter = 'signed' AND ClientSignature IS NOT NULL)
          OR (@filter = 'in_progress' AND Status = 'Draft')
      )
    ORDER BY CreatedAt DESC;
END
GO

PRINT '✅ Procédure sp_GetPersonalCRIs créée';
GO

-- ============================================================================
-- 3. sp_GetGlobalStats : Statistiques globales (admin uniquement)
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetGlobalStats
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE MONTH(CreatedAt) = MONTH(GETDATE()) 
           AND YEAR(CreatedAt) = YEAR(GETDATE())
        ) AS TotalCeMois,
        
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE ClientSignature IS NOT NULL
        ) AS TotalSignes,
        
        (SELECT COUNT(*) 
         FROM CRIForms 
         WHERE ClientSignature IS NULL
        ) AS TotalEnAttente,
        
        (SELECT COUNT(DISTINCT TechnicianId) 
         FROM CRIForms 
         WHERE CreatedAt >= DATEADD(day, -30, GETDATE())
        ) AS TechniciensActifs;
END
GO

PRINT '✅ Procédure sp_GetGlobalStats créée';
GO

-- ============================================================================
-- 4. sp_GetAllCRIsWithTechnician : Tous les CRI avec info technicien (admin)
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetAllCRIsWithTechnician
    @technicianFilter UNIQUEIDENTIFIER = NULL,
    @statusFilter NVARCHAR(20) = 'all'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.*,
        u.FirstName AS TechnicianFirstName,
        u.LastName AS TechnicianLastName,
        u.Email AS TechnicianEmail
    FROM CRIForms c
    INNER JOIN Users u ON c.TechnicianId = u.Id
    WHERE (@technicianFilter IS NULL OR c.TechnicianId = @technicianFilter)
      AND (
          @statusFilter = 'all'
          OR (@statusFilter = 'signed' AND c.ClientSignature IS NOT NULL)
          OR (@statusFilter = 'pending' AND c.ClientSignature IS NULL)
      )
    ORDER BY c.CreatedAt DESC;
END
GO

PRINT '✅ Procédure sp_GetAllCRIsWithTechnician créée';
GO

-- ============================================================================
-- 5. sp_GetTechnicianActivity : Activité de chaque technicien (admin)
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetTechnicianActivity
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.Id,
        u.FirstName,
        u.LastName,
        COUNT(c.Id) AS NbCriTotal,
        SUM(CASE WHEN c.CreatedAt >= DATEADD(day, -7, GETDATE()) THEN 1 ELSE 0 END) AS NbCri7j,
        SUM(CASE WHEN c.CreatedAt >= DATEADD(day, -30, GETDATE()) THEN 1 ELSE 0 END) AS NbCri30j
    FROM Users u
    LEFT JOIN CRIForms c ON u.Id = c.TechnicianId
    WHERE u.Role IN ('Technician', 'Admin')
      AND u.IsActive = 1
    GROUP BY u.Id, u.FirstName, u.LastName
    ORDER BY NbCri30j DESC;
END
GO

PRINT '✅ Procédure sp_GetTechnicianActivity créée';
GO

-- ============================================================================
-- 6. sp_GetDailyActivity : Données pour graphique d'activité (7 derniers jours)
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetDailyActivity
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CAST(CreatedAt AS DATE) AS Jour,
        COUNT(*) AS Nb
    FROM CRIForms
    WHERE CreatedAt >= DATEADD(day, -7, GETDATE())
    GROUP BY CAST(CreatedAt AS DATE)
    ORDER BY Jour;
END
GO

PRINT '✅ Procédure sp_GetDailyActivity créée';
GO

PRINT '';
PRINT '=== Toutes les procédures stockées ont été créées avec succès ===';
GO
