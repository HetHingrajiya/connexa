using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Connexa.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddProductIndustry : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("IF COL_LENGTH('Products', 'IndustryId') IS NULL ALTER TABLE [Products] ADD [IndustryId] int NULL;");
            migrationBuilder.Sql("IF COL_LENGTH('ProductInquiries', 'ResponseMessage') IS NULL ALTER TABLE [ProductInquiries] ADD [ResponseMessage] nvarchar(2000) NULL;");
            migrationBuilder.Sql(@"IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_IndustryId' AND object_id = OBJECT_ID('Products'))
BEGIN
    CREATE INDEX [IX_Products_IndustryId] ON [Products] ([IndustryId]);
END");
            migrationBuilder.Sql(@"IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Products_Industries')
BEGIN
    ALTER TABLE [Products] ADD CONSTRAINT [FK_Products_Industries] FOREIGN KEY ([IndustryId]) REFERENCES [Industries] ([Id]);
END");

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Products_Industries",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_Products_IndustryId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "IndustryId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "ResponseMessage",
                table: "ProductInquiries");
        }
    }
}
