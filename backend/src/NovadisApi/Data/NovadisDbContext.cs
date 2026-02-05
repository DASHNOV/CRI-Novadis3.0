using Microsoft.EntityFrameworkCore;
using NovadisApi.Models;

namespace NovadisApi.Data
{
    public class NovadisDbContext : DbContext
    {
        public NovadisDbContext(DbContextOptions<NovadisDbContext> options)
            : base(options)
        {
        }

        // Tables existantes
        public DbSet<User> Users { get; set; }
        public DbSet<CRIForm> CRIForms { get; set; }
        public DbSet<CRIPhoto> CRIPhotos { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }

        // ✨ NOUVELLES TABLES pour l'authentification
        public DbSet<AuthAttempt> AuthAttempts { get; set; }
        public DbSet<UserToken> UserTokens { get; set; }
        public DbSet<MagicLink> MagicLinks { get; set; } // Pour Phase 2

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configuration User
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
                entity.Property(e => e.FirstName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.LastName).IsRequired().HasMaxLength(100);
            });

            // Configuration AuthAttempt
            modelBuilder.Entity<AuthAttempt>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email);
                entity.HasIndex(e => new { e.Email, e.CreatedAt });
                entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
                entity.Property(e => e.CodeHash).IsRequired();
            });

            // Configuration UserToken
            modelBuilder.Entity<UserToken>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.RefreshToken).IsUnique();
                entity.HasIndex(e => e.UserId);
                entity.Property(e => e.RefreshToken).IsRequired();
                
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configuration MagicLink (Phase 2)
            modelBuilder.Entity<MagicLink>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Token).IsUnique();
                entity.HasIndex(e => e.Email);
                entity.Property(e => e.Token).IsRequired();
                entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            });

            // Configuration CRIForm
            modelBuilder.Entity<CRIForm>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.TechnicianId);
                entity.HasIndex(e => e.CreatedAt);
                
                entity.HasOne(e => e.Technician)
                    .WithMany(u => u.CRIForms)
                    .HasForeignKey(e => e.TechnicianId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.Property(e => e.Duration).HasPrecision(18, 2);
            });

            // Configuration CRIPhoto
            modelBuilder.Entity<CRIPhoto>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.CRIFormId);
                
                entity.HasOne(e => e.CRIForm)
                    .WithMany(c => c.Photos)
                    .HasForeignKey(e => e.CRIFormId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configuration AuditLog
            modelBuilder.Entity<AuditLog>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => e.CreatedAt);
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.AuditLogs)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Seed Data (utilisateurs de test)
            SeedData(modelBuilder);
        }

        private void SeedData(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = Guid.Parse("a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"),
                    Email = "admin@novadis.local",
                    FirstName = "Admin",
                    LastName = "Système",
                    Role = "Admin",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CRIForms = null, // Fix for EF Core Seeding
                    AuditLogs = null // Fix for EF Core Seeding
                },
                new User
                {
                    Id = Guid.Parse("b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e"),
                    Email = "technicien@novadis.local",
                    FirstName = "Jean",
                    LastName = "Dupont",
                    Role = "Technician",
                    PhoneNumber = "0612345678",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CRIForms = null, // Fix for EF Core Seeding
                    AuditLogs = null // Fix for EF Core Seeding
                }
            );
        }
    }
}
