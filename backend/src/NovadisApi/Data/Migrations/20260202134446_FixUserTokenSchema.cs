using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class FixUserTokenSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Token",
                table: "UserTokens",
                newName: "RefreshToken");

            migrationBuilder.RenameIndex(
                name: "IX_UserTokens_Token",
                table: "UserTokens",
                newName: "IX_UserTokens_RefreshToken");

            migrationBuilder.RenameColumn(
                name: "AttemptCount",
                table: "AuthAttempts",
                newName: "FailedAttempts");

            migrationBuilder.AddColumn<string>(
                name: "DeviceInfo",
                table: "UserTokens",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "UserTokens",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "AuthAttempts",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeviceInfo",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "AuthAttempts");

            migrationBuilder.RenameColumn(
                name: "RefreshToken",
                table: "UserTokens",
                newName: "Token");

            migrationBuilder.RenameIndex(
                name: "IX_UserTokens_RefreshToken",
                table: "UserTokens",
                newName: "IX_UserTokens_Token");

            migrationBuilder.RenameColumn(
                name: "FailedAttempts",
                table: "AuthAttempts",
                newName: "AttemptCount");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 13, 28, 58, 137, DateTimeKind.Utc).AddTicks(3367));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: new Guid("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"),
                column: "CreatedAt",
                value: new DateTime(2026, 2, 2, 13, 28, 58, 137, DateTimeKind.Utc).AddTicks(3373));
        }
    }
}
