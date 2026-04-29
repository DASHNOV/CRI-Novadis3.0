using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using NovadisApi.Middleware;

namespace NovadisApi.Tests.Middleware;

internal sealed class FakeHostEnv : IHostEnvironment
{
    public string EnvironmentName { get; set; } = Environments.Production;
    public string ApplicationName { get; set; } = "NovadisApi.Tests";
    public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
    public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
}

public class GlobalExceptionHandlerTests
{
    private static (DefaultHttpContext ctx, MemoryStream body) MakeContext()
    {
        var ctx = new DefaultHttpContext();
        var body = new MemoryStream();
        ctx.Response.Body = body;
        return (ctx, body);
    }

    private static IHostEnvironment ProdEnv() =>
        new FakeHostEnv { EnvironmentName = Environments.Production };

    [Theory]
    [InlineData(typeof(UnauthorizedAccessException), 401)]
    [InlineData(typeof(KeyNotFoundException), 404)]
    [InlineData(typeof(ArgumentException), 400)]
    [InlineData(typeof(InvalidOperationException), 400)]
    [InlineData(typeof(Exception), 500)]
    public async Task TryHandleAsync_MapsExceptionToCorrectStatus(Type exType, int expectedStatus)
    {
        var sut = new GlobalExceptionHandler(NullLogger<GlobalExceptionHandler>.Instance, ProdEnv());
        var (ctx, _) = MakeContext();
        var ex = (Exception)Activator.CreateInstance(exType, "boom")!;

        var handled = await sut.TryHandleAsync(ctx, ex, CancellationToken.None);

        handled.Should().BeTrue();
        ctx.Response.StatusCode.Should().Be(expectedStatus);
    }

    [Fact]
    public async Task TryHandleAsync_Production_DoesNotLeakExceptionMessage()
    {
        var sut = new GlobalExceptionHandler(NullLogger<GlobalExceptionHandler>.Instance, ProdEnv());
        var (ctx, body) = MakeContext();

        await sut.TryHandleAsync(ctx, new InvalidOperationException("secret-stack-trace"), CancellationToken.None);

        body.Position = 0;
        var payload = JsonDocument.Parse(body).RootElement.GetRawText();
        payload.Should().NotContain("secret-stack-trace");
        payload.Should().Contain("Réf:");
    }

    [Fact]
    public async Task TryHandleAsync_Development_IncludesExceptionMessage()
    {
        var devEnv = new FakeHostEnv { EnvironmentName = Environments.Development };
        var sut = new GlobalExceptionHandler(NullLogger<GlobalExceptionHandler>.Instance, devEnv);
        var (ctx, body) = MakeContext();

        await sut.TryHandleAsync(ctx, new InvalidOperationException("debug-detail"), CancellationToken.None);

        body.Position = 0;
        var payload = JsonDocument.Parse(body).RootElement.GetRawText();
        payload.Should().Contain("debug-detail");
    }
}
