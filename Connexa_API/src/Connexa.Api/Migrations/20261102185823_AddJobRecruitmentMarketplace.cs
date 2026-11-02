using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddJobRecruitmentMarketplace : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "JobOpenings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    Department = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    IndustryId = table.Column<int>(type: "int", nullable: true),
                    BusinessGroupId = table.Column<int>(type: "int", nullable: true),
                    SubGroupId = table.Column<int>(type: "int", nullable: true),
                    CategoryId = table.Column<int>(type: "int", nullable: true),
                    JobType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "Full-time"),
                    WorkplaceType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "On-site"),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    MinExperienceYears = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    MaxExperienceYears = table.Column<int>(type: "int", nullable: true),
                    MinSalary = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    MaxSalary = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    SalaryPeriod = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "Per Month"),
                    RequiredSkillsJson = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    EducationRequirements = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    OpeningsCount = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    Status = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    ApplicationDeadlineUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ViewCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    ApplicationsCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobOpenings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobOpenings_BusinessGroups",
                        column: x => x.BusinessGroupId,
                        principalTable: "BusinessGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobOpenings_Categories",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobOpenings_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobOpenings_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobOpenings_SubGroups",
                        column: x => x.SubGroupId,
                        principalTable: "SubGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobApplications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ApplicationNumber = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    JobOpeningId = table.Column<int>(type: "int", nullable: false),
                    ApplicantMemberId = table.Column<int>(type: "int", nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CurrentCompany = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    CurrentDesignation = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    YearsOfExperience = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    ExpectedSalary = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    NoticePeriodDays = table.Column<int>(type: "int", nullable: true),
                    CoverLetter = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    ResumeUrl = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ResumeFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    EmployerNotes = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    ReviewedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobApplications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobApplications_ApplicantMembers",
                        column: x => x.ApplicantMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobApplications_JobOpenings",
                        column: x => x.JobOpeningId,
                        principalTable: "JobOpenings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobApplicationAttachments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    JobApplicationId = table.Column<int>(type: "int", nullable: false),
                    FileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    FilePath = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    UploadedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobApplicationAttachments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobApplicationAttachments_Applications",
                        column: x => x.JobApplicationId,
                        principalTable: "JobApplications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "JobApplicationStatusHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    JobApplicationId = table.Column<int>(type: "int", nullable: false),
                    PreviousStatus = table.Column<int>(type: "int", nullable: true),
                    NewStatus = table.Column<int>(type: "int", nullable: false),
                    ChangedByMemberId = table.Column<int>(type: "int", nullable: false),
                    Remarks = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ChangedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobApplicationStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobApplicationStatusHistories_Applications",
                        column: x => x.JobApplicationId,
                        principalTable: "JobApplications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_JobApplicationStatusHistories_ChangedByMember",
                        column: x => x.ChangedByMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_JobApplicationAttachments_ApplicationId",
                table: "JobApplicationAttachments",
                column: "JobApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_JobApplications_ApplicantMemberId",
                table: "JobApplications",
                column: "ApplicantMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobApplications_ApplicationNumber",
                table: "JobApplications",
                column: "ApplicationNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobApplications_Job_Applicant",
                table: "JobApplications",
                columns: new[] { "JobOpeningId", "ApplicantMemberId" });

            migrationBuilder.CreateIndex(
                name: "IX_JobApplications_JobOpeningId",
                table: "JobApplications",
                column: "JobOpeningId");

            migrationBuilder.CreateIndex(
                name: "IX_JobApplications_Status",
                table: "JobApplications",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_JobApplicationStatusHistories_ApplicationId",
                table: "JobApplicationStatusHistories",
                column: "JobApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_JobApplicationStatusHistories_ChangedByMemberId",
                table: "JobApplicationStatusHistories",
                column: "ChangedByMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_BusinessGroupId",
                table: "JobOpenings",
                column: "BusinessGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_CategoryId",
                table: "JobOpenings",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_City",
                table: "JobOpenings",
                column: "City");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_CreatedAtUtc",
                table: "JobOpenings",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_IndustryId",
                table: "JobOpenings",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_MemberId",
                table: "JobOpenings",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_Status",
                table: "JobOpenings",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_JobOpenings_SubGroupId",
                table: "JobOpenings",
                column: "SubGroupId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "JobApplicationAttachments");

            migrationBuilder.DropTable(
                name: "JobApplicationStatusHistories");

            migrationBuilder.DropTable(
                name: "JobApplications");

            migrationBuilder.DropTable(
                name: "JobOpenings");
        }
    }
}
