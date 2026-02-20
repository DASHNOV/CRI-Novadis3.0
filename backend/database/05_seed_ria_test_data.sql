-- ===================================================================================
-- Script de test pour la fonctionnalité RIA (Résumé d'Intervention Automatisé)
-- Version Unicode corrigée
-- ===================================================================================

USE [CRI_NovadisDB_Dev];
GO

DECLARE @TechId UNIQUEIDENTIFIER = '9804D2B3-B415-47E7-B32A-23DBF9C63B48'; 
DECLARE @SiteName NVARCHAR(255) = N'NOVADIS HQ';

DELETE FROM CRIForms WHERE ClientSite = @SiteName;

-- CRI #1 : Il y a 2 mois - Résolu partiellement
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientSite, ClientAddress, Status, CreatedAt, Data)
VALUES (
    NEWID(), @TechId, 'Service', 'Dépannage', 
    DATEADD(month, -2, GETUTCDATE()), 
    N'Novadis Services', @SiteName, N'15 Rue de l''Innovation, Paris', 
    'Submitted', DATEADD(month, -2, GETUTCDATE()),
    N'{
        "technicianName": "Jean Dupont",
        "ticketNumber": "TICK-2025-00101",
        "priority": "normale",
        "requestDescription": "Problème de climatisation Zone A",
        "identifiedCause": "Fuite lente sur le raccord du compresseur principal",
        "replacedParts": "Joint torique",
        "resolutionStatus": "partiellementResolu",
        "recommendations": "Surveiller la pression la semaine prochaine."
    }'
);

-- CRI #2 : Il y a 1 mois - Non résolu
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientSite, ClientAddress, Status, CreatedAt, Data)
VALUES (
    NEWID(), @TechId, 'Service', 'Dépannage', 
    DATEADD(month, -1, GETUTCDATE()), 
    N'Novadis Services', @SiteName, N'15 Rue de l''Innovation, Paris', 
    'Submitted', DATEADD(month, -1, GETUTCDATE()),
    N'{
        "technicianName": "Marie Martin",
        "ticketNumber": "TICK-2025-00205",
        "priority": "haute",
        "requestDescription": "Arrêt complet clim Zone A",
        "identifiedCause": "Fuite lente sur le raccord du compresseur principal",
        "replacedParts": "-",
        "resolutionStatus": "nonResolu",
        "recommendations": "Le joint n''a pas tenu. Prévoir remplacement du raccord complet.",
        "cybersecurityRecommendations": "S''assurer que le boîtier de contrôle reste hors réseau public."
    }'
);

-- CRI #3 : Il y a 10 jours - Non résolu, priorité CRITIQUE
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientSite, ClientAddress, Status, CreatedAt, Data)
VALUES (
    NEWID(), @TechId, 'Service', 'Dépannage', 
    DATEADD(day, -10, GETUTCDATE()), 
    N'Novadis Services', @SiteName, N'15 Rue de l''Innovation, Paris', 
    'Submitted', DATEADD(day, -10, GETUTCDATE()),
    N'{
        "technicianName": "Jean Dupont",
        "ticketNumber": "TICK-2025-00312",
        "priority": "critique",
        "requestDescription": "Fuite gaz importante",
        "identifiedCause": "Fuite lente sur le raccord du compresseur principal",
        "replacedParts": "Azote pour test",
        "resolutionStatus": "nonResolu",
        "recommendations": "Prévoir une échelle de 3m pour accéder au compresseur. Le raccord est fissuré."
    }'
);

PRINT 'Données de test Unicode insérées avec succès !';
GO
