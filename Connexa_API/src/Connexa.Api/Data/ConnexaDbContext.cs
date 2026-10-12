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

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1. Industry
        modelBuilder.Entity<Industry>(entity =>
        {
            entity.ToTable("Industries");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasMaxLength(50).IsRequired();
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
            entity.Property(e => e.Id).HasMaxLength(50).IsRequired();
            entity.Property(e => e.IndustryId).HasMaxLength(50).IsRequired();
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
            entity.Property(e => e.Id).HasMaxLength(50).IsRequired();
            entity.Property(e => e.BusinessGroupId).HasMaxLength(50).IsRequired();
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
            entity.Property(e => e.Id).HasMaxLength(50).IsRequired();
            entity.Property(e => e.SubGroupId).HasMaxLength(50).IsRequired();
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
    }
}