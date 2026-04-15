using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class NormalizeClientAndSiteRelations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ClientID",
                table: "CRIForms",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SiteID",
                table: "CRIForms",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ClientsNormalises",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RaisonSociale = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Contact = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Telephone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Adresse = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CodePostal = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    Ville = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Pays = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Actif = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClientsNormalises", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ClientID",
                table: "CRIForms",
                column: "ClientID");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_SiteID",
                table: "CRIForms",
                column: "SiteID");

            migrationBuilder.CreateIndex(
                name: "IX_ClientsNormalises_RaisonSociale",
                table: "ClientsNormalises",
                column: "RaisonSociale");

            migrationBuilder.CreateIndex(
                name: "IX_ClientsNormalises_Ville",
                table: "ClientsNormalises",
                column: "Ville");

            migrationBuilder.AddForeignKey(
                name: "FK_CRIForms_ClientsNormalises_ClientID",
                table: "CRIForms",
                column: "ClientID",
                principalTable: "ClientsNormalises",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_CRIForms_Sites_SiteID",
                table: "CRIForms",
                column: "SiteID",
                principalTable: "Sites",
                principalColumn: "Numero",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CRIForms_ClientsNormalises_ClientID",
                table: "CRIForms");

            migrationBuilder.DropForeignKey(
                name: "FK_CRIForms_Sites_SiteID",
                table: "CRIForms");

            migrationBuilder.DropTable(
                name: "ClientsNormalises");

            migrationBuilder.DropIndex(
                name: "IX_CRIForms_ClientID",
                table: "CRIForms");

            migrationBuilder.DropIndex(
                name: "IX_CRIForms_SiteID",
                table: "CRIForms");

            migrationBuilder.DropColumn(
                name: "ClientID",
                table: "CRIForms");

            migrationBuilder.DropColumn(
                name: "SiteID",
                table: "CRIForms");
        }
    }
}
