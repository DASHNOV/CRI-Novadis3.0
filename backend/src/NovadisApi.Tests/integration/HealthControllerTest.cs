using System.Net;
using System.Text.Json;
using FluentAssertions;

namespace NovadisApi.Tests.Integration;

public class HealthControllerTests : IClassFixture<NovadisWebApplicationFactory>
{
    private readonly HttpClient _client;

    public HealthControllerTests(NovadisWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Live_ReturnsOk_WithAliveStatus()
    {
        // Act
        var response = await _client.GetAsync("/api/health/live");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("status").GetString().Should().Be("alive");
    }

    [Fact]
    public async Task Get_WithInMemoryDb_ReturnsHealthy()
    {
        // Act
        var response = await _client.GetAsync("/api/health");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("status").GetString().Should().Be("healthy");
    }

    [Fact]
    public async Task Stats_WithEmptyDb_ReturnsZeroCounts()
    {
        // Act
        var response = await _client.GetAsync("/api/health/stats");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("users").GetInt32().Should().Be(0);
        json.GetProperty("criForms").GetInt32().Should().Be(0);
    }
}