using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddEmailToOtpChallenges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "OtpChallenges",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "OtpChallenges",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_Email",
                table: "OtpChallenges",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_Email_Status",
                table: "OtpChallenges",
                columns: new[] { "Email", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_OtpChallenges_Email",
                table: "OtpChallenges");

            migrationBuilder.DropIndex(
                name: "IX_OtpChallenges_Email_Status",
                table: "OtpChallenges");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "OtpChallenges");

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "OtpChallenges",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30,
                oldNullable: true);
        }
    }
}
