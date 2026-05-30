-- Run this against MarketplaceDb to fix the migration issue
DELETE FROM [__EFMigrationsHistory] WHERE [MigrationId] = '20260426151456_deletedByAt';
