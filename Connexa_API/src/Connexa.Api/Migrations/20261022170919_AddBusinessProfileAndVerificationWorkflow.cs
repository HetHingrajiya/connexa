using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessProfileAndVerificationWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "BusinessProfiles",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BusinessImagesJson",
                table: "BusinessProfiles",
                type: "nvarchar(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "BusinessProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LogoUrl",
                table: "BusinessProfiles",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Pincode",
                table: "BusinessProfiles",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "State",
                table: "BusinessProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "VerificationStatus",
                table: "BusinessProfiles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "WebsiteUrl",
                table: "BusinessProfiles",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BusinessVerificationRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BusinessProfileId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    BusinessRegistrationNumber = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    RegisteredAddress = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Pincode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    SubmittedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    ReviewedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReviewedByMemberId = table.Column<int>(type: "int", nullable: true),
                    RejectionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessVerificationRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessVerificationRequests_BusinessProfiles",
                        column: x => x.BusinessProfileId,
                        principalTable: "BusinessProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BusinessVerificationRequests_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessVerificationRequests_Reviewer",
                        column: x => x.ReviewedByMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "BusinessVerificationDocuments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VerificationRequestId = table.Column<int>(type: "int", nullable: false),
                    DocumentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    OriginalFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    StoredFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    FileExtension = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    UploadedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessVerificationDocuments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessVerificationDocuments_VerificationRequests",
                        column: x => x.VerificationRequestId,
                        principalTable: "BusinessVerificationRequests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_VerificationStatus",
                table: "BusinessProfiles",
                column: "VerificationStatus");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessVerificationDocuments_VerificationRequestId",
                table: "BusinessVerificationDocuments",
                column: "VerificationRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessVerificationRequests_BusinessProfileId",
                table: "BusinessVerificationRequests",
                column: "BusinessProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessVerificationRequests_MemberId",
                table: "BusinessVerificationRequests",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessVerificationRequests_ReviewedByMemberId",
                table: "BusinessVerificationRequests",
                column: "ReviewedByMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessVerificationRequests_Status",
                table: "BusinessVerificationRequests",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BusinessVerificationDocuments");

            migrationBuilder.DropTable(
                name: "BusinessVerificationRequests");

            migrationBuilder.DropIndex(
                name: "IX_BusinessProfiles_VerificationStatus",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "Address",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "BusinessImagesJson",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "City",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "LogoUrl",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "Pincode",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "State",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "VerificationStatus",
                table: "BusinessProfiles");

            migrationBuilder.DropColumn(
                name: "WebsiteUrl",
                table: "BusinessProfiles");
        }
    }
}
