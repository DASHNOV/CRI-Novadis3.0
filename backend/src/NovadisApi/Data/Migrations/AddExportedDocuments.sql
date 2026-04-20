BEGIN TRANSACTION;
GO

CREATE TABLE [ExportedDocuments] (
    [Id] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [CriId] uniqueidentifier NULL,
    [Filename] nvarchar(300) NOT NULL,
    [FileType] nvarchar(10) NOT NULL,
    [ExportType] nvarchar(30) NOT NULL,
    [StoragePath] nvarchar(500) NOT NULL,
    [SizeBytes] bigint NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [SharedAt] datetime2 NULL,
    [PeriodStart] datetime2 NULL,
    [PeriodEnd] datetime2 NULL,
    [Metadata] nvarchar(2000) NULL,
    CONSTRAINT [PK_ExportedDocuments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ExportedDocuments_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_ExportedDocuments_CreatedAt] ON [ExportedDocuments] ([CreatedAt]);
GO

CREATE INDEX [IX_ExportedDocuments_CriId] ON [ExportedDocuments] ([CriId]);
GO

CREATE INDEX [IX_ExportedDocuments_UserId] ON [ExportedDocuments] ([UserId]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260417140510_AddExportedDocuments', N'8.0.1');
GO

COMMIT;
GO

