using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketplaceApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddImageThumbnails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ThumbnailMediumPath",
                table: "AnnonceImages",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ThumbnailSmallPath",
                table: "AnnonceImages",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ThumbnailMediumPath",
                table: "AnnonceImages");

            migrationBuilder.DropColumn(
                name: "ThumbnailSmallPath",
                table: "AnnonceImages");
        }
    }
}
