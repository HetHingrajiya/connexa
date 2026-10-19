using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddDirectOtpCode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "OtpCode",
                table: "OtpChallenges",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OtpCode",
                table: "OtpChallenges");
        }
    }
}
