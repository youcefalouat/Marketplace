using MarketplaceApi.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketplaceApi.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260530210500_ImproveChatRealtimeUnread")]
    public partial class ImproveChatRealtimeUnread : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ReceiverId",
                table: "Messages",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReadAt",
                table: "Messages",
                type: "datetime2",
                nullable: true);

            migrationBuilder.Sql(@"
UPDATE m
SET ReceiverId = CASE
    WHEN m.SenderId = c.BuyerId THEN c.SellerId
    ELSE c.BuyerId
END
FROM Messages m
INNER JOIN Conversations c ON c.Id = m.ConversationId
WHERE m.ReceiverId = 0;");

            migrationBuilder.Sql(@"
UPDATE Messages
SET ReadAt = SentAt
WHERE IsRead = 1 AND ReadAt IS NULL;");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_AnnonceId_BuyerId_SellerId_IsModeration",
                table: "Conversations",
                columns: new[] { "AnnonceId", "BuyerId", "SellerId", "IsModeration" });

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_BuyerId_LastMessageAt",
                table: "Conversations",
                columns: new[] { "BuyerId", "LastMessageAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_LastMessageAt",
                table: "Conversations",
                column: "LastMessageAt");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_SellerId_LastMessageAt",
                table: "Conversations",
                columns: new[] { "SellerId", "LastMessageAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_ConversationId_SentAt",
                table: "Messages",
                columns: new[] { "ConversationId", "SentAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_ReceiverId_IsRead",
                table: "Messages",
                columns: new[] { "ReceiverId", "IsRead" });

            migrationBuilder.AddForeignKey(
                name: "FK_Messages_Users_ReceiverId",
                table: "Messages",
                column: "ReceiverId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Messages_Users_ReceiverId",
                table: "Messages");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_AnnonceId_BuyerId_SellerId_IsModeration",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_BuyerId_LastMessageAt",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_LastMessageAt",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_SellerId_LastMessageAt",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Messages_ConversationId_SentAt",
                table: "Messages");

            migrationBuilder.DropIndex(
                name: "IX_Messages_ReceiverId_IsRead",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "ReadAt",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "ReceiverId",
                table: "Messages");
        }
    }
}
