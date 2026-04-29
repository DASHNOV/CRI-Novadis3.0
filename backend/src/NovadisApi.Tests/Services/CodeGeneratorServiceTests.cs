using FluentAssertions;
using NovadisApi.Services.Auth;

namespace NovadisApi.Tests.Services;

public class CodeGeneratorServiceTests
{
    private readonly CodeGeneratorService _sut = new();

    [Fact]
    public void GenerateCode_DefaultLength_Returns6Digits()
    {
        var code = _sut.GenerateCode();
        code.Should().HaveLength(6);
        code.Should().MatchRegex("^\\d{6}$");
    }

    [Theory]
    [InlineData(4)]
    [InlineData(8)]
    [InlineData(10)]
    public void GenerateCode_CustomLength_ReturnsCorrectLength(int length)
    {
        var code = _sut.GenerateCode(length);
        code.Should().HaveLength(length);
        code.Should().MatchRegex($"^\\d{{{length}}}$");
    }

    [Fact]
    public void GenerateCode_ProducesDifferentCodes_OverManyCalls()
    {
        // 1000 codes — collisions extrêmement improbables si RNG cryptographique
        var codes = Enumerable.Range(0, 1000).Select(_ => _sut.GenerateCode()).ToList();
        var unique = codes.Distinct().Count();
        unique.Should().BeGreaterThan(950, "le RNG cryptographique doit éviter les répétitions massives");
    }

    [Fact]
    public void HashCode_SameInput_ProducesSameHash()
    {
        var h1 = _sut.HashCode("123456");
        var h2 = _sut.HashCode("123456");
        h1.Should().Be(h2);
    }

    [Fact]
    public void HashCode_DifferentInput_ProducesDifferentHash()
    {
        var h1 = _sut.HashCode("123456");
        var h2 = _sut.HashCode("654321");
        h1.Should().NotBe(h2);
    }

    [Fact]
    public void VerifyCode_CorrectCode_ReturnsTrue()
    {
        var hash = _sut.HashCode("987654");
        _sut.VerifyCode("987654", hash).Should().BeTrue();
    }

    [Fact]
    public void VerifyCode_WrongCode_ReturnsFalse()
    {
        var hash = _sut.HashCode("987654");
        _sut.VerifyCode("000000", hash).Should().BeFalse();
    }
}
