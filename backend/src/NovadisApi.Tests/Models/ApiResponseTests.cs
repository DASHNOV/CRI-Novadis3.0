using FluentAssertions;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Tests.Models;

public class ApiResponseTests
{
    [Fact]
    public void SuccessResponse_SetsSuccessTrueAndData()
    {
        var r = ApiResponse<string>.SuccessResponse("payload", "ok");
        r.Success.Should().BeTrue();
        r.Data.Should().Be("payload");
        r.Message.Should().Be("ok");
        r.Errors.Should().BeNull();
    }

    [Fact]
    public void ErrorResponse_SetsSuccessFalseAndMessage()
    {
        var r = ApiResponse<int>.ErrorResponse("erreur", new List<string> { "détail1" });
        r.Success.Should().BeFalse();
        r.Message.Should().Be("erreur");
        r.Errors.Should().ContainSingle().Which.Should().Be("détail1");
    }
}
