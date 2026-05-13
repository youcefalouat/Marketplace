using MarketplaceApi.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketplaceApi.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260511132132_AddArabicCategoryName")]
    public partial class AddArabicCategoryName : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
IF COL_LENGTH(N'dbo.Categories', N'ArName') IS NULL
BEGIN
    ALTER TABLE [dbo].[Categories]
    ADD [ArName] nvarchar(255) NOT NULL
        CONSTRAINT [DF_Categories_ArName] DEFAULT N'';
END");

            migrationBuilder.Sql("UPDATE Categories SET ArName = N'الأجهزة المنزلية' WHERE Slug = N'electromenager'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'أثاث' WHERE Slug = N'meubles'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'مفروشات' WHERE Slug = N'literie'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'ديكور' WHERE Slug = N'decoration'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'أجهزة منزلية كبيرة' WHERE Slug = N'gros-electromenager'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'أجهزة منزلية صغيرة' WHERE Slug = N'petit-electromenager'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'غرفة المعيشة' WHERE Slug = N'salon'");
            migrationBuilder.Sql("UPDATE Categories SET ArName = N'غرفة النوم' WHERE Slug = N'chambre'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ArName",
                table: "Categories");
        }
    }
}
