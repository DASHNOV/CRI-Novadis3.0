using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AuthAttempts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    CodeHash = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    FailedAttempts = table.Column<int>(type: "integer", nullable: false),
                    PlainCode = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuthAttempts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ClientsNormalises",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RaisonSociale = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Contact = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Telephone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    Adresse = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CodePostal = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: true),
                    Ville = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Pays = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Actif = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClientsNormalises", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MagicLinks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Token = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MagicLinks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Sites",
                columns: table => new
                {
                    Numero = table.Column<int>(type: "integer", nullable: false),
                    NomDuSite = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Adresse = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Ville = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    CodePostal = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Pays = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ResponsableDorigine = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    DateDeCreation = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sites", x => x.Numero);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    Role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    FirstName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    LastName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    PhoneNumber = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastLoginAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Action = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    EntityType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    EntityId = table.Column<Guid>(type: "uuid", nullable: true),
                    Details = table.Column<string>(type: "text", nullable: true),
                    IpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AuditLogs_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "CRIForms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicianId = table.Column<Guid>(type: "uuid", nullable: false),
                    InterventionType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    InterventionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ClientName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    ClientAddress = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    ClientSite = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    ClientPhone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    ClientEmail = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    WorkDescription = table.Column<string>(type: "text", nullable: true),
                    MaterialsUsed = table.Column<string>(type: "text", nullable: true),
                    Duration = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Data = table.Column<string>(type: "text", nullable: true),
                    TechnicianSignature = table.Column<string>(type: "text", nullable: true),
                    ClientSignature = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SubmittedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    HeureDebut = table.Column<TimeSpan>(type: "interval", nullable: true),
                    HeureFin = table.Column<TimeSpan>(type: "interval", nullable: true),
                    DureeMinutes = table.Column<int>(type: "integer", nullable: true),
                    Ville = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    CodePostal = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: true),
                    Pays = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ClientContact = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    TicketNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Priority = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    ResolutionStatus = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    AdditionalInterventionRequired = table.Column<bool>(type: "boolean", nullable: true),
                    ProjectName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    ProjectNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    ProjectPhase = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    ProjectStatus = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    SiteID = table.Column<int>(type: "integer", nullable: true),
                    ClientID = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CRIForms", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CRIForms_ClientsNormalises_ClientID",
                        column: x => x.ClientID,
                        principalTable: "ClientsNormalises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_CRIForms_Sites_SiteID",
                        column: x => x.SiteID,
                        principalTable: "Sites",
                        principalColumn: "Numero",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_CRIForms_Users_TechnicianId",
                        column: x => x.TechnicianId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ExportedDocuments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CriId = table.Column<Guid>(type: "uuid", nullable: true),
                    Filename = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    FileType = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    ExportType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    StoragePath = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    SharedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PeriodStart = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PeriodEnd = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Metadata = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExportedDocuments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExportedDocuments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RefreshToken = table.Column<string>(type: "text", nullable: false),
                    TokenType = table.Column<string>(type: "text", nullable: false),
                    DeviceInfo = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    IpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsRevoked = table.Column<bool>(type: "boolean", nullable: false),
                    RevokedReason = table.Column<string>(type: "text", nullable: true),
                    TrustedDeviceToken = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserTokens_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CRIPhotos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CRIFormId = table.Column<Guid>(type: "uuid", nullable: false),
                    StoragePath = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    OriginalFileName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    MimeType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    FileSize = table.Column<long>(type: "bigint", nullable: false),
                    Description = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CRIPhotos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CRIPhotos_CRIForms_CRIFormId",
                        column: x => x.CRIFormId,
                        principalTable: "CRIForms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "Email", "FirstName", "IsActive", "LastLoginAt", "LastName", "PasswordHash", "PhoneNumber", "Role" },
                values: new object[,]
                {
                    { new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"), new DateTime(2026, 2, 5, 10, 31, 37, 0, DateTimeKind.Utc), "admin@novadis.fr", "Admin", true, null, "Système", "", null, "Admin" },
                    { new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"), new DateTime(2026, 2, 5, 10, 31, 37, 0, DateTimeKind.Utc), "technicien@novadis.local", "Jean", true, null, "Dupont", "", "0612345678", "Technician" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_CreatedAt",
                table: "AuditLogs",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AuthAttempts_Email",
                table: "AuthAttempts",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_AuthAttempts_Email_CreatedAt",
                table: "AuthAttempts",
                columns: new[] { "Email", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ClientsNormalises_RaisonSociale",
                table: "ClientsNormalises",
                column: "RaisonSociale");

            migrationBuilder.CreateIndex(
                name: "IX_ClientsNormalises_Ville",
                table: "ClientsNormalises",
                column: "Ville");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ClientID",
                table: "CRIForms",
                column: "ClientID");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_CreatedAt",
                table: "CRIForms",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_InterventionDate",
                table: "CRIForms",
                column: "InterventionDate");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Priority",
                table: "CRIForms",
                column: "Priority");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ProjectNumber",
                table: "CRIForms",
                column: "ProjectNumber");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ProjectStatus",
                table: "CRIForms",
                column: "ProjectStatus");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ResolutionStatus",
                table: "CRIForms",
                column: "ResolutionStatus");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_SiteID",
                table: "CRIForms",
                column: "SiteID");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Status",
                table: "CRIForms",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_TechnicianId",
                table: "CRIForms",
                column: "TechnicianId");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_TicketNumber",
                table: "CRIForms",
                column: "TicketNumber");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Ville",
                table: "CRIForms",
                column: "Ville");

            migrationBuilder.CreateIndex(
                name: "IX_CRIPhotos_CRIFormId",
                table: "CRIPhotos",
                column: "CRIFormId");

            migrationBuilder.CreateIndex(
                name: "IX_ExportedDocuments_CreatedAt",
                table: "ExportedDocuments",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_ExportedDocuments_CriId",
                table: "ExportedDocuments",
                column: "CriId");

            migrationBuilder.CreateIndex(
                name: "IX_ExportedDocuments_UserId",
                table: "ExportedDocuments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_MagicLinks_Email",
                table: "MagicLinks",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_MagicLinks_Token",
                table: "MagicLinks",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Sites_CodePostal",
                table: "Sites",
                column: "CodePostal");

            migrationBuilder.CreateIndex(
                name: "IX_Sites_NomDuSite",
                table: "Sites",
                column: "NomDuSite");

            migrationBuilder.CreateIndex(
                name: "IX_Sites_Ville",
                table: "Sites",
                column: "Ville");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_RefreshToken",
                table: "UserTokens",
                column: "RefreshToken",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_UserId",
                table: "UserTokens",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropTable(
                name: "AuthAttempts");

            migrationBuilder.DropTable(
                name: "CRIPhotos");

            migrationBuilder.DropTable(
                name: "ExportedDocuments");

            migrationBuilder.DropTable(
                name: "MagicLinks");

            migrationBuilder.DropTable(
                name: "UserTokens");

            migrationBuilder.DropTable(
                name: "CRIForms");

            migrationBuilder.DropTable(
                name: "ClientsNormalises");

            migrationBuilder.DropTable(
                name: "Sites");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
