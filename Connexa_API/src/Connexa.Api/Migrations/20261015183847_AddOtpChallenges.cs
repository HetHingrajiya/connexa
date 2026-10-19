using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddOtpChallenges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "OtpChallenges",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PhoneNumber = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    OtpHashingSalt = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    OtpHash = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Purpose = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RegistrationFlowId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    VerifiedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    AttemptCount = table.Column<int>(type: "int", nullable: false),
                    MaxAttempts = table.Column<int>(type: "int", nullable: false),
                    ResendCount = table.Column<int>(type: "int", nullable: false),
                    LastResentAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    VerificationGrantToken = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    VerificationGrantExpiresAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RequestIpAddress = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    ProviderMessageId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OtpChallenges", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_Phone_Status",
                table: "OtpChallenges",
                columns: new[] { "PhoneNumber", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_PhoneNumber",
                table: "OtpChallenges",
                column: "PhoneNumber");

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_RegistrationFlowId",
                table: "OtpChallenges",
                column: "RegistrationFlowId");

            migrationBuilder.CreateIndex(
                name: "IX_OtpChallenges_VerificationGrantToken",
                table: "OtpChallenges",
                column: "VerificationGrantToken");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OtpChallenges");
        }
    }
}
