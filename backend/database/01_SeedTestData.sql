-- ===================================================================================
-- Script de peuplement de données de test pour l'application Novadis CRI
-- Ce script génère des techniciens, des interventions et des logs cohérents.
-- ===================================================================================

USE [NovadisDb];
GO

-- Désactiver les contraintes pour faciliter le nettoyage si nécessaire (optionnel)
-- EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'

-- 1. Nettoyage des données existantes (Techniciens de test uniquement)
-- On garde l'admin et le technicien par défaut créés par le SeedData de EF Core
DELETE FROM AuditLogs;
DELETE FROM CRIPhotos;
DELETE FROM CRIForms;
DELETE FROM Users WHERE Email NOT IN ('admin@novadis.local', 'technicien@novadis.local');

-- 2. Ajout de Techniciens supplémentaires (pour simuler une équipe)
DECLARE @TechMarieId UNIQUEIDENTIFIER = 'C3D4E5F6-A7B8-4C9D-0E1F-2A3B4C5D6E7F';
DECLARE @TechPierreId UNIQUEIDENTIFIER = 'D4E5F6A7-B8C9-4D0E-1F2A-3B4C5D6E7F8A';

INSERT INTO Users (Id, Email, PasswordHash, Role, FirstName, LastName, PhoneNumber, IsActive, CreatedAt)
VALUES 
(@TechMarieId, 'marie.martin@novadis.fr', 'AQAAAAEAACcQAAAAE...', 'Technician', 'Marie', 'Martin', '06 11 22 33 44', 1, DATEADD(month, -2, GETUTCDATE())),
(@TechPierreId, 'pierre.durand@novadis.fr', 'AQAAAAEAACcQAAAAE...', 'Technician', 'Pierre', 'Durand', '06 22 33 44 55', 1, DATEADD(month, -1, GETUTCDATE()));

-- 3. Ajout de formulaires CRI (Compte-Rendu d'Intervention)
DECLARE @TechJeanId UNIQUEIDENTIFIER = 'B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E'; -- Créé par EF Core
DECLARE @CRI1Id UNIQUEIDENTIFIER = NEWID();
DECLARE @CRI2Id UNIQUEIDENTIFIER = NEWID();
DECLARE @CRI3Id UNIQUEIDENTIFIER = NEWID();
DECLARE @CRI4Id UNIQUEIDENTIFIER = NEWID();
DECLARE @CRI5Id UNIQUEIDENTIFIER = NEWID();

-- CRI #1: Installation Validée (Jean Dupont)
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientAddress, WorkDescription, MaterialsUsed, Duration, Status, CreatedAt, SubmittedAt, Data)
VALUES (
    @CRI1Id, 
    @TechJeanId, 
    'Project', 
    'Installation', 
    DATEADD(day, -10, GETUTCDATE()), 
    'Clinique du Parc', 
    '45 Boulevard de la République, 69006 Lyon', 
    'Mise en place de la centrale de traitement d''air (CTA) au bloc opératoire n°3. Raccordements électriques et aérauliques terminés.', 
    'Filtres HEPA, Gaine isolée 400mm, Variateur de vitesse ABB', 
    14.5, 
    'Validated', 
    DATEADD(day, -11, GETUTCDATE()), 
    DATEADD(day, -10, GETUTCDATE()),
    '{"roomNumber": "B3", "equipmentTag": "CTA-03", "airflowMeasured": 2500}'
);

-- CRI #2: Maintenance Préventive Soumise (Marie Martin)
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientAddress, WorkDescription, MaterialsUsed, Duration, Status, CreatedAt, SubmittedAt, Data)
VALUES (
    @CRI2Id, 
    @TechMarieId, 
    'Service', 
    'Maintenance', 
    DATEADD(day, -2, GETUTCDATE()), 
    'Supermarché Express', 
    '12 Place du Marché, 75015 Paris', 
    'Maintenance trimestrielle des meubles frigorifiques négatifs. Vérification des températures et dégivrage.', 
    'Solution de nettoyage, Gaz R449A (appoint 200g)', 
    3.5, 
    'Submitted', 
    DATEADD(day, -2, GETUTCDATE()), 
    DATEADD(day, -2, GETUTCDATE()),
    '{"fridgeCount": 8, "tempAvg": -22.5, "alarmCheck": "OK"}'
);

-- CRI #3: Dépannage Urgent en Brouillon (Jean Dupont)
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientAddress, ClientPhone, WorkDescription, Status, CreatedAt)
VALUES (
    @CRI3Id, 
    @TechJeanId, 
    'Service', 
    'Repair', 
    GETUTCDATE(), 
    'Restaurant l''Escalier', 
    '2 Rue des Gourmets, 44000 Nantes', 
    '02 40 50 60 70',
    'Panne totale de la chambre froide positive. Compresseur semble HS. Commande de pièce à prévoir.', 
    'Draft', 
    GETUTCDATE()
);

-- CRI #4: Expertise Technique (Pierre Durand)
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientAddress, WorkDescription, Duration, Status, CreatedAt, SubmittedAt)
VALUES (
    @CRI4Id, 
    @TechPierreId, 
    'Project', 
    'Expertise', 
    DATEADD(day, -5, GETUTCDATE()), 
    'Immeuble Le Quartz', 
    '50 Avenue des Champs, 92000 Nanterre', 
    'Audit technique du réseau incendie. Test de pression et vérification des vannes de zone.', 
    4.0, 
    'Validated', 
    DATEADD(day, -6, GETUTCDATE()), 
    DATEADD(day, -5, GETUTCDATE())
);

-- CRI #5: Installation en cours (Marie Martin)
INSERT INTO CRIForms (Id, TechnicianId, InterventionType, Category, InterventionDate, ClientName, ClientAddress, WorkDescription, Status, CreatedAt)
VALUES (
    @CRI5Id, 
    @TechMarieId, 
    'Project', 
    'Installation', 
    GETUTCDATE(), 
    'DataCenter Link', 
    'Zone Industrielle, 13010 Marseille', 
    'Phase 1 : Pose des supports pour le passage des câbles réseau.', 
    'Draft', 
    GETUTCDATE()
);

-- 4. Ajout de Photos de test (liées aux formulaires)
INSERT INTO CRIPhotos (Id, CRIFormId, StoragePath, OriginalFileName, MimeType, FileSize, Description, UploadedAt)
VALUES 
(NEWID(), @CRI1Id, 'photos/2026/02/cta_install.jpg', 'cta_install.jpg', 'image/jpeg', 2500000, 'Vue d''ensemble de la CTA installée', DATEADD(day, -10, GETUTCDATE())),
(NEWID(), @CRI1Id, 'photos/2026/02/panel_wiring.jpg', 'panel_wiring.jpg', 'image/jpeg', 1800000, 'Détail du câblage de l''armoire', DATEADD(day, -10, GETUTCDATE())),
(NEWID(), @CRI2Id, 'photos/2026/02/fridge_temp.png', 'temp_check.png', 'image/png', 500000, 'Capture d''écran du contrôleur T°', DATEADD(day, -2, GETUTCDATE())),
(NEWID(), @CRI3Id, 'photos/2026/02/leaking_unit.jpg', 'leak.jpg', 'image/jpeg', 3200000, 'Localisation de la fuite sur le condenseur', GETUTCDATE());

-- 5. Audit Logs (pour l'historique d'activité)
INSERT INTO AuditLogs (Id, UserId, Action, EntityType, EntityId, Details, IpAddress, UserAgent, CreatedAt)
VALUES 
(NEWID(), @TechJeanId, 'Login', 'User', @TechJeanId, '{"platform": "Mobile", "version": "2.1.0"}', '176.12.34.56', 'NovadisApp/Flutter', DATEADD(hour, -8, GETUTCDATE())),
(NEWID(), @TechJeanId, 'CreateCRI', 'CRIForm', @CRI3Id, '{"method": "QuickStart"}', '176.12.34.56', 'NovadisApp/Flutter', GETUTCDATE()),
(NEWID(), @TechMarieId, 'Login', 'User', @TechMarieId, '{"platform": "Web", "browser": "Chrome"}', '82.45.67.89', 'Mozilla/5.0...', DATEADD(hour, -4, GETUTCDATE())),
(NEWID(), @TechMarieId, 'UpdateCRI', 'CRIForm', @CRI5Id, '{"fields": ["WorkDescription"]}', '82.45.67.89', 'Mozilla/5.0...', DATEADD(minute, -30, GETUTCDATE()));

-- 6. Tentatives d''authentification (Codes de connexion)
INSERT INTO AuthAttempts (Id, Email, CodeHash, PlainCode, CreatedAt, ExpiresAt, IsUsed, IpAddress)
VALUES 
(NEWID(), 'technicien@novadis.local', 'HASH123', '123456', DATEADD(minute, -15, GETUTCDATE()), DATEADD(minute, -5, GETUTCDATE()), 1, '176.12.34.56'),
(NEWID(), 'marie.martin@novadis.fr', 'HASH456', '654321', GETUTCDATE(), DATEADD(minute, 10, GETUTCDATE()), 0, '82.45.67.89');

-- Réactiver les contraintes (optionnel)
-- EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'

PRINT 'Données de test insérées avec succès !';
GO
