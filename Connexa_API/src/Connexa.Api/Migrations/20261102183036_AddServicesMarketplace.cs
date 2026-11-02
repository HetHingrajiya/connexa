using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddServicesMarketplace : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "BusinessServices",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    ServiceCategory = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IndustryId = table.Column<int>(type: "int", nullable: true),
                    BusinessGroupId = table.Column<int>(type: "int", nullable: true),
                    SubGroupId = table.Column<int>(type: "int", nullable: true),
                    CategoryId = table.Column<int>(type: "int", nullable: true),
                    ServiceType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "On-Site"),
                    PricingModel = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "Quote-Based"),
                    StartingPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    PriceUnit = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    TurnaroundTime = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    CoverageArea = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Location = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    TagsJson = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ImagesJson = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    Certifications = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    YearsOfExperience = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    ViewCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessServices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessServices_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_BusinessServices_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ServiceInquiries",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    InquiryNumber = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    ServiceId = table.Column<int>(type: "int", nullable: false),
                    SenderMemberId = table.Column<int>(type: "int", nullable: false),
                    RecipientMemberId = table.Column<int>(type: "int", nullable: false),
                    Subject = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    RequirementDescription = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    ScopeOfWork = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    Location = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    PreferredStartDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EstimatedBudget = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    Urgency = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "Normal"),
                    Status = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    ResponseMessage = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    RespondedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceInquiries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceInquiries_BusinessServices",
                        column: x => x.ServiceId,
                        principalTable: "BusinessServices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServiceInquiries_RecipientMember",
                        column: x => x.RecipientMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServiceInquiries_SenderMember",
                        column: x => x.SenderMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ServiceInquiryStatusHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ServiceInquiryId = table.Column<int>(type: "int", nullable: false),
                    PreviousStatus = table.Column<int>(type: "int", nullable: true),
                    NewStatus = table.Column<int>(type: "int", nullable: false),
                    ChangedByMemberId = table.Column<int>(type: "int", nullable: false),
                    ChangedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    Remarks = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceInquiryStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceInquiryStatusHistories_ChangedByMember",
                        column: x => x.ChangedByMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServiceInquiryStatusHistories_Inquiries",
                        column: x => x.ServiceInquiryId,
                        principalTable: "ServiceInquiries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BusinessServices_Category",
                table: "BusinessServices",
                column: "ServiceCategory");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessServices_IndustryId",
                table: "BusinessServices",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessServices_IsActive",
                table: "BusinessServices",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessServices_Location",
                table: "BusinessServices",
                column: "Location");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessServices_MemberId",
                table: "BusinessServices",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiries_InquiryNumber",
                table: "ServiceInquiries",
                column: "InquiryNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiries_RecipientMemberId",
                table: "ServiceInquiries",
                column: "RecipientMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiries_SenderMemberId",
                table: "ServiceInquiries",
                column: "SenderMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiries_ServiceId",
                table: "ServiceInquiries",
                column: "ServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiries_Status",
                table: "ServiceInquiries",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiryStatusHistories_ChangedByMemberId",
                table: "ServiceInquiryStatusHistories",
                column: "ChangedByMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceInquiryStatusHistories_InquiryId",
                table: "ServiceInquiryStatusHistories",
                column: "ServiceInquiryId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ServiceInquiryStatusHistories");

            migrationBuilder.DropTable(
                name: "ServiceInquiries");

            migrationBuilder.DropTable(
                name: "BusinessServices");
        }
    }
}
