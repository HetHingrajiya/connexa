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

            entity.HasIndex(e => e.PhoneNumber).IsUnique().HasDatabaseName("IX_Members_PhoneNumber");
            entity.HasIndex(e => e.Email).IsUnique().HasDatabaseName("IX_Members_Email");
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
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("SYSUTCDATETIME()");

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
    }
}