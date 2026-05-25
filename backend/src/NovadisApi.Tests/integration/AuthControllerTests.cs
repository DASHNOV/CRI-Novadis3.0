using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Tests.Integration;

public class AuthControllerTests : IClassFixture<NovadisWebApplicationFactory>
{
  private readonly NovadisWebApplicationFactory _factory;
  private readonly Guid _testUserId = Guid.NewGuid();
  private const string TestEmail = "auth-test@novadis.fr";

  public AuthControllerTests(NovadisWebApplicationFactory factory)
  {
      _factory = factory;
  }

  // ─── Test 1 : GET /api/auth/me sans token → 401 ──────────────────────────

  [Fact]
  public async Task GetMe_WithoutToken_Returns401()
  {
      var client = _factory.CreateClient();

      var response = await client.GetAsync("/api/auth/me");

      response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
  }

  // ─── Test 2 : GET /api/auth/me avec token valide → 200 ───────────────────

  [Fact]
  public async Task GetMe_WithValidToken_Returns200AndUserInfo()
  {
      await TestDataSeeder.SeedUserAsync(_factory, _testUserId, TestEmail);

      var client = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(client, _testUserId);

      var response = await client.GetAsync("/api/auth/me");

      response.StatusCode.Should().Be(HttpStatusCode.OK);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("success").GetBoolean().Should().BeTrue();
      json.GetProperty("data").GetProperty("email").GetString().Should().Be(TestEmail);
  }

  // ─── Test 3 : POST /api/auth/login email inconnu → 400 ───────────────────

  [Fact]
  public async Task Login_WithUnknownEmail_Returns400()
  {
      var client = _factory.CreateClient();

      var request = new LoginRequestDto { Email = "inconnu@novadis.fr" };
      var response = await client.PostAsJsonAsync("/api/auth/login", request);

      response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("success").GetBoolean().Should().BeFalse();
  }

  // ─── Test 4 : POST /api/auth/login email connu → 200 ─────────────────────

  [Fact]
  public async Task Login_WithKnownEmail_Returns200AndExpiresIn()
  {
      await TestDataSeeder.SeedUserAsync(_factory, _testUserId, TestEmail);

      var client = _factory.CreateClient();
      var request = new LoginRequestDto { Email = TestEmail };
      var response = await client.PostAsJsonAsync("/api/auth/login", request);

      response.StatusCode.Should().Be(HttpStatusCode.OK);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("success").GetBoolean().Should().BeTrue();
      json.GetProperty("data").GetProperty("expiresIn").GetInt32().Should().BeGreaterThan(0);
  }
}