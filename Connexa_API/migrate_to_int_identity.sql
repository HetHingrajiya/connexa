USE [Connexa];
SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Create mapping temp tables
    CREATE TABLE #IndustryMap (
        OldId NVARCHAR(50) PRIMARY KEY,
        NewId INT IDENTITY(1,1) NOT NULL
    );
    INSERT INTO #IndustryMap (OldId)
    SELECT Id FROM Industries ORDER BY Id;

    CREATE TABLE #BusinessGroupMap (
        OldId NVARCHAR(50) PRIMARY KEY,
        NewId INT IDENTITY(1,1) NOT NULL
    );
    INSERT INTO #BusinessGroupMap (OldId)
    SELECT Id FROM BusinessGroups ORDER BY Id;

    CREATE TABLE #SubGroupMap (
        OldId NVARCHAR(50) PRIMARY KEY,
        NewId INT IDENTITY(1,1) NOT NULL
    );
    INSERT INTO #SubGroupMap (OldId)
    SELECT Id FROM SubGroups ORDER BY Id;

    CREATE TABLE #CategoryMap (
        OldId NVARCHAR(50) PRIMARY KEY,
        NewId INT IDENTITY(1,1) NOT NULL
    );
    INSERT INTO #CategoryMap (OldId)
    SELECT Id FROM Categories ORDER BY Id;

    CREATE TABLE #OtpMap (
        OldId UNIQUEIDENTIFIER PRIMARY KEY,
        NewId INT IDENTITY(1,1) NOT NULL
    );
    INSERT INTO #OtpMap (OldId)
    SELECT Id FROM OtpChallenges ORDER BY CreatedAtUtc, Id;

    -- 2. Create new tables with INT IDENTITY(1,1) (unconstrained initially to prevent name collision with existing schema-scoped PKs)
    CREATE TABLE Industries_New (
        Id INT IDENTITY(1,1) NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Code NVARCHAR(50) NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT (SYSUTCDATETIME())
    );

    CREATE TABLE BusinessGroups_New (
        Id INT IDENTITY(1,1) NOT NULL,
        IndustryId INT NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Code NVARCHAR(50) NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT (SYSUTCDATETIME())
    );

    CREATE TABLE SubGroups_New (
        Id INT IDENTITY(1,1) NOT NULL,
        BusinessGroupId INT NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Code NVARCHAR(50) NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT (SYSUTCDATETIME())
    );

    CREATE TABLE Categories_New (
        Id INT IDENTITY(1,1) NOT NULL,
        SubGroupId INT NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Code NVARCHAR(50) NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT (SYSUTCDATETIME())
    );

    CREATE TABLE OtpChallenges_New (
        Id INT IDENTITY(1,1) NOT NULL,
        PhoneNumber NVARCHAR(30) NOT NULL,
        OtpHashingSalt NVARCHAR(100) NOT NULL,
        OtpHash NVARCHAR(128) NOT NULL,
        Purpose NVARCHAR(50) NOT NULL,
        RegistrationFlowId NVARCHAR(100) NOT NULL,
        CreatedAtUtc DATETIME2(7) NOT NULL,
        ExpiresAtUtc DATETIME2(7) NOT NULL,
        VerifiedAtUtc DATETIME2(7) NULL,
        AttemptCount INT NOT NULL,
        MaxAttempts INT NOT NULL,
        ResendCount INT NOT NULL,
        LastResentAtUtc DATETIME2(7) NULL,
        Status INT NOT NULL,
        VerificationGrantToken NVARCHAR(100) NULL,
        VerificationGrantExpiresAtUtc DATETIME2(7) NULL,
        RequestIpAddress NVARCHAR(64) NULL,
        ProviderMessageId NVARCHAR(100) NULL,
        OtpCode NVARCHAR(10) NOT NULL
    );

    -- 3. Copy data into new tables preserving deterministic IDs via IDENTITY_INSERT
    SET IDENTITY_INSERT Industries_New ON;
    INSERT INTO Industries_New (Id, Name, Code, Description, CreatedAt)
    SELECT m.NewId, i.Name, i.Code, i.Description, i.CreatedAt
    FROM Industries i
    JOIN #IndustryMap m ON i.Id = m.OldId;
    SET IDENTITY_INSERT Industries_New OFF;

    SET IDENTITY_INSERT BusinessGroups_New ON;
    INSERT INTO BusinessGroups_New (Id, IndustryId, Name, Code, Description, CreatedAt)
    SELECT bgm.NewId, im.NewId, bg.Name, bg.Code, bg.Description, bg.CreatedAt
    FROM BusinessGroups bg
    JOIN #BusinessGroupMap bgm ON bg.Id = bgm.OldId
    JOIN #IndustryMap im ON bg.IndustryId = im.OldId;
    SET IDENTITY_INSERT BusinessGroups_New OFF;

    SET IDENTITY_INSERT SubGroups_New ON;
    INSERT INTO SubGroups_New (Id, BusinessGroupId, Name, Code, Description, CreatedAt)
    SELECT sgm.NewId, bgm.NewId, sg.Name, sg.Code, sg.Description, sg.CreatedAt
    FROM SubGroups sg
    JOIN #SubGroupMap sgm ON sg.Id = sgm.OldId
    JOIN #BusinessGroupMap bgm ON sg.BusinessGroupId = bgm.OldId;
    SET IDENTITY_INSERT SubGroups_New OFF;

    SET IDENTITY_INSERT Categories_New ON;
    INSERT INTO Categories_New (Id, SubGroupId, Name, Code, Description, CreatedAt)
    SELECT cm.NewId, sgm.NewId, c.Name, c.Code, c.Description, c.CreatedAt
    FROM Categories c
    JOIN #CategoryMap cm ON c.Id = cm.OldId
    JOIN #SubGroupMap sgm ON c.SubGroupId = sgm.OldId;
    SET IDENTITY_INSERT Categories_New OFF;

    SET IDENTITY_INSERT OtpChallenges_New ON;
    INSERT INTO OtpChallenges_New (
        Id, PhoneNumber, OtpHashingSalt, OtpHash, Purpose,
        RegistrationFlowId, CreatedAtUtc, ExpiresAtUtc, VerifiedAtUtc,
        AttemptCount, MaxAttempts, ResendCount, LastResentAtUtc,
        Status, VerificationGrantToken, VerificationGrantExpiresAtUtc,
        RequestIpAddress, ProviderMessageId, OtpCode
    )
    SELECT 
        om.NewId, o.PhoneNumber, o.OtpHashingSalt, o.OtpHash, o.Purpose,
        o.RegistrationFlowId, o.CreatedAtUtc, o.ExpiresAtUtc, o.VerifiedAtUtc,
        o.AttemptCount, o.MaxAttempts, o.ResendCount, o.LastResentAtUtc,
        o.Status, o.VerificationGrantToken, o.VerificationGrantExpiresAtUtc,
        o.RequestIpAddress, o.ProviderMessageId, o.OtpCode
    FROM OtpChallenges o
    JOIN #OtpMap om ON o.Id = om.OldId;
    SET IDENTITY_INSERT OtpChallenges_New OFF;

    -- 4. Verify Row Counts Before Swapping
    DECLARE @OldIndCount INT = (SELECT COUNT(*) FROM Industries);
    DECLARE @NewIndCount INT = (SELECT COUNT(*) FROM Industries_New);
    IF (@OldIndCount <> @NewIndCount) RAISERROR('Industries row count mismatch', 16, 1);

    DECLARE @OldBgCount INT = (SELECT COUNT(*) FROM BusinessGroups);
    DECLARE @NewBgCount INT = (SELECT COUNT(*) FROM BusinessGroups_New);
    IF (@OldBgCount <> @NewBgCount) RAISERROR('BusinessGroups row count mismatch', 16, 1);

    DECLARE @OldSgCount INT = (SELECT COUNT(*) FROM SubGroups);
    DECLARE @NewSgCount INT = (SELECT COUNT(*) FROM SubGroups_New);
    IF (@OldSgCount <> @NewSgCount) RAISERROR('SubGroups row count mismatch', 16, 1);

    DECLARE @OldCatCount INT = (SELECT COUNT(*) FROM Categories);
    DECLARE @NewCatCount INT = (SELECT COUNT(*) FROM Categories_New);
    IF (@OldCatCount <> @NewCatCount) RAISERROR('Categories row count mismatch', 16, 1);

    DECLARE @OldOtpCount INT = (SELECT COUNT(*) FROM OtpChallenges);
    DECLARE @NewOtpCount INT = (SELECT COUNT(*) FROM OtpChallenges_New);
    IF (@OldOtpCount <> @NewOtpCount) RAISERROR('OtpChallenges row count mismatch', 16, 1);

    -- 5. Reseed identities on new tables to the max inserted ID
    DECLARE @MaxIndId INT = ISNULL((SELECT MAX(Id) FROM Industries_New), 0);
    IF (@MaxIndId > 0) DBCC CHECKIDENT ('Industries_New', RESEED, @MaxIndId);

    DECLARE @MaxBgId INT = ISNULL((SELECT MAX(Id) FROM BusinessGroups_New), 0);
    IF (@MaxBgId > 0) DBCC CHECKIDENT ('BusinessGroups_New', RESEED, @MaxBgId);

    DECLARE @MaxSgId INT = ISNULL((SELECT MAX(Id) FROM SubGroups_New), 0);
    IF (@MaxSgId > 0) DBCC CHECKIDENT ('SubGroups_New', RESEED, @MaxSgId);

    DECLARE @MaxCatId INT = ISNULL((SELECT MAX(Id) FROM Categories_New), 0);
    IF (@MaxCatId > 0) DBCC CHECKIDENT ('Categories_New', RESEED, @MaxCatId);

    DECLARE @MaxOtpId INT = ISNULL((SELECT MAX(Id) FROM OtpChallenges_New), 0);
    IF (@MaxOtpId > 0) DBCC CHECKIDENT ('OtpChallenges_New', RESEED, @MaxOtpId);

    -- 6. Drop old Foreign Keys
    ALTER TABLE Categories DROP CONSTRAINT FK_Categories_SubGroups;
    ALTER TABLE SubGroups DROP CONSTRAINT FK_SubGroups_BusinessGroups;
    ALTER TABLE BusinessGroups DROP CONSTRAINT FK_BusinessGroups_Industries;

    -- 7. Drop old tables
    DROP TABLE Categories;
    DROP TABLE SubGroups;
    DROP TABLE BusinessGroups;
    DROP TABLE Industries;
    DROP TABLE OtpChallenges;

    -- 8. Rename New tables to canonical names
    EXEC sp_rename 'Industries_New', 'Industries';
    EXEC sp_rename 'BusinessGroups_New', 'BusinessGroups';
    EXEC sp_rename 'SubGroups_New', 'SubGroups';
    EXEC sp_rename 'Categories_New', 'Categories';
    EXEC sp_rename 'OtpChallenges_New', 'OtpChallenges';

    -- 9. Add Primary Key constraints
    ALTER TABLE Industries ADD CONSTRAINT PK_Industries PRIMARY KEY CLUSTERED (Id);
    ALTER TABLE BusinessGroups ADD CONSTRAINT PK_BusinessGroups PRIMARY KEY CLUSTERED (Id);
    ALTER TABLE SubGroups ADD CONSTRAINT PK_SubGroups PRIMARY KEY CLUSTERED (Id);
    ALTER TABLE Categories ADD CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (Id);
    ALTER TABLE OtpChallenges ADD CONSTRAINT PK_OtpChallenges PRIMARY KEY CLUSTERED (Id);

    -- 10. Add Foreign Key constraints
    ALTER TABLE BusinessGroups WITH CHECK ADD CONSTRAINT FK_BusinessGroups_Industries 
        FOREIGN KEY (IndustryId) REFERENCES Industries (Id) ON DELETE CASCADE;
    ALTER TABLE BusinessGroups CHECK CONSTRAINT FK_BusinessGroups_Industries;

    ALTER TABLE SubGroups WITH CHECK ADD CONSTRAINT FK_SubGroups_BusinessGroups 
        FOREIGN KEY (BusinessGroupId) REFERENCES BusinessGroups (Id) ON DELETE CASCADE;
    ALTER TABLE SubGroups CHECK CONSTRAINT FK_SubGroups_BusinessGroups;

    ALTER TABLE Categories WITH CHECK ADD CONSTRAINT FK_Categories_SubGroups 
        FOREIGN KEY (SubGroupId) REFERENCES SubGroups (Id) ON DELETE CASCADE;
    ALTER TABLE Categories CHECK CONSTRAINT FK_Categories_SubGroups;

    -- 11. Recreate indexes
    CREATE NONCLUSTERED INDEX IX_Industries_Name ON Industries (Name);
    CREATE NONCLUSTERED INDEX IX_BusinessGroups_IndustryId ON BusinessGroups (IndustryId);
    CREATE NONCLUSTERED INDEX IX_BusinessGroups_Name ON BusinessGroups (Name);
    CREATE NONCLUSTERED INDEX IX_SubGroups_BusinessGroupId ON SubGroups (BusinessGroupId);
    CREATE NONCLUSTERED INDEX IX_SubGroups_Name ON SubGroups (Name);
    CREATE NONCLUSTERED INDEX IX_Categories_SubGroupId ON Categories (SubGroupId);
    CREATE NONCLUSTERED INDEX IX_Categories_Name ON Categories (Name);

    CREATE NONCLUSTERED INDEX IX_OtpChallenges_PhoneNumber ON OtpChallenges (PhoneNumber);
    CREATE NONCLUSTERED INDEX IX_OtpChallenges_RegistrationFlowId ON OtpChallenges (RegistrationFlowId);
    CREATE NONCLUSTERED INDEX IX_OtpChallenges_VerificationGrantToken ON OtpChallenges (VerificationGrantToken);
    CREATE NONCLUSTERED INDEX IX_OtpChallenges_Phone_Status ON OtpChallenges (PhoneNumber, Status);

    COMMIT TRANSACTION;
    PRINT 'MIGRATION COMPLETED SUCCESSFULLY';
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
