-- ============================================================================
-- Phase 1 : Extraction des colonnes statistiques depuis le JSON Data
-- ============================================================================
-- Ce script :
--   1. Ajoute les nouvelles colonnes à CRIForms (si elles n'existent pas)
--   2. Remplit les colonnes depuis le JSON Data existant (rattrapage)
--   3. Crée les index pour les requêtes statistiques
-- ============================================================================

-- ── Étape 1 : Ajout des colonnes ──

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('CRIForms') AND name = 'HeureDebut')
BEGIN
    ALTER TABLE CRIForms ADD
        HeureDebut          time(7)         NULL,
        HeureFin            time(7)         NULL,
        DureeMinutes        int             NULL,
        Ville               nvarchar(100)   NULL,
        CodePostal          varchar(10)     NULL,
        Pays                nvarchar(100)   NULL,
        ClientContact       nvarchar(100)   NULL,
        TicketNumber        varchar(50)     NULL,
        Priority            varchar(20)     NULL,
        ResolutionStatus    varchar(30)     NULL,
        AdditionalInterventionRequired bit NULL,
        ProjectName         nvarchar(255)   NULL,
        ProjectNumber       varchar(50)     NULL,
        ProjectPhase        varchar(30)     NULL,
        ProjectStatus       varchar(30)     NULL;

    PRINT 'Colonnes ajoutées avec succès.';
END
ELSE
BEGIN
    PRINT 'Les colonnes existent déjà, étape ignorée.';
END
GO

-- ── Étape 2 : Rattrapage des données existantes depuis le JSON ──

UPDATE CRIForms
SET
    HeureDebut = TRY_CAST(
        CONVERT(time, TRY_CAST(JSON_VALUE(Data, '$.startTime') AS datetime2))
        AS time),
    HeureFin = TRY_CAST(
        CONVERT(time, TRY_CAST(JSON_VALUE(Data, '$.endTime') AS datetime2))
        AS time),
    DureeMinutes = COALESCE(
        -- Service : interventionDurationMinutes directement dans le JSON
        TRY_CAST(JSON_VALUE(Data, '$.interventionDurationMinutes') AS int),
        -- Projet : calculer depuis startTime/endTime
        DATEDIFF(
            MINUTE,
            TRY_CAST(JSON_VALUE(Data, '$.startTime') AS datetime2),
            TRY_CAST(JSON_VALUE(Data, '$.endTime') AS datetime2)
        )
    ),
    Ville           = JSON_VALUE(Data, '$.ville'),
    CodePostal      = JSON_VALUE(Data, '$.codePostal'),
    Pays            = JSON_VALUE(Data, '$.pays'),
    ClientContact   = JSON_VALUE(Data, '$.clientContact'),
    TicketNumber    = JSON_VALUE(Data, '$.ticketNumber'),
    Priority        = JSON_VALUE(Data, '$.priority'),
    ResolutionStatus = JSON_VALUE(Data, '$.resolutionStatus'),
    AdditionalInterventionRequired = CASE
        WHEN JSON_VALUE(Data, '$.additionalInterventionRequired') = 'true' THEN 1
        WHEN JSON_VALUE(Data, '$.additionalInterventionRequired') = '1' THEN 1
        ELSE 0
    END,
    ProjectName     = JSON_VALUE(Data, '$.projectName'),
    ProjectNumber   = JSON_VALUE(Data, '$.projectNumber'),
    ProjectPhase    = JSON_VALUE(Data, '$.projectPhase'),
    ProjectStatus   = JSON_VALUE(Data, '$.projectStatus')
WHERE Data IS NOT NULL
  AND HeureDebut IS NULL;  -- Ne pas re-traiter les lignes déjà migrées

PRINT CONCAT(@@ROWCOUNT, ' CRI mis à jour avec les données extraites du JSON.');
GO

-- ── Étape 3 : Index pour les requêtes statistiques ──

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_InterventionDate' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_InterventionDate ON CRIForms (InterventionDate DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_Status' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_Status ON CRIForms (Status);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_Priority' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_Priority ON CRIForms (Priority);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_ResolutionStatus' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_ResolutionStatus ON CRIForms (ResolutionStatus);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_Ville' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_Ville ON CRIForms (Ville);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_ProjectStatus' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_ProjectStatus ON CRIForms (ProjectStatus);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_TicketNumber' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_TicketNumber ON CRIForms (TicketNumber);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CRIForms_ProjectNumber' AND object_id = OBJECT_ID('CRIForms'))
    CREATE NONCLUSTERED INDEX IX_CRIForms_ProjectNumber ON CRIForms (ProjectNumber);

PRINT 'Index créés avec succès.';
GO

-- ── Vérification ──

SELECT
    'Résumé migration Phase 1' AS Info,
    COUNT(*) AS TotalCRI,
    SUM(CASE WHEN DureeMinutes IS NOT NULL THEN 1 ELSE 0 END) AS AvecDuree,
    SUM(CASE WHEN Ville IS NOT NULL THEN 1 ELSE 0 END) AS AvecVille,
    SUM(CASE WHEN Priority IS NOT NULL THEN 1 ELSE 0 END) AS AvecPriorite,
    SUM(CASE WHEN ResolutionStatus IS NOT NULL THEN 1 ELSE 0 END) AS AvecStatutResolution,
    SUM(CASE WHEN ProjectName IS NOT NULL THEN 1 ELSE 0 END) AS AvecNomProjet,
    SUM(CASE WHEN TicketNumber IS NOT NULL THEN 1 ELSE 0 END) AS AvecNumeroTicket
FROM CRIForms;
GO
