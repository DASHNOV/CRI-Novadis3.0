using NovadisApi.Services.Export;
using Xunit;

namespace NovadisApi.Tests.Services
{
    public class ChartImageBuilderSmokeTest
    {
        [Fact]
        public void BuildBarChart_ProducesNonEmptyPng()
        {
            var data = new List<(string Label, double Value)> { ("A", 3), ("B", 5), ("C", 1) };
            var bytes = ChartImageBuilder.BuildBarChart("Test", data);
            Assert.NotEmpty(bytes);
        }

        [Fact]
        public void BuildPieChart_ProducesNonEmptyPng()
        {
            var data = new List<(string Label, double Value)> { ("Service", 8), ("Projet", 4) };
            var bytes = ChartImageBuilder.BuildPieChart("Test", data);
            Assert.NotEmpty(bytes);
        }

        [Fact]
        public void BuildLineChart_ProducesNonEmptyPng()
        {
            var data = new List<(string Label, double Value)> { ("01/01", 2), ("02/01", 4), ("03/01", 0) };
            var bytes = ChartImageBuilder.BuildLineChart("Test", data);
            Assert.NotEmpty(bytes);
        }
    }
}
