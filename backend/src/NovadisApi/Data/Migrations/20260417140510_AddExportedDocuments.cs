using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddExportedDocuments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ExportedDocuments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CriId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Filename = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    FileType = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    ExportType = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    StoragePath = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SharedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PeriodStart = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PeriodEnd = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Metadata = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true)
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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExportedDocuments");
        }
    }
}
