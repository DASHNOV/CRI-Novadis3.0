using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using NovadisApi.Models;

namespace NovadisApi.Tests.Integration;

public class CRIControllerTests : IClassFixture<NovadisWebApplicationFactory>
{
  private readonly NovadisWebApplicationFactory _factory;
  private readonly Guid _testUserId = Guid.NewGuid();

  public CRIControllerTests(NovadisWebApplicationFactory factory)
  {
      _factory = factory;
  }

  private HttpClient CreateAuthenticatedClient()
  {
      var client = _factory.CreateClient();
      return TestAuthHelper.CreateAuthenticatedClient(client, _testUserId);
  }

  // ─── Test 1 : sans token → 401 ───────────────────────────────────────────

  [Fact]
  public async Task GetMyCRIs_WithoutToken_Returns401()
  {
      var client = _factory.CreateClient();

      var response = await client.GetAsync("/api/cri");

      response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
  }

  // ─── Test 2 : liste vide → 200 + tableau vide ────────────────────────────

  [Fact]
  public async Task GetMyCRIs_WithToken_EmptyDb_Returns200AndEmptyList()
  {
      var client = CreateAuthenticatedClient();

      var response = await client.GetAsync("/api/cri");

      response.StatusCode.Should().Be(HttpStatusCode.OK);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("success").GetBoolean().Should().BeTrue();
      json.GetProperty("data").GetArrayLength().Should().Be(0);
  }

  // ─── Test 3 : créer un CRI → 201 + données correctes ─────────────────────

  [Fact]
  public async Task CreateCRI_WithValidData_Returns201AndCreatedCRI()
  {
      var client = CreateAuthenticatedClient();

      var newCri = new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "Client Test",
      };

      var response = await client.PostAsJsonAsync("/api/cri", newCri);

      response.StatusCode.Should().Be(HttpStatusCode.Created);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("success").GetBoolean().Should().BeTrue();
      json.GetProperty("data").GetProperty("clientName").GetString().Should().Be("Client Test");
  }

  // ─── Test 4 : CRI inexistant → 404 ───────────────────────────────────────

  [Fact]
  public async Task GetCRI_WithUnknownId_Returns404()
  {
      var client = CreateAuthenticatedClient();
      var unknownId = Guid.NewGuid();

      var response = await client.GetAsync($"/api/cri/{unknownId}");

      response.StatusCode.Should().Be(HttpStatusCode.NotFound);
  }
}