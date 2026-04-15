using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class ExtractStatsColumnsFromJson : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ── Nouvelles colonnes statistiques sur CRIForms ──

            migrationBuilder.AddColumn<TimeSpan>(
                name: "HeureDebut",
                table: "CRIForms",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "HeureFin",
                table: "CRIForms",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DureeMinutes",
                table: "CRIForms",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Ville",
                table: "CRIForms",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CodePostal",
                table: "CRIForms",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Pays",
                table: "CRIForms",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ClientContact",
                table: "CRIForms",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TicketNumber",
                table: "CRIForms",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Priority",
                table: "CRIForms",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResolutionStatus",
                table: "CRIForms",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "AdditionalInterventionRequired",
                table: "CRIForms",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProjectName",
                table: "CRIForms",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProjectNumber",
                table: "CRIForms",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProjectPhase",
                table: "CRIForms",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProjectStatus",
                table: "CRIForms",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true);

            // ── Index pour requêtes statistiques ──

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_InterventionDate",
                table: "CRIForms",
                column: "InterventionDate");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Status",
                table: "CRIForms",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Priority",
                table: "CRIForms",
                column: "Priority");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ResolutionStatus",
                table: "CRIForms",
                column: "ResolutionStatus");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_Ville",
                table: "CRIForms",
                column: "Ville");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ProjectStatus",
                table: "CRIForms",
                column: "ProjectStatus");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_TicketNumber",
                table: "CRIForms",
                column: "TicketNumber");

            migrationBuilder.CreateIndex(
                name: "IX_CRIForms_ProjectNumber",
                table: "CRIForms",
                column: "ProjectNumber");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(name: "IX_CRIForms_InterventionDate", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_Status", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_Priority", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_ResolutionStatus", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_Ville", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_ProjectStatus", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_TicketNumber", table: "CRIForms");
            migrationBuilder.DropIndex(name: "IX_CRIForms_ProjectNumber", table: "CRIForms");

            migrationBuilder.DropColumn(name: "HeureDebut", table: "CRIForms");
            migrationBuilder.DropColumn(name: "HeureFin", table: "CRIForms");
            migrationBuilder.DropColumn(name: "DureeMinutes", table: "CRIForms");
            migrationBuilder.DropColumn(name: "Ville", table: "CRIForms");
            migrationBuilder.DropColumn(name: "CodePostal", table: "CRIForms");
            migrationBuilder.DropColumn(name: "Pays", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ClientContact", table: "CRIForms");
            migrationBuilder.DropColumn(name: "TicketNumber", table: "CRIForms");
            migrationBuilder.DropColumn(name: "Priority", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ResolutionStatus", table: "CRIForms");
            migrationBuilder.DropColumn(name: "AdditionalInterventionRequired", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ProjectName", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ProjectNumber", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ProjectPhase", table: "CRIForms");
            migrationBuilder.DropColumn(name: "ProjectStatus", table: "CRIForms");
        }
    }
}
