using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSitesTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Sites",
                columns: table => new
                {
                    Numero = table.Column<int>(type: "int", nullable: false),
                    NomDuSite = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Adresse = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Ville = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    CodePostal = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Pays = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    ResponsableDorigine = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    DateDeCreation = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sites", x => x.Numero);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Sites_NomDuSite",
                table: "Sites",
                column: "NomDuSite");

            migrationBuilder.CreateIndex(
                name: "IX_Sites_Ville",
                table: "Sites",
                column: "Ville");

            migrationBuilder.CreateIndex(
                name: "IX_Sites_CodePostal",
                table: "Sites",
                column: "CodePostal");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "Sites");
        }
    }
}
