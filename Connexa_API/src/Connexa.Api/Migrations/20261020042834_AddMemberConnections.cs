using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMemberConnections : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MemberConnections",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequesterMemberId = table.Column<int>(type: "int", nullable: false),
                    RecipientMemberId = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    RespondedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MemberConnections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MemberConnections_RecipientMember",
                        column: x => x.RecipientMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MemberConnections_RequesterMember",
                        column: x => x.RequesterMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MemberConnections_RecipientMemberId",
                table: "MemberConnections",
                column: "RecipientMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_MemberConnections_Requester_Recipient",
                table: "MemberConnections",
                columns: new[] { "RequesterMemberId", "RecipientMemberId" });

            migrationBuilder.CreateIndex(
                name: "IX_MemberConnections_RequesterMemberId",
                table: "MemberConnections",
                column: "RequesterMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_MemberConnections_Status",
                table: "MemberConnections",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MemberConnections");
        }
    }
}

