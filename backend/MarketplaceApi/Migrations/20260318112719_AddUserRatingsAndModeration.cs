using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketplaceApi.Migrations
{
    /// <inheritdoc />
    public partial class AddUserRatingsAndModeration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsModeration",
                table: "Conversations",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "ModerationThreads",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AnnonceId = table.Column<int>(type: "int", nullable: false),
                    OwnerId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ClosedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModerationThreads", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ModerationThreads_Annonces_AnnonceId",
                        column: x => x.AnnonceId,
                        principalTable: "Annonces",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ModerationThreads_Users_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserRatings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SellerId = table.Column<int>(type: "int", nullable: false),
                    RaterId = table.Column<int>(type: "int", nullable: false),
                    Rating = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRatings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserRatings_Users_RaterId",
                        column: x => x.RaterId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserRatings_Users_SellerId",
                        column: x => x.SellerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ModerationMessages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ThreadId = table.Column<int>(type: "int", nullable: false),
                    SenderId = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    SentAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsFromAdmin = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModerationMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ModerationMessages_ModerationThreads_ThreadId",
                        column: x => x.ThreadId,
                        principalTable: "ModerationThreads",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ModerationMessages_Users_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ModerationMessages_SenderId",
                table: "ModerationMessages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_ModerationMessages_SentAt",
                table: "ModerationMessages",
                column: "SentAt");

            migrationBuilder.CreateIndex(
                name: "IX_ModerationMessages_ThreadId",
                table: "ModerationMessages",
                column: "ThreadId");

            migrationBuilder.CreateIndex(
                name: "IX_ModerationThreads_AnnonceId",
                table: "ModerationThreads",
                column: "AnnonceId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ModerationThreads_OwnerId",
                table: "ModerationThreads",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_RaterId",
                table: "UserRatings",
                column: "RaterId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_SellerId_RaterId",
                table: "UserRatings",
                columns: new[] { "SellerId", "RaterId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ModerationMessages");

            migrationBuilder.DropTable(
                name: "UserRatings");

            migrationBuilder.DropTable(
                name: "ModerationThreads");

            migrationBuilder.DropColumn(
                name: "IsModeration",
                table: "Conversations");
        }
    }
}
