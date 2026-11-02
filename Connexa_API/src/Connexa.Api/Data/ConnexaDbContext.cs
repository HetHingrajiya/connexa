using Microsoft.EntityFrameworkCore;
using Connexa.Api.Entities;

namespace Connexa.Api.Data;

public class ConnexaDbContext : DbContext
{
    public ConnexaDbContext(DbContextOptions<ConnexaDbContext> options) : base(options)
    {
    }

    public DbSet<Industry> Industries => Set<Industry>();
    public DbSet<BusinessGroup> BusinessGroups => Set<BusinessGroup>();
    public DbSet<SubGroup> SubGroups => Set<SubGroup>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<OtpChallenge> OtpChallenges => Set<OtpChallenge>();
    public DbSet<Member> Members => Set<Member>();
    public DbSet<BusinessProfile> BusinessProfiles => Set<BusinessProfile>();
    public DbSet<EmployeeProfile> EmployeeProfiles => Set<EmployeeProfile>();
    public DbSet<ServiceEngineerProfile> ServiceEngineerProfiles => Set<ServiceEngineerProfile>();
    public DbSet<TraderProfile> TraderProfiles => Set<TraderProfile>();
    public DbSet<ContractorProfile> ContractorProfiles => Set<ContractorProfile>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<MemberConnection> MemberConnections => Set<MemberConnection>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductInquiry> ProductInquiries => Set<ProductInquiry>();
    public DbSet<ProfileView> ProfileViews => Set<ProfileView>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<BusinessVerificationRequest> BusinessVerificationRequests => Set<BusinessVerificationRequest>();
    public DbSet<BusinessVerificationDocument> BusinessVerificationDocuments => Set<BusinessVerificationDocument>();
    public DbSet<Rfq> Rfqs => Set<Rfq>();
    public DbSet<Quotation> Quotations => Set<Quotation>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    public DbSet<JobWorkRequirement> JobWorkRequirements => Set<JobWorkRequirement>();
    public DbSet<JobWorkAttachment> JobWorkAttachments => Set<JobWorkAttachment>();
    public DbSet<JobWorkQuotation> JobWorkQuotations => Set<JobWorkQuotation>();
    public DbSet<JobWorkOrder> JobWorkOrders => Set<JobWorkOrder>();
    public DbSet<JobWorkOrderStatusHistory> JobWorkOrderStatusHistories => Set<JobWorkOrderStatusHistory>();
    public DbSet<AccountDeletionRequest> AccountDeletionRequests => Set<AccountDeletionRequest>();
    public DbSet<BusinessService> BusinessServices => Set<BusinessService>();
    public DbSet<ServiceInquiry> ServiceInquiries => Set<ServiceInquiry>();
    public DbSet<ServiceInquiryStatusHistory> ServiceInquiryStatusHistories => Set<ServiceInquiryStatusHistory>();
    public DbSet<JobOpening> JobOpenings => Set<JobOpening>();
    public DbSet<JobApplication> JobApplications => Set<JobApplication>();
    public DbSet<JobApplicationAttachment> JobApplicationAttachments => Set<JobApplicationAttachment>();
    public DbSet<JobApplicationStatusHistory> JobApplicationStatusHistories => Set<JobApplicationStatusHistory>();
    public DbSet<BusinessPost> BusinessPosts => Set<BusinessPost>();
    public DbSet<BusinessPostAttachment> BusinessPostAttachments => Set<BusinessPostAttachment>();
    public DbSet<BusinessPostLike> BusinessPostLikes => Set<BusinessPostLike>();
    public DbSet<BusinessPostComment> BusinessPostComments => Set<BusinessPostComment>();
    public DbSet<BusinessPostReport> BusinessPostReports => Set<BusinessPostReport>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1. Industry
        modelBuilder.Entity<Industry>(entity =>
        {
            entity.ToTable("Industries");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasIndex(e => e.Name).HasDatabaseName("IX_Industries_Name");
        });

        // 2. BusinessGroup
        modelBuilder.Entity<BusinessGroup>(entity =>
        {
            entity.ToTable("BusinessGroups");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.IndustryId).IsRequired();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Industry)
                  .WithMany(i => i.BusinessGroups)
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessGroups_Industries");

            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_BusinessGroups_IndustryId");
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_BusinessGroups_Name");
        });

        // 3. SubGroup
        modelBuilder.Entity<SubGroup>(entity =>
        {
            entity.ToTable("SubGroups");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.BusinessGroupId).IsRequired();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.BusinessGroup)
                  .WithMany(bg => bg.SubGroups)
                  .HasForeignKey(e => e.BusinessGroupId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_SubGroups_BusinessGroups");

            entity.HasIndex(e => e.BusinessGroupId).HasDatabaseName("IX_SubGroups_BusinessGroupId");
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_SubGroups_Name");
        });

        // 4. Category
        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("Categories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.SubGroupId).IsRequired();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.SubGroup)
                  .WithMany(sg => sg.Categories)
                  .HasForeignKey(e => e.SubGroupId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_Categories_SubGroups");

            entity.HasIndex(e => e.SubGroupId).HasDatabaseName("IX_Categories_SubGroupId");
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_Categories_Name");
        });

        // 5. OtpChallenge
        modelBuilder.Entity<OtpChallenge>(entity =>
        {
            entity.ToTable("OtpChallenges");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.PhoneNumber).HasMaxLength(30);
            entity.Property(e => e.Email).HasMaxLength(256);
            entity.Property(e => e.OtpCode).HasMaxLength(10);
            entity.Property(e => e.OtpHashingSalt).HasMaxLength(100).IsRequired();
            entity.Property(e => e.OtpHash).HasMaxLength(128).IsRequired();
            entity.Property(e => e.Purpose).HasMaxLength(50).IsRequired();
            entity.Property(e => e.RegistrationFlowId).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.VerificationGrantToken).HasMaxLength(100);
            entity.Property(e => e.RequestIpAddress).HasMaxLength(64);
            entity.Property(e => e.ProviderMessageId).HasMaxLength(100);

            entity.HasIndex(e => e.PhoneNumber).HasDatabaseName("IX_OtpChallenges_PhoneNumber");
            entity.HasIndex(e => e.Email).HasDatabaseName("IX_OtpChallenges_Email");
            entity.HasIndex(e => e.RegistrationFlowId).HasDatabaseName("IX_OtpChallenges_RegistrationFlowId");
            entity.HasIndex(e => e.VerificationGrantToken).HasDatabaseName("IX_OtpChallenges_VerificationGrantToken");
            entity.HasIndex(e => new { e.PhoneNumber, e.Status }).HasDatabaseName("IX_OtpChallenges_Phone_Status");
            entity.HasIndex(e => new { e.Email, e.Status }).HasDatabaseName("IX_OtpChallenges_Email_Status");
        });

        // 6. Member
        modelBuilder.Entity<Member>(entity =>
        {
            entity.ToTable("Members");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.FullName).HasMaxLength(200).IsRequired();
            entity.Property(e => e.CountryCode).HasMaxLength(10).HasDefaultValue("+91").IsRequired();
            entity.Property(e => e.PhoneNumber).HasMaxLength(30).IsRequired();
            entity.Property(e => e.Email).HasMaxLength(256).IsRequired();
            entity.Property(e => e.PrimaryProfileType).HasConversion<int>().IsRequired();
            entity.Property(e => e.VerifiedMethod).HasMaxLength(20).IsRequired();
            entity.Property(e => e.VerifiedDestination).HasMaxLength(256).IsRequired();
            entity.Property(e => e.Role).HasMaxLength(50).HasDefaultValue("Member").IsRequired();
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.PasswordHash).HasMaxLength(256);
            entity.Property(e => e.PasswordSalt).HasMaxLength(128);
            entity.Property(e => e.CredentialSetupToken).HasMaxLength(128);
            entity.Property(e => e.DeactivationReason).HasMaxLength(500);
            entity.Property(e => e.FailedLoginAttempts).HasDefaultValue(0);

            entity.HasIndex(e => e.PhoneNumber).IsUnique().HasDatabaseName("IX_Members_PhoneNumber");
            entity.HasIndex(e => e.Email).IsUnique().HasDatabaseName("IX_Members_Email");
            entity.HasIndex(e => e.CredentialSetupToken).HasDatabaseName("IX_Members_CredentialSetupToken");
        });

        // 7. BusinessProfile
        modelBuilder.Entity<BusinessProfile>(entity =>
        {
            entity.ToTable("BusinessProfiles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.CompanyName).HasMaxLength(250).IsRequired();
            entity.Property(e => e.BusinessCapabilities).HasMaxLength(500);
            entity.Property(e => e.BusinessDescription).HasMaxLength(2000);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.State).HasMaxLength(100);
            entity.Property(e => e.Pincode).HasMaxLength(20);
            entity.Property(e => e.WebsiteUrl).HasMaxLength(500);
            entity.Property(e => e.LogoUrl).HasMaxLength(1000);
            entity.Property(e => e.BusinessImagesJson).HasMaxLength(4000);
            entity.Property(e => e.VerificationStatus).HasConversion<int>().HasDefaultValue(BusinessVerificationStatus.NotSubmitted);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasIndex(e => e.VerificationStatus).HasDatabaseName("IX_BusinessProfiles_VerificationStatus");

            entity.HasOne(e => e.Member)
                  .WithOne(m => m.BusinessProfile)
                  .HasForeignKey<BusinessProfile>(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessProfiles_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessProfiles_Industries");

            entity.HasOne(e => e.BusinessGroup)
                  .WithMany()
                  .HasForeignKey(e => e.BusinessGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessProfiles_BusinessGroups");

            entity.HasOne(e => e.SubGroup)
                  .WithMany()
                  .HasForeignKey(e => e.SubGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessProfiles_SubGroups");

            entity.HasOne(e => e.Category)
                  .WithMany()
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessProfiles_Categories");

            entity.HasIndex(e => e.MemberId).IsUnique().HasDatabaseName("IX_BusinessProfiles_MemberId");
        });

        // 8. EmployeeProfile
        modelBuilder.Entity<EmployeeProfile>(entity =>
        {
            entity.ToTable("EmployeeProfiles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.JobTitle).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Skills).HasMaxLength(1000).IsRequired();
            entity.Property(e => e.Experience).HasMaxLength(500);
            entity.Property(e => e.PreferredJobType).HasMaxLength(100);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithOne(m => m.EmployeeProfile)
                  .HasForeignKey<EmployeeProfile>(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_EmployeeProfiles_Members");

            entity.HasIndex(e => e.MemberId).IsUnique().HasDatabaseName("IX_EmployeeProfiles_MemberId");
        });

        // 9. ServiceEngineerProfile
        modelBuilder.Entity<ServiceEngineerProfile>(entity =>
        {
            entity.ToTable("ServiceEngineerProfiles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Specialization).HasMaxLength(300).IsRequired();
            entity.Property(e => e.SupportedEquipment).HasMaxLength(1000);
            entity.Property(e => e.YearsOfExperience).HasMaxLength(100);
            entity.Property(e => e.ServiceCoverage).HasMaxLength(300);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithOne(m => m.ServiceEngineerProfile)
                  .HasForeignKey<ServiceEngineerProfile>(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_ServiceEngineerProfiles_Members");

            entity.HasIndex(e => e.MemberId).IsUnique().HasDatabaseName("IX_ServiceEngineerProfiles_MemberId");
        });

        // 10. TraderProfile
        modelBuilder.Entity<TraderProfile>(entity =>
        {
            entity.ToTable("TraderProfiles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.TradingName).HasMaxLength(250).IsRequired();
            entity.Property(e => e.Capabilities).HasMaxLength(500);
            entity.Property(e => e.ProductsSupplied).HasMaxLength(1000);
            entity.Property(e => e.ServiceCoverage).HasMaxLength(300);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithOne(m => m.TraderProfile)
                  .HasForeignKey<TraderProfile>(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_TraderProfiles_Members");

            entity.HasIndex(e => e.MemberId).IsUnique().HasDatabaseName("IX_TraderProfiles_MemberId");
        });

        // 11. ContractorProfile
        modelBuilder.Entity<ContractorProfile>(entity =>
        {
            entity.ToTable("ContractorProfiles");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.WorkName).HasMaxLength(250).IsRequired();
            entity.Property(e => e.WorkCapabilities).HasMaxLength(500);
            entity.Property(e => e.ProcessesSupported).HasMaxLength(1000);
            entity.Property(e => e.WorkCoverage).HasMaxLength(300);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithOne(m => m.ContractorProfile)
                  .HasForeignKey<ContractorProfile>(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_ContractorProfiles_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ContractorProfiles_Industries");

            entity.HasOne(e => e.BusinessGroup)
                  .WithMany()
                  .HasForeignKey(e => e.BusinessGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ContractorProfiles_BusinessGroups");

            entity.HasOne(e => e.SubGroup)
                  .WithMany()
                  .HasForeignKey(e => e.SubGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ContractorProfiles_SubGroups");

            entity.HasOne(e => e.Category)
                  .WithMany()
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ContractorProfiles_Categories");

            entity.HasIndex(e => e.MemberId).IsUnique().HasDatabaseName("IX_ContractorProfiles_MemberId");
        });

        // 12. RefreshToken
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("RefreshTokens");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.TokenHash).HasMaxLength(128).IsRequired();
            entity.Property(e => e.ExpiresAtUtc).IsRequired();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.CreatedByIp).HasMaxLength(64);
            entity.Property(e => e.RevokedByIp).HasMaxLength(64);
            entity.Property(e => e.ReplacedByTokenHash).HasMaxLength(128);
            entity.Property(e => e.ReasonRevoked).HasMaxLength(256);
            entity.Property(e => e.DeviceName).HasMaxLength(128);
            entity.Property(e => e.UserAgent).HasMaxLength(512);
            entity.Property(e => e.LastActiveAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.RefreshTokens)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_RefreshTokens_Members");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_RefreshTokens_MemberId");
            entity.HasIndex(e => e.TokenHash).IsUnique().HasDatabaseName("IX_RefreshTokens_TokenHash");
        });

        // 13. MemberConnection
        modelBuilder.Entity<MemberConnection>(entity =>
        {
            entity.ToTable("MemberConnections");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.RequesterMemberId).IsRequired();
            entity.Property(e => e.RecipientMemberId).IsRequired();
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.Note).HasMaxLength(500);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.RequesterMember)
                  .WithMany(m => m.SentConnections)
                  .HasForeignKey(e => e.RequesterMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_MemberConnections_RequesterMember");

            entity.HasOne(e => e.RecipientMember)
                  .WithMany(m => m.ReceivedConnections)
                  .HasForeignKey(e => e.RecipientMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_MemberConnections_RecipientMember");

            entity.HasIndex(e => e.RequesterMemberId).HasDatabaseName("IX_MemberConnections_RequesterMemberId");
            entity.HasIndex(e => e.RecipientMemberId).HasDatabaseName("IX_MemberConnections_RecipientMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_MemberConnections_Status");
            entity.HasIndex(e => new { e.RequesterMemberId, e.RecipientMemberId }).HasDatabaseName("IX_MemberConnections_Requester_Recipient");
        });

        // 14. Product
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("Products");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(2000).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(200).IsRequired();
            entity.Property(e => e.SubCategory).HasMaxLength(200);
            entity.Property(e => e.TagsJson).HasMaxLength(2000);
            entity.Property(e => e.ImageUrl).HasMaxLength(1000);
            entity.Property(e => e.SpecificationsJson).HasMaxLength(4000);
            entity.Property(e => e.ViewCount).HasDefaultValue(0);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.Property(e => e.IndustryId);

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.Products)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_Products_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Products_Industries");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_Products_MemberId");
            entity.HasIndex(e => e.Category).HasDatabaseName("IX_Products_Category");
            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_Products_IndustryId");
        });


        // 15. ProductInquiry
        modelBuilder.Entity<ProductInquiry>(entity =>
        {
            entity.ToTable("ProductInquiries");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.ProductId).IsRequired();
            entity.Property(e => e.SenderMemberId).IsRequired();
            entity.Property(e => e.RecipientMemberId).IsRequired();
            entity.Property(e => e.Subject).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Message).HasMaxLength(2000).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(50).IsRequired().HasDefaultValue("Pending");
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.ResponseMessage).HasMaxLength(2000);

            entity.HasOne(e => e.Product)
                  .WithMany(p => p.Inquiries)
                  .HasForeignKey(e => e.ProductId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_ProductInquiries_Products");

            entity.HasOne(e => e.SenderMember)
                  .WithMany(m => m.SentInquiries)
                  .HasForeignKey(e => e.SenderMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ProductInquiries_SenderMember");

            entity.HasOne(e => e.RecipientMember)
                  .WithMany(m => m.ReceivedInquiries)
                  .HasForeignKey(e => e.RecipientMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ProductInquiries_RecipientMember");

            entity.HasIndex(e => e.ProductId).HasDatabaseName("IX_ProductInquiries_ProductId");
            entity.HasIndex(e => e.SenderMemberId).HasDatabaseName("IX_ProductInquiries_SenderMemberId");
            entity.HasIndex(e => e.RecipientMemberId).HasDatabaseName("IX_ProductInquiries_RecipientMemberId");
        });

        // 16. ProfileView
        modelBuilder.Entity<ProfileView>(entity =>
        {
            entity.ToTable("ProfileViews");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.ViewedMemberId).IsRequired();
            entity.Property(e => e.ViewedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.ViewedMember)
                  .WithMany(m => m.ProfileViews)
                  .HasForeignKey(e => e.ViewedMemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_ProfileViews_ViewedMember");

            entity.HasIndex(e => e.ViewedMemberId).HasDatabaseName("IX_ProfileViews_ViewedMemberId");
        });

        // 17. Notification
        modelBuilder.Entity<Notification>(entity =>
        {
            entity.ToTable("Notifications");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.RecipientMemberId).IsRequired();
            entity.Property(e => e.EventType).HasConversion<int>().IsRequired();
            entity.Property(e => e.Title).HasMaxLength(150).IsRequired();
            entity.Property(e => e.Message).HasMaxLength(500).IsRequired();
            entity.Property(e => e.IsRead).HasDefaultValue(false).IsRequired();
            entity.Property(e => e.ReferenceType).HasMaxLength(50);
            entity.Property(e => e.PayloadJson).HasMaxLength(2000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.RecipientMember)
                  .WithMany(m => m.ReceivedNotifications)
                  .HasForeignKey(e => e.RecipientMemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_Notifications_RecipientMember");

            entity.HasOne(e => e.ActorMember)
                  .WithMany(m => m.TriggeredNotifications)
                  .HasForeignKey(e => e.ActorMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Notifications_ActorMember");

            entity.HasIndex(e => e.RecipientMemberId).HasDatabaseName("IX_Notifications_RecipientMemberId");
            entity.HasIndex(e => new { e.RecipientMemberId, e.IsRead }).HasDatabaseName("IX_Notifications_Recipient_IsRead");
            entity.HasIndex(e => new { e.RecipientMemberId, e.CreatedAtUtc }).HasDatabaseName("IX_Notifications_Recipient_CreatedAt");
            entity.HasIndex(e => new { e.ReferenceType, e.ReferenceId, e.EventType }).HasDatabaseName("IX_Notifications_Ref_Event");
        });

        // 18. DeviceToken
        modelBuilder.Entity<DeviceToken>(entity =>
        {
            entity.ToTable("DeviceTokens");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Token).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Platform).HasMaxLength(50).HasDefaultValue("android").IsRequired();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.UpdatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.DeviceTokens)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_DeviceTokens_Member");

            entity.HasIndex(e => new { e.MemberId, e.Token }).IsUnique().HasDatabaseName("UQ_DeviceTokens_Member_Token");
        });

        // 19. BusinessVerificationRequest
        modelBuilder.Entity<BusinessVerificationRequest>(entity =>
        {
            entity.ToTable("BusinessVerificationRequests");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.BusinessProfileId).IsRequired();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.BusinessRegistrationNumber).HasMaxLength(100).IsRequired();
            entity.Property(e => e.RegisteredAddress).HasMaxLength(500).IsRequired();
            entity.Property(e => e.City).HasMaxLength(100).IsRequired();
            entity.Property(e => e.State).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Pincode).HasMaxLength(20).IsRequired();
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.SubmittedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.BusinessProfile)
                  .WithMany(b => b.VerificationRequests)
                  .HasForeignKey(e => e.BusinessProfileId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessVerificationRequests_BusinessProfiles");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.VerificationRequests)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessVerificationRequests_Members");

            entity.HasOne(e => e.ReviewedByMember)
                  .WithMany(m => m.ReviewedVerificationRequests)
                  .HasForeignKey(e => e.ReviewedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessVerificationRequests_Reviewer");

            entity.HasIndex(e => e.BusinessProfileId).HasDatabaseName("IX_BusinessVerificationRequests_BusinessProfileId");
            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_BusinessVerificationRequests_MemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_BusinessVerificationRequests_Status");
        });

        // 20. BusinessVerificationDocument
        modelBuilder.Entity<BusinessVerificationDocument>(entity =>
        {
            entity.ToTable("BusinessVerificationDocuments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.VerificationRequestId).IsRequired();
            entity.Property(e => e.DocumentType).HasMaxLength(100).IsRequired();
            entity.Property(e => e.OriginalFileName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.StoredFileName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.FileExtension).HasMaxLength(20).IsRequired();
            entity.Property(e => e.ContentType).HasMaxLength(100).IsRequired();
            entity.Property(e => e.FileSizeBytes).IsRequired();
            entity.Property(e => e.UploadedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.VerificationRequest)
                  .WithMany(vr => vr.Documents)
                  .HasForeignKey(e => e.VerificationRequestId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessVerificationDocuments_VerificationRequests");

            entity.HasIndex(e => e.VerificationRequestId).HasDatabaseName("IX_BusinessVerificationDocuments_VerificationRequestId");
        });

        // 21. Rfq
        modelBuilder.Entity<Rfq>(entity =>
        {
            entity.ToTable("Rfqs");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.RfqNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.UnitOfMeasurement).HasMaxLength(50).IsRequired();
            entity.Property(e => e.TargetPrice).HasPrecision(18, 2);
            entity.Property(e => e.DeliveryLocation).HasMaxLength(300).IsRequired();
            entity.Property(e => e.AdditionalSpecifications).HasMaxLength(2000);
            entity.Property(e => e.AttachmentUrl).HasMaxLength(500);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Product)
                  .WithMany(p => p.Rfqs)
                  .HasForeignKey(e => e.ProductId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Rfqs_Products");

            entity.HasOne(e => e.BuyerMember)
                  .WithMany(m => m.SentRfqs)
                  .HasForeignKey(e => e.BuyerMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Rfqs_BuyerMember");

            entity.HasOne(e => e.SupplierMember)
                  .WithMany(m => m.ReceivedRfqs)
                  .HasForeignKey(e => e.SupplierMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Rfqs_SupplierMember");

            entity.HasOne(e => e.ProductInquiry)
                  .WithMany()
                  .HasForeignKey(e => e.ProductInquiryId)
                  .OnDelete(DeleteBehavior.SetNull)
                  .HasConstraintName("FK_Rfqs_ProductInquiries");

            entity.HasIndex(e => e.RfqNumber).IsUnique().HasDatabaseName("IX_Rfqs_RfqNumber");
            entity.HasIndex(e => e.BuyerMemberId).HasDatabaseName("IX_Rfqs_BuyerMemberId");
            entity.HasIndex(e => e.SupplierMemberId).HasDatabaseName("IX_Rfqs_SupplierMemberId");
            entity.HasIndex(e => e.ProductId).HasDatabaseName("IX_Rfqs_ProductId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_Rfqs_Status");
        });

        // 22. Quotation
        modelBuilder.Entity<Quotation>(entity =>
        {
            entity.ToTable("Quotations");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.QuotationNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Version).HasDefaultValue(1).IsRequired();
            entity.Property(e => e.UnitPrice).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Subtotal).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TaxRatePercent).HasPrecision(5, 2).HasDefaultValue(18.00m).IsRequired();
            entity.Property(e => e.TaxAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.ShippingCharges).HasPrecision(18, 2).HasDefaultValue(0.00m).IsRequired();
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.EstimatedDeliveryTime).HasMaxLength(100).IsRequired();
            entity.Property(e => e.TermsAndConditions).HasMaxLength(2000);
            entity.Property(e => e.DocumentUrl).HasMaxLength(500);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.RevisionNotes).HasMaxLength(1000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Rfq)
                  .WithMany(r => r.Quotations)
                  .HasForeignKey(e => e.RfqId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_Quotations_Rfqs");

            entity.HasOne(e => e.SupplierMember)
                  .WithMany(m => m.SubmittedQuotations)
                  .HasForeignKey(e => e.SupplierMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Quotations_SupplierMember");

            entity.HasOne(e => e.BuyerMember)
                  .WithMany(m => m.ReceivedQuotations)
                  .HasForeignKey(e => e.BuyerMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Quotations_BuyerMember");

            entity.HasIndex(e => e.QuotationNumber).IsUnique().HasDatabaseName("IX_Quotations_QuotationNumber");
            entity.HasIndex(e => e.RfqId).HasDatabaseName("IX_Quotations_RfqId");
            entity.HasIndex(e => e.SupplierMemberId).HasDatabaseName("IX_Quotations_SupplierMemberId");
            entity.HasIndex(e => e.BuyerMemberId).HasDatabaseName("IX_Quotations_BuyerMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_Quotations_Status");
        });

        // 23. Order
        modelBuilder.Entity<Order>(entity =>
        {
            entity.ToTable("Orders");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.OrderNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.QuotationId).IsRequired();
            entity.Property(e => e.RfqId).IsRequired();
            entity.Property(e => e.ProductId).IsRequired();
            entity.Property(e => e.BuyerMemberId).IsRequired();
            entity.Property(e => e.SupplierMemberId).IsRequired();

            entity.Property(e => e.ProductName).HasMaxLength(250).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.UnitOfMeasurement).HasMaxLength(50).IsRequired();
            entity.Property(e => e.UnitPrice).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Subtotal).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TaxRatePercent).HasPrecision(5, 2).IsRequired();
            entity.Property(e => e.TaxAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.ShippingCharges).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TermsAndConditionsSnapshot).HasMaxLength(2000);

            entity.Property(e => e.DeliveryAddress).HasMaxLength(500).IsRequired();
            entity.Property(e => e.CarrierName).HasMaxLength(100);
            entity.Property(e => e.TrackingNumber).HasMaxLength(100);
            entity.Property(e => e.TrackingUrl).HasMaxLength(500);

            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.CancellationReason).HasMaxLength(1000);
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            // Relationships
            entity.HasOne(e => e.Quotation)
                  .WithOne(q => q.Order)
                  .HasForeignKey<Order>(e => e.QuotationId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Orders_Quotations");

            entity.HasOne(e => e.Rfq)
                  .WithMany()
                  .HasForeignKey(e => e.RfqId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Orders_Rfqs");

            entity.HasOne(e => e.Product)
                  .WithMany(p => p.Orders)
                  .HasForeignKey(e => e.ProductId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Orders_Products");

            entity.HasOne(e => e.BuyerMember)
                  .WithMany(m => m.SentOrders)
                  .HasForeignKey(e => e.BuyerMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Orders_BuyerMember");

            entity.HasOne(e => e.SupplierMember)
                  .WithMany(m => m.ReceivedOrders)
                  .HasForeignKey(e => e.SupplierMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_Orders_SupplierMember");

            entity.HasIndex(e => e.OrderNumber).IsUnique().HasDatabaseName("IX_Orders_OrderNumber");
            entity.HasIndex(e => e.QuotationId).IsUnique().HasDatabaseName("IX_Orders_QuotationId");
            entity.HasIndex(e => e.RfqId).HasDatabaseName("IX_Orders_RfqId");
            entity.HasIndex(e => e.ProductId).HasDatabaseName("IX_Orders_ProductId");
            entity.HasIndex(e => e.BuyerMemberId).HasDatabaseName("IX_Orders_BuyerMemberId");
            entity.HasIndex(e => e.SupplierMemberId).HasDatabaseName("IX_Orders_SupplierMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_Orders_Status");
        });

        // 24. OrderStatusHistory
        modelBuilder.Entity<OrderStatusHistory>(entity =>
        {
            entity.ToTable("OrderStatusHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.OrderId).IsRequired();
            entity.Property(e => e.PreviousStatus).HasConversion<int?>();
            entity.Property(e => e.NewStatus).HasConversion<int>().IsRequired();
            entity.Property(e => e.ChangedByMemberId).IsRequired();
            entity.Property(e => e.ChangedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.Remarks).HasMaxLength(1000);

            entity.HasOne(e => e.Order)
                  .WithMany(o => o.StatusHistory)
                  .HasForeignKey(e => e.OrderId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_OrderStatusHistories_Orders");

            entity.HasOne(e => e.ChangedByMember)
                  .WithMany()
                  .HasForeignKey(e => e.ChangedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_OrderStatusHistories_ChangedByMember");

            entity.HasIndex(e => e.OrderId).HasDatabaseName("IX_OrderStatusHistories_OrderId");
            entity.HasIndex(e => e.ChangedByMemberId).HasDatabaseName("IX_OrderStatusHistories_ChangedByMemberId");
        });

        // 25. JobWorkRequirement
        modelBuilder.Entity<JobWorkRequirement>(entity =>
        {
            entity.ToTable("JobWorkRequirements");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.RequirementNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.OwnerMemberId).IsRequired();
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(3000).IsRequired();
            entity.Property(e => e.IndustryId).IsRequired();
            entity.Property(e => e.JobWorkProcess).HasMaxLength(100).IsRequired();
            entity.Property(e => e.MachineType).HasMaxLength(100);
            entity.Property(e => e.MachineCategory).HasMaxLength(100);
            entity.Property(e => e.RequiredMachineCapacity).HasMaxLength(150);
            entity.Property(e => e.TechnicalSpecifications).HasMaxLength(2000);
            entity.Property(e => e.RequiredTolerance).HasMaxLength(100);
            entity.Property(e => e.MaterialType).HasMaxLength(150);
            entity.Property(e => e.MaterialResponsibility).HasConversion<int>().IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.UnitOfMeasurement).HasMaxLength(50).IsRequired();
            entity.Property(e => e.TargetBudget).HasPrecision(18, 2);
            entity.Property(e => e.Location).HasMaxLength(200).IsRequired();
            entity.Property(e => e.DeliveryTerms).HasMaxLength(500);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.OwnerMember)
                  .WithMany(m => m.PostedJobWorkRequirements)
                  .HasForeignKey(e => e.OwnerMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkRequirements_OwnerMember");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkRequirements_Industries");

            entity.HasOne(e => e.BusinessGroup)
                  .WithMany()
                  .HasForeignKey(e => e.BusinessGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkRequirements_BusinessGroups");

            entity.HasOne(e => e.SubGroup)
                  .WithMany()
                  .HasForeignKey(e => e.SubGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkRequirements_SubGroups");

            entity.HasOne(e => e.Category)
                  .WithMany()
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkRequirements_Categories");

            entity.HasIndex(e => e.RequirementNumber).IsUnique().HasDatabaseName("IX_JobWorkRequirements_RequirementNumber");
            entity.HasIndex(e => e.OwnerMemberId).HasDatabaseName("IX_JobWorkRequirements_OwnerMemberId");
            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_JobWorkRequirements_IndustryId");
            entity.HasIndex(e => e.JobWorkProcess).HasDatabaseName("IX_JobWorkRequirements_JobWorkProcess");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_JobWorkRequirements_Status");
        });

        // 26. JobWorkAttachment
        modelBuilder.Entity<JobWorkAttachment>(entity =>
        {
            entity.ToTable("JobWorkAttachments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.OriginalFileName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.StoredFileName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.FileExtension).HasMaxLength(30).IsRequired();
            entity.Property(e => e.ContentType).HasMaxLength(100).IsRequired();
            entity.Property(e => e.FileSizeBytes).IsRequired();
            entity.Property(e => e.UploadedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.JobWorkRequirement)
                  .WithMany(r => r.Attachments)
                  .HasForeignKey(e => e.JobWorkRequirementId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkAttachments_JobWorkRequirements");

            entity.HasOne(e => e.JobWorkQuotation)
                  .WithMany(q => q.Attachments)
                  .HasForeignKey(e => e.JobWorkQuotationId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkAttachments_JobWorkQuotations");

            entity.HasOne(e => e.UploadedByMember)
                  .WithMany()
                  .HasForeignKey(e => e.UploadedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkAttachments_UploadedByMember");

            entity.HasIndex(e => e.JobWorkRequirementId).HasDatabaseName("IX_JobWorkAttachments_RequirementId");
            entity.HasIndex(e => e.JobWorkQuotationId).HasDatabaseName("IX_JobWorkAttachments_QuotationId");
        });

        // 27. JobWorkQuotation
        modelBuilder.Entity<JobWorkQuotation>(entity =>
        {
            entity.ToTable("JobWorkQuotations");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.QuotationNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.JobWorkRequirementId).IsRequired();
            entity.Property(e => e.ContractorMemberId).IsRequired();
            entity.Property(e => e.OfferedUnitPrice).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Subtotal).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TaxRatePercent).HasPrecision(5, 2).HasDefaultValue(18.00m).IsRequired();
            entity.Property(e => e.TaxAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.OtherCharges).HasPrecision(18, 2).HasDefaultValue(0.00m).IsRequired();
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.LeadTimeDays).IsRequired();
            entity.Property(e => e.MachineProposed).HasMaxLength(200);
            entity.Property(e => e.TechnicalRemarks).HasMaxLength(2000);
            entity.Property(e => e.TermsAndConditions).HasMaxLength(2000);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.RevisionNumber).HasDefaultValue(1).IsRequired();
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.RevisionNotes).HasMaxLength(1000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Requirement)
                  .WithMany(r => r.Quotations)
                  .HasForeignKey(e => e.JobWorkRequirementId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkQuotations_JobWorkRequirements");

            entity.HasOne(e => e.ContractorMember)
                  .WithMany(m => m.SubmittedJobWorkQuotations)
                  .HasForeignKey(e => e.ContractorMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkQuotations_ContractorMember");

            entity.HasIndex(e => e.QuotationNumber).IsUnique().HasDatabaseName("IX_JobWorkQuotations_QuotationNumber");
            entity.HasIndex(e => e.JobWorkRequirementId).HasDatabaseName("IX_JobWorkQuotations_RequirementId");
            entity.HasIndex(e => e.ContractorMemberId).HasDatabaseName("IX_JobWorkQuotations_ContractorMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_JobWorkQuotations_Status");
        });

        // 28. JobWorkOrder
        modelBuilder.Entity<JobWorkOrder>(entity =>
        {
            entity.ToTable("JobWorkOrders");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.OrderNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.JobWorkRequirementId).IsRequired();
            entity.Property(e => e.JobWorkQuotationId).IsRequired();
            entity.Property(e => e.BuyerMemberId).IsRequired();
            entity.Property(e => e.ContractorMemberId).IsRequired();
            entity.Property(e => e.JobTitle).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Process).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.UnitOfMeasurement).HasMaxLength(50).IsRequired();
            entity.Property(e => e.AgreedUnitPrice).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.Subtotal).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TaxAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.OtherCharges).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2).IsRequired();
            entity.Property(e => e.LeadTimeDays).IsRequired();
            entity.Property(e => e.DeliveryLocation).HasMaxLength(300).IsRequired();
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.CancellationReason).HasMaxLength(1000);
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Requirement)
                  .WithOne(r => r.Order)
                  .HasForeignKey<JobWorkOrder>(e => e.JobWorkRequirementId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkOrders_JobWorkRequirements");

            entity.HasOne(e => e.Quotation)
                  .WithOne(q => q.Order)
                  .HasForeignKey<JobWorkOrder>(e => e.JobWorkQuotationId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkOrders_JobWorkQuotations");

            entity.HasOne(e => e.BuyerMember)
                  .WithMany(m => m.PlacedJobWorkOrders)
                  .HasForeignKey(e => e.BuyerMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkOrders_BuyerMember");

            entity.HasOne(e => e.ContractorMember)
                  .WithMany(m => m.ReceivedJobWorkOrders)
                  .HasForeignKey(e => e.ContractorMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkOrders_ContractorMember");

            entity.HasIndex(e => e.OrderNumber).IsUnique().HasDatabaseName("IX_JobWorkOrders_OrderNumber");
            entity.HasIndex(e => e.JobWorkRequirementId).HasDatabaseName("IX_JobWorkOrders_RequirementId");
            entity.HasIndex(e => e.JobWorkQuotationId).IsUnique().HasDatabaseName("IX_JobWorkOrders_QuotationId");
            entity.HasIndex(e => e.BuyerMemberId).HasDatabaseName("IX_JobWorkOrders_BuyerMemberId");
            entity.HasIndex(e => e.ContractorMemberId).HasDatabaseName("IX_JobWorkOrders_ContractorMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_JobWorkOrders_Status");
        });

        // 29. JobWorkOrderStatusHistory
        modelBuilder.Entity<JobWorkOrderStatusHistory>(entity =>
        {
            entity.ToTable("JobWorkOrderStatusHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.JobWorkOrderId).IsRequired();
            entity.Property(e => e.PreviousStatus).HasConversion<int?>();
            entity.Property(e => e.NewStatus).HasConversion<int>().IsRequired();
            entity.Property(e => e.ChangedByMemberId).IsRequired();
            entity.Property(e => e.ChangedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.Remarks).HasMaxLength(1000);

            entity.HasOne(e => e.Order)
                  .WithMany(o => o.StatusHistory)
                  .HasForeignKey(e => e.JobWorkOrderId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_JobWorkOrderStatusHistories_JobWorkOrders");

            entity.HasOne(e => e.ChangedByMember)
                  .WithMany()
                  .HasForeignKey(e => e.ChangedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobWorkOrderStatusHistories_ChangedByMember");

            entity.HasIndex(e => e.JobWorkOrderId).HasDatabaseName("IX_JobWorkOrderStatusHistories_OrderId");
            entity.HasIndex(e => e.ChangedByMemberId).HasDatabaseName("IX_JobWorkOrderStatusHistories_ChangedByMemberId");
        });

        // 26. AccountDeletionRequest
        modelBuilder.Entity<AccountDeletionRequest>(entity =>
        {
            entity.ToTable("AccountDeletionRequests");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Reason).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(32).IsRequired().HasDefaultValue("PendingReview");
            entity.Property(e => e.RequestedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");
            entity.Property(e => e.AdminNotes).HasMaxLength(1000);

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.DeletionRequests)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_AccountDeletionRequests_Members");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_AccountDeletionRequests_MemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_AccountDeletionRequests_Status");
        });

        // 30. BusinessService
        modelBuilder.Entity<BusinessService>(entity =>
        {
            entity.ToTable("BusinessServices");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(4000).IsRequired();
            entity.Property(e => e.ServiceCategory).HasMaxLength(100).IsRequired();
            entity.Property(e => e.ServiceType).HasMaxLength(50).IsRequired().HasDefaultValue("On-Site");
            entity.Property(e => e.PricingModel).HasMaxLength(50).IsRequired().HasDefaultValue("Quote-Based");
            entity.Property(e => e.StartingPrice).HasPrecision(18, 2);
            entity.Property(e => e.PriceUnit).HasMaxLength(50);
            entity.Property(e => e.TurnaroundTime).HasMaxLength(100);
            entity.Property(e => e.CoverageArea).HasMaxLength(200);
            entity.Property(e => e.Location).HasMaxLength(200);
            entity.Property(e => e.TagsJson).HasMaxLength(1000);
            entity.Property(e => e.ImagesJson).HasMaxLength(2000);
            entity.Property(e => e.Certifications).HasMaxLength(500);
            entity.Property(e => e.IsActive).IsRequired().HasDefaultValue(true);
            entity.Property(e => e.ViewCount).IsRequired().HasDefaultValue(0);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.PublishedServices)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessServices_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.SetNull)
                  .HasConstraintName("FK_BusinessServices_Industries");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_BusinessServices_MemberId");
            entity.HasIndex(e => e.ServiceCategory).HasDatabaseName("IX_BusinessServices_Category");
            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_BusinessServices_IndustryId");
            entity.HasIndex(e => e.IsActive).HasDatabaseName("IX_BusinessServices_IsActive");
            entity.HasIndex(e => e.Location).HasDatabaseName("IX_BusinessServices_Location");
        });

        // 31. ServiceInquiry
        modelBuilder.Entity<ServiceInquiry>(entity =>
        {
            entity.ToTable("ServiceInquiries");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.InquiryNumber).HasMaxLength(64).IsRequired();
            entity.Property(e => e.ServiceId).IsRequired();
            entity.Property(e => e.SenderMemberId).IsRequired();
            entity.Property(e => e.RecipientMemberId).IsRequired();
            entity.Property(e => e.Subject).HasMaxLength(200).IsRequired();
            entity.Property(e => e.RequirementDescription).HasMaxLength(4000).IsRequired();
            entity.Property(e => e.ScopeOfWork).HasMaxLength(2000);
            entity.Property(e => e.Location).HasMaxLength(200);
            entity.Property(e => e.EstimatedBudget).HasPrecision(18, 2);
            entity.Property(e => e.Urgency).HasMaxLength(50).IsRequired().HasDefaultValue("Normal");
            entity.Property(e => e.Status).HasConversion<int>().IsRequired().HasDefaultValue(ServiceInquiryStatus.Pending);
            entity.Property(e => e.ResponseMessage).HasMaxLength(4000);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Service)
                  .WithMany(s => s.Inquiries)
                  .HasForeignKey(e => e.ServiceId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ServiceInquiries_BusinessServices");

            entity.HasOne(e => e.SenderMember)
                  .WithMany(m => m.SentServiceInquiries)
                  .HasForeignKey(e => e.SenderMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ServiceInquiries_SenderMember");

            entity.HasOne(e => e.RecipientMember)
                  .WithMany(m => m.ReceivedServiceInquiries)
                  .HasForeignKey(e => e.RecipientMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ServiceInquiries_RecipientMember");

            entity.HasIndex(e => e.InquiryNumber).IsUnique().HasDatabaseName("IX_ServiceInquiries_InquiryNumber");
            entity.HasIndex(e => e.ServiceId).HasDatabaseName("IX_ServiceInquiries_ServiceId");
            entity.HasIndex(e => e.SenderMemberId).HasDatabaseName("IX_ServiceInquiries_SenderMemberId");
            entity.HasIndex(e => e.RecipientMemberId).HasDatabaseName("IX_ServiceInquiries_RecipientMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_ServiceInquiries_Status");
        });

        // 32. ServiceInquiryStatusHistory
        modelBuilder.Entity<ServiceInquiryStatusHistory>(entity =>
        {
            entity.ToTable("ServiceInquiryStatusHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.ServiceInquiryId).IsRequired();
            entity.Property(e => e.PreviousStatus).HasConversion<int?>();
            entity.Property(e => e.NewStatus).HasConversion<int>().IsRequired();
            entity.Property(e => e.ChangedByMemberId).IsRequired();
            entity.Property(e => e.Remarks).HasMaxLength(1000);
            entity.Property(e => e.ChangedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.ServiceInquiry)
                  .WithMany(i => i.StatusHistory)
                  .HasForeignKey(e => e.ServiceInquiryId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_ServiceInquiryStatusHistories_Inquiries");

            entity.HasOne(e => e.ChangedByMember)
                  .WithMany()
                  .HasForeignKey(e => e.ChangedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_ServiceInquiryStatusHistories_ChangedByMember");

            entity.HasIndex(e => e.ServiceInquiryId).HasDatabaseName("IX_ServiceInquiryStatusHistories_InquiryId");
            entity.HasIndex(e => e.ChangedByMemberId).HasDatabaseName("IX_ServiceInquiryStatusHistories_ChangedByMemberId");
        });

        // 33. JobOpening
        modelBuilder.Entity<JobOpening>(entity =>
        {
            entity.ToTable("JobOpenings");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(4000).IsRequired();
            entity.Property(e => e.Department).HasMaxLength(100);
            entity.Property(e => e.JobType).HasMaxLength(50).IsRequired().HasDefaultValue("Full-time");
            entity.Property(e => e.WorkplaceType).HasMaxLength(50).IsRequired().HasDefaultValue("On-site");
            entity.Property(e => e.City).HasMaxLength(100).IsRequired();
            entity.Property(e => e.State).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.MinExperienceYears).HasDefaultValue(0);
            entity.Property(e => e.MinSalary).HasPrecision(18, 2);
            entity.Property(e => e.MaxSalary).HasPrecision(18, 2);
            entity.Property(e => e.SalaryPeriod).HasMaxLength(50).IsRequired().HasDefaultValue("Per Month");
            entity.Property(e => e.RequiredSkillsJson).HasMaxLength(2000);
            entity.Property(e => e.EducationRequirements).HasMaxLength(200);
            entity.Property(e => e.OpeningsCount).HasDefaultValue(1);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired().HasDefaultValue(JobOpeningStatus.Open);
            entity.Property(e => e.ViewCount).HasDefaultValue(0);
            entity.Property(e => e.ApplicationsCount).HasDefaultValue(0);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.PostedJobOpenings)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobOpenings_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobOpenings_Industries");

            entity.HasOne(e => e.BusinessGroup)
                  .WithMany()
                  .HasForeignKey(e => e.BusinessGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobOpenings_BusinessGroups");

            entity.HasOne(e => e.SubGroup)
                  .WithMany()
                  .HasForeignKey(e => e.SubGroupId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobOpenings_SubGroups");

            entity.HasOne(e => e.Category)
                  .WithMany()
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobOpenings_Categories");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_JobOpenings_MemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_JobOpenings_Status");
            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_JobOpenings_IndustryId");
            entity.HasIndex(e => e.City).HasDatabaseName("IX_JobOpenings_City");
            entity.HasIndex(e => e.CreatedAtUtc).HasDatabaseName("IX_JobOpenings_CreatedAtUtc");
        });

        // 34. JobApplication
        modelBuilder.Entity<JobApplication>(entity =>
        {
            entity.ToTable("JobApplications");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.ApplicationNumber).HasMaxLength(64).IsRequired();
            entity.Property(e => e.JobOpeningId).IsRequired();
            entity.Property(e => e.ApplicantMemberId).IsRequired();
            entity.Property(e => e.FullName).HasMaxLength(150).IsRequired();
            entity.Property(e => e.Email).HasMaxLength(150).IsRequired();
            entity.Property(e => e.Phone).HasMaxLength(50).IsRequired();
            entity.Property(e => e.CurrentCompany).HasMaxLength(150);
            entity.Property(e => e.CurrentDesignation).HasMaxLength(150);
            entity.Property(e => e.YearsOfExperience).HasDefaultValue(0);
            entity.Property(e => e.ExpectedSalary).HasPrecision(18, 2);
            entity.Property(e => e.CoverLetter).HasMaxLength(4000);
            entity.Property(e => e.ResumeUrl).HasMaxLength(1000);
            entity.Property(e => e.ResumeFileName).HasMaxLength(255);
            entity.Property(e => e.EmployerNotes).HasMaxLength(2000);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired().HasDefaultValue(JobApplicationStatus.Submitted);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.JobOpening)
                  .WithMany(j => j.Applications)
                  .HasForeignKey(e => e.JobOpeningId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobApplications_JobOpenings");

            entity.HasOne(e => e.ApplicantMember)
                  .WithMany(m => m.SubmittedJobApplications)
                  .HasForeignKey(e => e.ApplicantMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobApplications_ApplicantMembers");

            entity.HasIndex(e => e.ApplicationNumber).IsUnique().HasDatabaseName("IX_JobApplications_ApplicationNumber");
            entity.HasIndex(e => e.JobOpeningId).HasDatabaseName("IX_JobApplications_JobOpeningId");
            entity.HasIndex(e => e.ApplicantMemberId).HasDatabaseName("IX_JobApplications_ApplicantMemberId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_JobApplications_Status");
            entity.HasIndex(e => new { e.JobOpeningId, e.ApplicantMemberId }).HasDatabaseName("IX_JobApplications_Job_Applicant");
        });

        // 35. JobApplicationAttachment
        modelBuilder.Entity<JobApplicationAttachment>(entity =>
        {
            entity.ToTable("JobApplicationAttachments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.JobApplicationId).IsRequired();
            entity.Property(e => e.FileName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.FilePath).HasMaxLength(1000).IsRequired();
            entity.Property(e => e.ContentType).HasMaxLength(100).IsRequired();
            entity.Property(e => e.UploadedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.JobApplication)
                  .WithMany(a => a.Attachments)
                  .HasForeignKey(e => e.JobApplicationId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_JobApplicationAttachments_Applications");

            entity.HasIndex(e => e.JobApplicationId).HasDatabaseName("IX_JobApplicationAttachments_ApplicationId");
        });

        // 36. JobApplicationStatusHistory
        modelBuilder.Entity<JobApplicationStatusHistory>(entity =>
        {
            entity.ToTable("JobApplicationStatusHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.JobApplicationId).IsRequired();
            entity.Property(e => e.PreviousStatus).HasConversion<int?>();
            entity.Property(e => e.NewStatus).HasConversion<int>().IsRequired();
            entity.Property(e => e.ChangedByMemberId).IsRequired();
            entity.Property(e => e.Remarks).HasMaxLength(1000);
            entity.Property(e => e.ChangedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.JobApplication)
                  .WithMany(a => a.StatusHistory)
                  .HasForeignKey(e => e.JobApplicationId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_JobApplicationStatusHistories_Applications");

            entity.HasOne(e => e.ChangedByMember)
                  .WithMany()
                  .HasForeignKey(e => e.ChangedByMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_JobApplicationStatusHistories_ChangedByMember");

            entity.HasIndex(e => e.JobApplicationId).HasDatabaseName("IX_JobApplicationStatusHistories_ApplicationId");
            entity.HasIndex(e => e.ChangedByMemberId).HasDatabaseName("IX_JobApplicationStatusHistories_ChangedByMemberId");
        });

        // 37. BusinessPost
        modelBuilder.Entity<BusinessPost>(entity =>
        {
            entity.ToTable("BusinessPosts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Content).HasMaxLength(4000).IsRequired();
            entity.Property(e => e.LikeCount).HasDefaultValue(0);
            entity.Property(e => e.CommentCount).HasDefaultValue(0);
            entity.Property(e => e.IsEdited).HasDefaultValue(false);
            entity.Property(e => e.IsDeleted).HasDefaultValue(false);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.BusinessPosts)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPosts_Members");

            entity.HasOne(e => e.Industry)
                  .WithMany()
                  .HasForeignKey(e => e.IndustryId)
                  .OnDelete(DeleteBehavior.SetNull)
                  .HasConstraintName("FK_BusinessPosts_Industries");

            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_BusinessPosts_MemberId");
            entity.HasIndex(e => e.IndustryId).HasDatabaseName("IX_BusinessPosts_IndustryId");
            entity.HasIndex(e => e.CreatedAtUtc).HasDatabaseName("IX_BusinessPosts_CreatedAtUtc");
            entity.HasIndex(e => e.IsDeleted).HasDatabaseName("IX_BusinessPosts_IsDeleted");
        });

        // 38. BusinessPostAttachment
        modelBuilder.Entity<BusinessPostAttachment>(entity =>
        {
            entity.ToTable("BusinessPostAttachments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.PostId).IsRequired();
            entity.Property(e => e.MediaUrl).HasMaxLength(1000).IsRequired();
            entity.Property(e => e.MediaType).HasMaxLength(50);
            entity.Property(e => e.DisplayOrder).HasDefaultValue(0);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Post)
                  .WithMany(p => p.Attachments)
                  .HasForeignKey(e => e.PostId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessPostAttachments_Posts");

            entity.HasIndex(e => e.PostId).HasDatabaseName("IX_BusinessPostAttachments_PostId");
        });

        // 39. BusinessPostLike
        modelBuilder.Entity<BusinessPostLike>(entity =>
        {
            entity.ToTable("BusinessPostLikes");
            entity.HasKey(e => new { e.PostId, e.MemberId });
            entity.Property(e => e.LikedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Post)
                  .WithMany(p => p.Likes)
                  .HasForeignKey(e => e.PostId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessPostLikes_Posts");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.PostLikes)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPostLikes_Members");

            entity.HasIndex(e => e.PostId).HasDatabaseName("IX_BusinessPostLikes_PostId");
            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_BusinessPostLikes_MemberId");
        });

        // 40. BusinessPostComment
        modelBuilder.Entity<BusinessPostComment>(entity =>
        {
            entity.ToTable("BusinessPostComments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.PostId).IsRequired();
            entity.Property(e => e.MemberId).IsRequired();
            entity.Property(e => e.Content).HasMaxLength(2000).IsRequired();
            entity.Property(e => e.IsEdited).HasDefaultValue(false);
            entity.Property(e => e.IsDeleted).HasDefaultValue(false);
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.Post)
                  .WithMany(p => p.Comments)
                  .HasForeignKey(e => e.PostId)
                  .OnDelete(DeleteBehavior.Cascade)
                  .HasConstraintName("FK_BusinessPostComments_Posts");

            entity.HasOne(e => e.Member)
                  .WithMany(m => m.PostComments)
                  .HasForeignKey(e => e.MemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPostComments_Members");

            entity.HasIndex(e => e.PostId).HasDatabaseName("IX_BusinessPostComments_PostId");
            entity.HasIndex(e => e.MemberId).HasDatabaseName("IX_BusinessPostComments_MemberId");
            entity.HasIndex(e => e.CreatedAtUtc).HasDatabaseName("IX_BusinessPostComments_CreatedAtUtc");
        });

        // 41. BusinessPostReport
        modelBuilder.Entity<BusinessPostReport>(entity =>
        {
            entity.ToTable("BusinessPostReports");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.ReporterMemberId).IsRequired();
            entity.Property(e => e.Reason).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Details).HasMaxLength(1000);
            entity.Property(e => e.Status).HasConversion<int>().IsRequired();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

            entity.HasOne(e => e.ReporterMember)
                  .WithMany(m => m.PostReports)
                  .HasForeignKey(e => e.ReporterMemberId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPostReports_Members");

            entity.HasOne(e => e.Post)
                  .WithMany(p => p.Reports)
                  .HasForeignKey(e => e.PostId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPostReports_Posts");

            entity.HasOne(e => e.Comment)
                  .WithMany(c => c.Reports)
                  .HasForeignKey(e => e.CommentId)
                  .OnDelete(DeleteBehavior.Restrict)
                  .HasConstraintName("FK_BusinessPostReports_Comments");

            entity.HasIndex(e => e.ReporterMemberId).HasDatabaseName("IX_BusinessPostReports_ReporterMemberId");
            entity.HasIndex(e => e.PostId).HasDatabaseName("IX_BusinessPostReports_PostId");
            entity.HasIndex(e => e.CommentId).HasDatabaseName("IX_BusinessPostReports_CommentId");
            entity.HasIndex(e => e.Status).HasDatabaseName("IX_BusinessPostReports_Status");
        });
    }
}