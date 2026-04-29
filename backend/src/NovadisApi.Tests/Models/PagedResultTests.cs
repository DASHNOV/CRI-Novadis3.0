using FluentAssertions;
using NovadisApi.Models.DTOs;

namespace NovadisApi.Tests.Models;

public class PaginationQueryTests
{
    [Theory]
    [InlineData(0, 1)]
    [InlineData(-5, 1)]
    [InlineData(1, 1)]
    [InlineData(10, 10)]
    public void Page_BelowOne_ClampsToOne(int input, int expected)
    {
        var q = new PaginationQuery { Page = input };
        q.Page.Should().Be(expected);
    }

    [Theory]
    [InlineData(0, 50)]    // 0 → défaut
    [InlineData(-1, 50)]
    [InlineData(50, 50)]
    [InlineData(500, 200)] // > MaxPageSize → clampé
    public void PageSize_OutOfRange_ClampsToBounds(int input, int expected)
    {
        var q = new PaginationQuery { PageSize = input };
        q.PageSize.Should().Be(expected);
    }

    [Fact]
    public void Skip_ComputesCorrectly()
    {
        new PaginationQuery { Page = 1, PageSize = 50 }.Skip.Should().Be(0);
        new PaginationQuery { Page = 3, PageSize = 20 }.Skip.Should().Be(40);
    }
}

public class PagedResultTests
{
    [Fact]
    public void Create_ComputesTotalPages()
    {
        var r = PagedResult<int>.Create(new[] { 1, 2 }, totalCount: 95, page: 1, pageSize: 50);
        r.TotalPages.Should().Be(2);
        r.HasNext.Should().BeTrue();
        r.HasPrev.Should().BeFalse();
    }

    [Fact]
    public void Create_LastPage_HasNoNext()
    {
        var r = PagedResult<int>.Create(Array.Empty<int>(), totalCount: 100, page: 2, pageSize: 50);
        r.HasNext.Should().BeFalse();
        r.HasPrev.Should().BeTrue();
    }

    [Fact]
    public void TotalPages_ZeroPageSize_ReturnsZero()
    {
        var r = PagedResult<int>.Create(Array.Empty<int>(), totalCount: 100, page: 1, pageSize: 0);
        r.TotalPages.Should().Be(0);
    }
}
