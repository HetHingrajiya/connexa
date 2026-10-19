using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMemberAndProfileEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Members",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FullName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    CountryCode = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false, defaultValue: "+91"),
                    PhoneNumber = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    PrimaryProfileType = table.Column<int>(type: "int", nullable: false),
                    VerifiedMethod = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    VerifiedDestination = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Role = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false, defaultValue: "Member"),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Members", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "BusinessProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    CompanyName = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: false),
                    BusinessCapabilities = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    BusinessDescription = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    IndustryId = table.Column<int>(type: "int", nullable: false),
                    BusinessGroupId = table.Column<int>(type: "int", nullable: false),
                    SubGroupId = table.Column<int>(type: "int", nullable: false),
                    CategoryId = table.Column<int>(type: "int", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessProfiles_BusinessGroups",
                        column: x => x.BusinessGroupId,
                        principalTable: "BusinessGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessProfiles_Categories",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessProfiles_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessProfiles_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BusinessProfiles_SubGroups",
                        column: x => x.SubGroupId,
                        principalTable: "SubGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ContractorProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    WorkName = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: false),
                    WorkCapabilities = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ProcessesSupported = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    WorkCoverage = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    IndustryId = table.Column<int>(type: "int", nullable: false),
                    BusinessGroupId = table.Column<int>(type: "int", nullable: false),
                    SubGroupId = table.Column<int>(type: "int", nullable: false),
                    CategoryId = table.Column<int>(type: "int", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ContractorProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ContractorProfiles_BusinessGroups",
                        column: x => x.BusinessGroupId,
                        principalTable: "BusinessGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContractorProfiles_Categories",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContractorProfiles_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ContractorProfiles_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ContractorProfiles_SubGroups",
                        column: x => x.SubGroupId,
                        principalTable: "SubGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "EmployeeProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    JobTitle = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Skills = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    Experience = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    PreferredJobType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmployeeProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EmployeeProfiles_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ServiceEngineerProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Specialization = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    SupportedEquipment = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    YearsOfExperience = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ServiceCoverage = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceEngineerProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServiceEngineerProfiles_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TraderProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    TradingName = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: false),
                    Capabilities = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ProductsSupplied = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    ServiceCoverage = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderProfiles_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_BusinessGroupId",
                table: "BusinessProfiles",
                column: "BusinessGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_CategoryId",
                table: "BusinessProfiles",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_IndustryId",
                table: "BusinessProfiles",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_MemberId",
                table: "BusinessProfiles",
                column: "MemberId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BusinessProfiles_SubGroupId",
                table: "BusinessProfiles",
                column: "SubGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_ContractorProfiles_BusinessGroupId",
                table: "ContractorProfiles",
                column: "BusinessGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_ContractorProfiles_CategoryId",
                table: "ContractorProfiles",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_ContractorProfiles_IndustryId",
                table: "ContractorProfiles",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_ContractorProfiles_MemberId",
                table: "ContractorProfiles",
                column: "MemberId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ContractorProfiles_SubGroupId",
                table: "ContractorProfiles",
                column: "SubGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_EmployeeProfiles_MemberId",
                table: "EmployeeProfiles",
                column: "MemberId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Members_Email",
                table: "Members",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Members_PhoneNumber",
                table: "Members",
                column: "PhoneNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ServiceEngineerProfiles_MemberId",
                table: "ServiceEngineerProfiles",
                column: "MemberId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TraderProfiles_MemberId",
                table: "TraderProfiles",
                column: "MemberId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BusinessProfiles");

            migrationBuilder.DropTable(
                name: "ContractorProfiles");

            migrationBuilder.DropTable(
                name: "EmployeeProfiles");

            migrationBuilder.DropTable(
                name: "ServiceEngineerProfiles");

            migrationBuilder.DropTable(
                name: "TraderProfiles");

            migrationBuilder.DropTable(
                name: "Members");
        }
    }
}
