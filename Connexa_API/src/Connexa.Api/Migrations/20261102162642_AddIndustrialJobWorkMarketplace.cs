using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddIndustrialJobWorkMarketplace : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "JobWorkRequirements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequirementNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    OwnerMemberId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(3000)", maxLength: 3000, nullable: false),
                    IndustryId = table.Column<int>(type: "int", nullable: false),
                    BusinessGroupId = table.Column<int>(type: "int", nullable: true),
                    SubGroupId = table.Column<int>(type: "int", nullable: true),
                    CategoryId = table.Column<int>(type: "int", nullable: true),
                    JobWorkProcess = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    MachineType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    MachineCategory = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    RequiredMachineCapacity = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    NumberOfAxes = table.Column<int>(type: "int", nullable: true),
                    TechnicalSpecifications = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    RequiredTolerance = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    MaterialType = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    MaterialResponsibility = table.Column<int>(type: "int", nullable: false),
                    Quantity = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    UnitOfMeasurement = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    TargetBudget = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    ExpectedCompletionDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Location = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    DeliveryTerms = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobWorkRequirements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobWorkRequirements_BusinessGroups",
                        column: x => x.BusinessGroupId,
                        principalTable: "BusinessGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkRequirements_Categories",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkRequirements_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkRequirements_OwnerMember",
                        column: x => x.OwnerMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkRequirements_SubGroups",
                        column: x => x.SubGroupId,
                        principalTable: "SubGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobWorkQuotations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    QuotationNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    JobWorkRequirementId = table.Column<int>(type: "int", nullable: false),
                    ContractorMemberId = table.Column<int>(type: "int", nullable: false),
                    OfferedUnitPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Quantity = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Subtotal = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TaxRatePercent = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false, defaultValue: 18.00m),
                    TaxAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    OtherCharges = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false, defaultValue: 0.00m),
                    TotalAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    LeadTimeDays = table.Column<int>(type: "int", nullable: false),
                    MachineProposed = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    TechnicalRemarks = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    TermsAndConditions = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    RevisionNumber = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    RejectionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    RevisionNotes = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobWorkQuotations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobWorkQuotations_ContractorMember",
                        column: x => x.ContractorMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkQuotations_JobWorkRequirements",
                        column: x => x.JobWorkRequirementId,
                        principalTable: "JobWorkRequirements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobWorkAttachments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    JobWorkRequirementId = table.Column<int>(type: "int", nullable: true),
                    JobWorkQuotationId = table.Column<int>(type: "int", nullable: true),
                    UploadedByMemberId = table.Column<int>(type: "int", nullable: false),
                    OriginalFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    StoredFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    FileExtension = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    UploadedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobWorkAttachments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobWorkAttachments_JobWorkQuotations",
                        column: x => x.JobWorkQuotationId,
                        principalTable: "JobWorkQuotations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkAttachments_JobWorkRequirements",
                        column: x => x.JobWorkRequirementId,
                        principalTable: "JobWorkRequirements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkAttachments_UploadedByMember",
                        column: x => x.UploadedByMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobWorkOrders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OrderNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    JobWorkRequirementId = table.Column<int>(type: "int", nullable: false),
                    JobWorkQuotationId = table.Column<int>(type: "int", nullable: false),
                    BuyerMemberId = table.Column<int>(type: "int", nullable: false),
                    ContractorMemberId = table.Column<int>(type: "int", nullable: false),
                    JobTitle = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Process = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Quantity = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    UnitOfMeasurement = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    AgreedUnitPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Subtotal = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TaxAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    OtherCharges = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalAmount = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    LeadTimeDays = table.Column<int>(type: "int", nullable: false),
                    DeliveryLocation = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    ConfirmedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ProcessingStartedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CompletedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CancellationReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    RejectionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobWorkOrders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobWorkOrders_BuyerMember",
                        column: x => x.BuyerMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkOrders_ContractorMember",
                        column: x => x.ContractorMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkOrders_JobWorkQuotations",
                        column: x => x.JobWorkQuotationId,
                        principalTable: "JobWorkQuotations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkOrders_JobWorkRequirements",
                        column: x => x.JobWorkRequirementId,
                        principalTable: "JobWorkRequirements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "JobWorkOrderStatusHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    JobWorkOrderId = table.Column<int>(type: "int", nullable: false),
                    PreviousStatus = table.Column<int>(type: "int", nullable: true),
                    NewStatus = table.Column<int>(type: "int", nullable: false),
                    ChangedByMemberId = table.Column<int>(type: "int", nullable: false),
                    ChangedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    Remarks = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobWorkOrderStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_JobWorkOrderStatusHistories_ChangedByMember",
                        column: x => x.ChangedByMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_JobWorkOrderStatusHistories_JobWorkOrders",
                        column: x => x.JobWorkOrderId,
                        principalTable: "JobWorkOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkAttachments_QuotationId",
                table: "JobWorkAttachments",
                column: "JobWorkQuotationId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkAttachments_RequirementId",
                table: "JobWorkAttachments",
                column: "JobWorkRequirementId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkAttachments_UploadedByMemberId",
                table: "JobWorkAttachments",
                column: "UploadedByMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_BuyerMemberId",
                table: "JobWorkOrders",
                column: "BuyerMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_ContractorMemberId",
                table: "JobWorkOrders",
                column: "ContractorMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_OrderNumber",
                table: "JobWorkOrders",
                column: "OrderNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_QuotationId",
                table: "JobWorkOrders",
                column: "JobWorkQuotationId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_RequirementId",
                table: "JobWorkOrders",
                column: "JobWorkRequirementId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrders_Status",
                table: "JobWorkOrders",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrderStatusHistories_ChangedByMemberId",
                table: "JobWorkOrderStatusHistories",
                column: "ChangedByMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkOrderStatusHistories_OrderId",
                table: "JobWorkOrderStatusHistories",
                column: "JobWorkOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkQuotations_ContractorMemberId",
                table: "JobWorkQuotations",
                column: "ContractorMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkQuotations_QuotationNumber",
                table: "JobWorkQuotations",
                column: "QuotationNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkQuotations_RequirementId",
                table: "JobWorkQuotations",
                column: "JobWorkRequirementId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkQuotations_Status",
                table: "JobWorkQuotations",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_BusinessGroupId",
                table: "JobWorkRequirements",
                column: "BusinessGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_CategoryId",
                table: "JobWorkRequirements",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_IndustryId",
                table: "JobWorkRequirements",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_JobWorkProcess",
                table: "JobWorkRequirements",
                column: "JobWorkProcess");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_OwnerMemberId",
                table: "JobWorkRequirements",
                column: "OwnerMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_RequirementNumber",
                table: "JobWorkRequirements",
                column: "RequirementNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_Status",
                table: "JobWorkRequirements",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_JobWorkRequirements_SubGroupId",
                table: "JobWorkRequirements",
                column: "SubGroupId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "JobWorkAttachments");

            migrationBuilder.DropTable(
                name: "JobWorkOrderStatusHistories");

            migrationBuilder.DropTable(
                name: "JobWorkOrders");

            migrationBuilder.DropTable(
                name: "JobWorkQuotations");

            migrationBuilder.DropTable(
                name: "JobWorkRequirements");
        }
    }
}
