using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPlainCodeForDev : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PlainCode",
                table: "AuthAttempts",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 14, 2, 26, 68, DateTimeKind.Utc).AddTicks(183));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 14, 2, 26, 68, DateTimeKind.Utc).AddTicks(190));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PlainCode",
                table: "AuthAttempts");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 13, 44, 46, 373, DateTimeKind.Utc).AddTicks(1329));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 13, 44, 46, 373, DateTimeKind.Utc).AddTicks(1339));
        }
    }
}
