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
        "requestDescription": "Lenteurs excessives sur l''application métier (Base de données)",
        "identifiedCause": "Saturation de la mémoire vive (RAM) sur le serveur de production",
        "replacedParts": "2x Barrette RAM 16Go DDR4",
        "resolutionStatus": "partiellementResolu",
        "recommendations": "La RAM a été doublée mais le CPU monte encore à 90%. Prévoir migration vers instance plus puissante."
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
        "requestDescription": "Déconnexions intermittentes du Wi-Fi dans tout l''étage 2",
        "identifiedCause": "Port SFP defectueux sur le switch coeur de réseau (Slot 4)",
        "replacedParts": "-",
        "resolutionStatus": "nonResolu",
        "recommendations": "Le module GBIC semble HS. Branchement temporaire sur le Slot 5, mais instable. Remplacement switch à prévoir.",
        "cybersecurityRecommendations": "Vérifier que le firmware du switch est à jour (v6.4 recommandée)."
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
        "requestDescription": "Coupure totale du réseau local et internet",
        "identifiedCause": "Tempête de broadcast causée par une boucle réseau",
        "replacedParts": "Câble RJ45 cat6a",
        "resolutionStatus": "nonResolu",
        "recommendations": "Un switch non administré a été branché par un utilisateur, créant une boucle. Localisation en cours."
    }'
);

PRINT 'Données de test Unicode insérées avec succès !';
GO
