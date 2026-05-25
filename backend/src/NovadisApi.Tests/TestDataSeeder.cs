using Microsoft.Extensions.DependencyInjection;
using NovadisApi.Data;
using NovadisApi.Models;

namespace NovadisApi.Tests;

public static class TestDataSeeder
{
    public static async Task<User> SeedUserAsync(
        NovadisWebApplicationFactory factory,
        Guid userId,
        string email = "test@novadis.fr",
        string role = "Technician")
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<NovadisDbContext>();

        var user = new User
        {
            Id = userId,
            Email = email,
            PasswordHash = "not-used-in-tests",
            Role = role,
            FirstName = "Test",
            LastName = "User",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };

        db.Users.Add(user);
        await db.SaveChangesAsync();

        return user;
    }
}