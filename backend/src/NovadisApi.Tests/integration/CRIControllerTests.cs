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
    
  // ─── Test 5 : technicien B ne peut pas lire le CRI de technicien A → 403 ──

  [Fact]
  public async Task GetCRI_OtherTechnicianCRI_Returns403()
  {
      // Technicien A crée un CRI
      var clientA = CreateAuthenticatedClient();
      var newCri = new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI de A",
      };
      var createResponse = await clientA.PostAsJsonAsync("/api/cri", newCri);
      createResponse.StatusCode.Should().Be(HttpStatusCode.Created);

      var createBody = await createResponse.Content.ReadAsStringAsync();
      var criId = JsonDocument.Parse(createBody).RootElement
          .GetProperty("data").GetProperty("id").GetString();

      // Technicien B essaie de lire ce CRI
      var technicianBId = Guid.NewGuid();
      var clientB = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(clientB, technicianBId);

      var response = await clientB.GetAsync($"/api/cri/{criId}");

      response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
  }

  // ─── Test 6 : un admin voit les CRI de tous les techniciens → 200 ─────────

  [Fact]
  public async Task GetMyCRIs_AsAdmin_ReturnsAllCRIs()
  {
      // Technicien A crée un CRI
      var clientA = CreateAuthenticatedClient();
      await clientA.PostAsJsonAsync("/api/cri", new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI de A",
      });

      // Technicien B crée un CRI
      var technicianBId = Guid.NewGuid();
      var clientB = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(clientB, technicianBId);
      await clientB.PostAsJsonAsync("/api/cri", new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI de B",
      });

      // L'admin récupère tous les CRI
      var adminId = Guid.NewGuid();
      var adminClient = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(adminClient, adminId, role: "Admin");

      var response = await adminClient.GetAsync("/api/cri");

      response.StatusCode.Should().Be(HttpStatusCode.OK);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      json.GetProperty("data").GetArrayLength().Should().BeGreaterThanOrEqualTo(2);
  }

  // ─── Test 7 : un technicien ne voit que ses propres CRI dans la liste ──────

  [Fact]
  public async Task GetMyCRIs_AsTechnician_ReturnsOnlyOwnCRIs()
  {
      var technicianAId = Guid.NewGuid();
      var clientA = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(clientA, technicianAId);

      // Technicien A crée 2 CRI
      await clientA.PostAsJsonAsync("/api/cri", new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI A1",
      });
      await clientA.PostAsJsonAsync("/api/cri", new CRIForm
      {
          InterventionType = "Projet",
          Category = "Installation",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI A2",
      });

      // Technicien B crée 1 CRI
      var technicianBId = Guid.NewGuid();
      var clientB = _factory.CreateClient();
      TestAuthHelper.CreateAuthenticatedClient(clientB, technicianBId);
      await clientB.PostAsJsonAsync("/api/cri", new CRIForm
      {
          InterventionType = "Service",
          Category = "Maintenance",
          InterventionDate = DateTime.UtcNow,
          ClientName = "CRI B1",
      });

      // Technicien A ne doit voir que ses 2 CRI
      var response = await clientA.GetAsync("/api/cri");

      response.StatusCode.Should().Be(HttpStatusCode.OK);

      var body = await response.Content.ReadAsStringAsync();
      var json = JsonDocument.Parse(body).RootElement;
      var data = json.GetProperty("data");
      data.GetArrayLength().Should().Be(2);

      // Vérifier qu'aucun CRI de B n'est dans la liste
      var clientNames = data.EnumerateArray()
          .Select(c => c.GetProperty("clientName").GetString())
          .ToList();
      clientNames.Should().NotContain("CRI B1");
  }
}