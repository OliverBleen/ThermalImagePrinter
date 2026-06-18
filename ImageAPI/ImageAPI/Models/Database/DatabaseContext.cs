using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ImageAPI.Models.Database;

public partial class DatabaseContext : DbContext
{
    public DatabaseContext()
    {
    }

    public DatabaseContext(DbContextOptions<DatabaseContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Album> Albums { get; set; }

    public virtual DbSet<ApiKey> ApiKeys { get; set; }

    public virtual DbSet<Image> Images { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseSqlite($"Filename={Path.Combine(Program.BASE_DIR, "Database.sqlite3")}");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Album>(entity =>
        {
            entity.HasKey(e => e.Title);
        });

        modelBuilder.Entity<ApiKey>(entity =>
        {
            entity.HasKey(e => e.Key);

            entity.Property(e => e.Key)
                .ValueGeneratedNever()
                .HasColumnType("TEXT(36)");
            entity.Property(e => e.AccessTo).HasColumnType("TEXT(255)");
            entity.Property(e => e.Comment).HasColumnType("TEXT(255)");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity.Property(e => e.Id).HasColumnType("TEXT(36)");

            entity.HasOne(d => d.AlbumTitleNavigation).WithMany(p => p.Images)
                .HasForeignKey(d => d.AlbumTitle)
                .OnDelete(DeleteBehavior.ClientSetNull);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
