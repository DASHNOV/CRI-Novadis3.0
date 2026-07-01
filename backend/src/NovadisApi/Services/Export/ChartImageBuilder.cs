using ScottPlot;

namespace NovadisApi.Services.Export
{
    /// <summary>
    /// Génère des graphiques (PNG) à embarquer dans les classeurs Excel.
    /// ClosedXML n'a pas d'API de charts natifs Excel : on rend les graphiques
    /// côté serveur avec ScottPlot puis on les insère comme images.
    /// </summary>
    public static class ChartImageBuilder
    {
        private static readonly string[] Palette = { "#8BB8E8", "#1A1A1A", "#4CAF50", "#F0AD4E", "#D9534F", "#5A6472", "#C0C0C0", "#CD7F32" };

        public static byte[] BuildBarChart(string title, IReadOnlyList<(string Label, double Value)> data, int width = 640, int height = 360)
        {
            var plt = new Plot();
            plt.Title(title);

            var bars = data.Select((d, i) => new Bar
            {
                Position = i,
                Value = d.Value,
                FillColor = Color.FromHex(Palette[i % Palette.Length]),
            }).ToArray();
            plt.Add.Bars(bars);

            var ticks = data.Select((d, i) => new Tick(i, d.Label)).ToArray();
            plt.Axes.Bottom.TickGenerator = new ScottPlot.TickGenerators.NumericManual(ticks);
            plt.Axes.Bottom.MajorTickStyle.Length = 0;
            plt.HideGrid();

            return plt.GetImageBytes(width, height, ImageFormat.Png);
        }

        public static byte[] BuildPieChart(string title, IReadOnlyList<(string Label, double Value)> data, int width = 480, int height = 360)
        {
            var plt = new Plot();
            plt.Title(title);

            var values = data.Select(d => d.Value).ToArray();
            var pie = plt.Add.Pie(values);
            for (var i = 0; i < pie.Slices.Count; i++)
            {
                pie.Slices[i].Label = $"{data[i].Label} ({data[i].Value:0.#})";
                pie.Slices[i].FillColor = Color.FromHex(Palette[i % Palette.Length]);
            }

            return plt.GetImageBytes(width, height, ImageFormat.Png);
        }

        public static byte[] BuildLineChart(string title, IReadOnlyList<(string Label, double Value)> data, int width = 720, int height = 300)
        {
            var plt = new Plot();
            plt.Title(title);

            var xs = Enumerable.Range(0, data.Count).Select(i => (double)i).ToArray();
            var ys = data.Select(d => d.Value).ToArray();
            var scatter = plt.Add.Scatter(xs, ys);
            scatter.Color = Color.FromHex("#1A1A1A");
            scatter.LineWidth = 2;
            scatter.MarkerSize = 5;

            var step = Math.Max(1, data.Count / 12);
            var ticks = data.Select((d, i) => new Tick(i, d.Label))
                .Where((t, i) => i % step == 0)
                .ToArray();
            plt.Axes.Bottom.TickGenerator = new ScottPlot.TickGenerators.NumericManual(ticks);
            plt.Axes.Bottom.MajorTickStyle.Length = 0;

            return plt.GetImageBytes(width, height, ImageFormat.Png);
        }
    }
}
