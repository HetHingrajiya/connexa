using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessPostsFeed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "BusinessPosts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    IndustryId = table.Column<int>(type: "int", nullable: true),
                    LikeCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CommentCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    IsEdited = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessPosts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessPosts_Industries",
                        column: x => x.IndustryId,
                        principalTable: "Industries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_BusinessPosts_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "BusinessPostAttachments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PostId = table.Column<int>(type: "int", nullable: false),
                    MediaUrl = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    MediaType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessPostAttachments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessPostAttachments_Posts",
                        column: x => x.PostId,
                        principalTable: "BusinessPosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BusinessPostComments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PostId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    IsEdited = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessPostComments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessPostComments_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessPostComments_Posts",
                        column: x => x.PostId,
                        principalTable: "BusinessPosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BusinessPostLikes",
                columns: table => new
                {
                    PostId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    LikedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessPostLikes", x => new { x.PostId, x.MemberId });
                    table.ForeignKey(
                        name: "FK_BusinessPostLikes_Members",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessPostLikes_Posts",
                        column: x => x.PostId,
                        principalTable: "BusinessPosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BusinessPostReports",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReporterMemberId = table.Column<int>(type: "int", nullable: false),
                    PostId = table.Column<int>(type: "int", nullable: true),
                    CommentId = table.Column<int>(type: "int", nullable: true),
                    Reason = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Details = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    ReviewedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BusinessPostReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BusinessPostReports_Comments",
                        column: x => x.CommentId,
                        principalTable: "BusinessPostComments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessPostReports_Members",
                        column: x => x.ReporterMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BusinessPostReports_Posts",
                        column: x => x.PostId,
                        principalTable: "BusinessPosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostAttachments_PostId",
                table: "BusinessPostAttachments",
                column: "PostId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostComments_CreatedAtUtc",
                table: "BusinessPostComments",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostComments_MemberId",
                table: "BusinessPostComments",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostComments_PostId",
                table: "BusinessPostComments",
                column: "PostId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostLikes_MemberId",
                table: "BusinessPostLikes",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostLikes_PostId",
                table: "BusinessPostLikes",
                column: "PostId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostReports_CommentId",
                table: "BusinessPostReports",
                column: "CommentId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostReports_PostId",
                table: "BusinessPostReports",
                column: "PostId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostReports_ReporterMemberId",
                table: "BusinessPostReports",
                column: "ReporterMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPostReports_Status",
                table: "BusinessPostReports",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPosts_CreatedAtUtc",
                table: "BusinessPosts",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPosts_IndustryId",
                table: "BusinessPosts",
                column: "IndustryId");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPosts_IsDeleted",
                table: "BusinessPosts",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_BusinessPosts_MemberId",
                table: "BusinessPosts",
                column: "MemberId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BusinessPostAttachments");

            migrationBuilder.DropTable(
                name: "BusinessPostLikes");

            migrationBuilder.DropTable(
                name: "BusinessPostReports");

            migrationBuilder.DropTable(
                name: "BusinessPostComments");

            migrationBuilder.DropTable(
                name: "BusinessPosts");
        }
    }
}
