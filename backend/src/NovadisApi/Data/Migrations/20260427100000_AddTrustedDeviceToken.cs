using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NovadisApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTrustedDeviceToken : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TrustedDeviceToken",
                table: "UserTokens",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTokens_TrustedDeviceToken",
                table: "UserTokens",
                column: "TrustedDeviceToken",
                unique: true,
                filter: "[TrustedDeviceToken] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserTokens_TrustedDeviceToken",
                table: "UserTokens");

            migrationBuilder.DropColumn(
                name: "TrustedDeviceToken",
                table: "UserTokens");
        }
    }
}
