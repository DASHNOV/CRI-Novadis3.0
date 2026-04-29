namespace NovadisApi.Models.DTOs
{
    /// <summary>
    /// Résultat paginé générique pour les listes volumineuses.
    /// </summary>
    public class PagedResult<T>
    {
        public IEnumerable<T> Items { get; set; } = Enumerable.Empty<T>();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling((double)TotalCount / PageSize);
        public bool HasNext => Page < TotalPages;
        public bool HasPrev => Page > 1;

        public static PagedResult<T> Create(IEnumerable<T> items, int totalCount, int page, int pageSize)
            => new() { Items = items, TotalCount = totalCount, Page = page, PageSize = pageSize };
    }

    public class PaginationQuery
    {
        private const int MaxPageSize = 200;
        private int _pageSize = 50;
        private int _page = 1;

        public int Page
        {
            get => _page;
            set => _page = value < 1 ? 1 : value;
        }

        public int PageSize
        {
            get => _pageSize;
            set => _pageSize = value switch
            {
                < 1 => 50,
                > MaxPageSize => MaxPageSize,
                _ => value
            };
        }

        public int Skip => (Page - 1) * PageSize;
    }
}
