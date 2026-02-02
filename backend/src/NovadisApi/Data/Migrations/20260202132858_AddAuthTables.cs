using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAuthTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CRIForms_InterventionDate",
                table: "CRIForms");

            migrationBuilder.DropIndex(
                name: "IX_CRIForms_Status",
                table: "CRIForms");

            migrationBuilder.DropIndex(
                name: "IX_AuditLogs_Action",
                table: "AuditLogs");

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("23819a5c-870e-40fd-9fe6-3ed97545362f"));

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("5f939aa9-937f-4cca-9eff-36f13c32e290"));

            migrationBuilder.AlterColumn<string>(
                name: "LastName",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "FirstName",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Users",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UploadedAt",
                table: "CRIPhotos",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "CRIForms",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "CRIForms",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuditLogs",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId1",
                table: "AuditLogs",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AuthAttempts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    CodeHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsUsed = table.Column<bool>(type: "bit", nullable: false),
                    AttemptCount = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuthAttempts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MagicLinks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Token = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsUsed = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MagicLinks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Token = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    TokenType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsRevoked = table.Column<bool>(type: "bit", nullable: false),
                    RevokedReason = table.Column<string>(type: "nvarchar(max)", nullable: true)
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

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "Email", "FirstName", "IsActive", "LastLoginAt", "LastName", "PasswordHash", "PhoneNumber", "Role" },
                values: new object[,]
                {
                    { new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"), new DateTime(2026, 2, 2, 13, 28, 58, 137, DateTimeKind.Utc).AddTicks(3367), "admin@novadis.local", "Admin", true, null, "Système", "", null, "Admin" },
                    { new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"), new DateTime(2026, 2, 2, 13, 28, 58, 137, DateTimeKind.Utc).AddTicks(3373), "technicien@novadis.local", "Jean", true, null, "Dupont", "", "0612345678", "Technician" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_CreatedAt",
                table: "CRIForms",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_UserId",
                table: "CRIForms",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_UserId1",
                table: "AuditLogs",
                column: "UserId1");

            migrationBuilder.CreateIndex(
                name: "IX_AuthAttempts_Email",
                table: "AuthAttempts",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_AuthAttempts_Email_CreatedAt",
                table: "AuthAttempts",
                columns: new[] { "Email", "CreatedAt" });

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
                name: "IX_UserTokens_Token",
                table: "UserTokens",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_UserId",
                table: "UserTokens",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId1",
                table: "AuditLogs",
                column: "UserId1",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_CRIForms_Users_UserId",
                table: "CRIForms",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId1",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_CRIForms_Users_UserId",
                table: "CRIForms");

            migrationBuilder.DropTable(
                name: "AuthAttempts");

            migrationBuilder.DropTable(
                name: "MagicLinks");

            migrationBuilder.DropTable(
                name: "UserTokens");

            migrationBuilder.DropIndex(
                name: "IX_CRIForms_CreatedAt",
                table: "CRIForms");

            migrationBuilder.DropIndex(
                name: "IX_CRIForms_UserId",
                table: "CRIForms");

            migrationBuilder.DropIndex(
                name: "IX_AuditLogs_UserId1",
                table: "AuditLogs");

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"));

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"));

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "CRIForms");

            migrationBuilder.DropColumn(
                name: "UserId1",
                table: "AuditLogs");

            migrationBuilder.AlterColumn<string>(
                name: "LastName",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "FirstName",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Users",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UploadedAt",
                table: "CRIPhotos",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "CRIForms",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "AuditLogs",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "CreatedAt", "Email", "FirstName", "IsActive", "LastLoginAt", "LastName", "PasswordHash", "PhoneNumber", "Role" },
                values: new object[,]
                {
                    { new Guid("23819a5c-870e-40fd-9fe6-3ed97545362f"), new DateTime(2026, 2, 2, 12, 36, 37, 235, DateTimeKind.Utc).AddTicks(3245), "technicien@novadis.local", "Jean", true, null, "Dupont", "$2a$11$MpsmRyOJXTLC/QbbuGMKMOzN0LREJaZxwdvH.Juha867PwslRHyQ6", "0612345678", "Technician" },
                    { new Guid("5f939aa9-937f-4cca-9eff-36f13c32e290"), new DateTime(2026, 2, 2, 12, 36, 37, 84, DateTimeKind.Utc).AddTicks(9184), "admin@novadis.local", "Admin", true, null, "Novadis", "$2a$11$B..3YbaRHK1WSqsDDAOBXuCXv0XO8.zrWeDg2OR5k.kW1kmMo3ksa", null, "Admin" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_InterventionDate",
                table: "CRIForms",
                column: "InterventionDate");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Status",
                table: "CRIForms",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_Action",
                table: "AuditLogs",
                column: "Action");
        }
    }
}
