IF COL_LENGTH('dbo.Categories', 'ArName') IS NULL
BEGIN
    ALTER TABLE dbo.Categories ADD ArName NVARCHAR(255) NOT NULL CONSTRAINT DF_Categories_ArName DEFAULT N'';
END;

UPDATE dbo.Categories SET ArName = N'الأجهزة المنزلية' WHERE Slug = N'electromenager';
UPDATE dbo.Categories SET ArName = N'أثاث' WHERE Slug = N'meubles';
UPDATE dbo.Categories SET ArName = N'مفروشات' WHERE Slug = N'literie';
UPDATE dbo.Categories SET ArName = N'ديكور' WHERE Slug = N'decoration';
UPDATE dbo.Categories SET ArName = N'أجهزة منزلية كبيرة' WHERE Slug = N'gros-electromenager';
UPDATE dbo.Categories SET ArName = N'أجهزة منزلية صغيرة' WHERE Slug = N'petit-electromenager';
UPDATE dbo.Categories SET ArName = N'غرفة المعيشة' WHERE Slug = N'salon';
UPDATE dbo.Categories SET ArName = N'غرفة النوم' WHERE Slug = N'chambre';
