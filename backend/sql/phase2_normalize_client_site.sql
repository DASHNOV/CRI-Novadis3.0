-- ============================================================================
-- Phase 2 : Normalisation des relations Client et Site
-- ============================================================================
-- Ce script :
--   1. Crée la table ClientsNormalises (si elle n'existe pas)
--   2. Ajoute SiteID et ClientID sur CRIForms (si pas déjà présents)
--   3. Peuple ClientsNormalises depuis les clients distincts des CRI existants
--   4. Relie les CRI existants aux Sites et Clients
-- ============================================================================

-- ── Étape 1 : Création de la table ClientsNormalises ──

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ClientsNormalises')
BEGIN
    CREATE TABLE ClientsNormalises (
        Id              uniqueidentifier    NOT NULL DEFAULT NEWID(),
        RaisonSociale   nvarchar(255)       NOT NULL,
        Contact         nvarchar(100)       NULL,
        Telephone       varchar(20)         NULL,
        Email           nvarchar(255)       NULL,
        Adresse         nvarchar(500)       NULL,
        CodePostal      varchar(10)         NULL,
        Ville           nvarchar(100)       NULL,
        Pays            nvarchar(100)       NULL,
        Actif           bit                 NOT NULL DEFAULT 1,
        CreatedAt       datetime2(7)        NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt       datetime2(7)        NULL,
        CONSTRAINT PK_ClientsNormalises PRIMARY KEY (Id)
    );

    CREATE NONCLUSTERED INDEX IX_ClientsNormalises_RaisonSociale
        ON ClientsNormalises (RaisonSociale);
    CREATE NONCLUSTERED INDEX IX_ClientsNormalises_Ville
        ON ClientsNormalises (Ville);

    PRINT 'Table ClientsNormalises créée.';
END
ELSE
    PRINT 'Table ClientsNormalises existe déjà.';
GO

-- ── Étape 2 : Ajout des FK sur CRIForms ──

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('CRIForms') AND name = 'SiteID')
BEGIN
    ALTER TABLE CRIForms ADD SiteID int NULL;
    ALTER TABLE CRIForms ADD CONSTRAINT FK_CRIForms_Sites
        FOREIGN KEY (SiteID) REFERENCES Sites(Numero) ON DELETE SET NULL;
    CREATE NONCLUSTERED INDEX IX_CRIForms_SiteID ON CRIForms (SiteID);
    PRINT 'Colonne SiteID ajoutée avec FK.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('CRIForms') AND name = 'ClientID')
BEGIN
    ALTER TABLE CRIForms ADD ClientID uniqueidentifier NULL;
    ALTER TABLE CRIForms ADD CONSTRAINT FK_CRIForms_ClientsNormalises
        FOREIGN KEY (ClientID) REFERENCES ClientsNormalises(Id) ON DELETE SET NULL;
    CREATE NONCLUSTERED INDEX IX_CRIForms_ClientID ON CRIForms (ClientID);
    PRINT 'Colonne ClientID ajoutée avec FK.';
END
GO

-- ── Étape 3 : Peupler ClientsNormalises depuis les CRI existants ──
-- On prend le CRI le plus récent de chaque client pour récupérer les coordonnées

INSERT INTO ClientsNormalises (Id, RaisonSociale, Contact, Telephone, Email, Adresse, CodePostal, Ville, Pays)
SELECT
    NEWID(),
    c.ClientName,
    c.ClientContact,
    c.ClientPhone,
    c.ClientEmail,
    c.ClientAddress,
    c.CodePostal,
    c.Ville,
    c.Pays
FROM (
    SELECT
        ClientName,
        ClientContact,
        ClientPhone,
        ClientEmail,
        ClientAddress,
        CodePostal,
        Ville,
        Pays,
        ROW_NUMBER() OVER (PARTITION BY ClientName ORDER BY CreatedAt DESC) AS rn
    FROM CRIForms
    WHERE ClientName IS NOT NULL AND ClientName != ''
) c
WHERE c.rn = 1
  AND NOT EXISTS (
      SELECT 1 FROM ClientsNormalises cn WHERE cn.RaisonSociale = c.ClientName
  );

PRINT CONCAT(@@ROWCOUNT, ' clients créés dans ClientsNormalises.');
GO

-- ── Étape 4 : Relier les CRI existants aux Clients ──

UPDATE cri
SET cri.ClientID = cn.Id
FROM CRIForms cri
INNER JOIN ClientsNormalises cn ON cn.RaisonSociale = cri.ClientName
WHERE cri.ClientID IS NULL;

PRINT CONCAT(@@ROWCOUNT, ' CRI reliés à un client.');
GO

-- ── Étape 5 : Relier les CRI existants aux Sites ──
-- Matching exact sur le nom du site

UPDATE cri
SET cri.SiteID = s.Numero
FROM CRIForms cri
INNER JOIN Sites s ON s.NomDuSite = cri.ClientSite
WHERE cri.SiteID IS NULL
  AND cri.ClientSite IS NOT NULL;

PRINT CONCAT(@@ROWCOUNT, ' CRI reliés à un site.');
GO

-- ── Vérification ──

SELECT 'Résumé Phase 2' AS Info,
    (SELECT COUNT(*) FROM ClientsNormalises) AS NbClients,
    (SELECT COUNT(*) FROM CRIForms WHERE ClientID IS NOT NULL) AS CriAvecClient,
    (SELECT COUNT(*) FROM CRIForms WHERE SiteID IS NOT NULL) AS CriAvecSite,
    (SELECT COUNT(*) FROM CRIForms) AS TotalCRI;
GO
