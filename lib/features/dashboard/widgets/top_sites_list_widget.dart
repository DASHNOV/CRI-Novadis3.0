import 'package:flutter/material.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';

/// Widget pour afficher la liste des top sites
class TopSitesListWidget extends StatelessWidget {
  final List<TopSiteData> sites;
  final String title;
  final String? subtitle;
  final Function(TopSiteData site)? onSiteTap;
  final bool isLoading;

  const TopSitesListWidget({
    super.key,
    required this.sites,
    this.title = 'Top 5 Sites',
    this.subtitle = 'Sites les plus visités',
    this.onSiteTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState()
            else if (sites.isEmpty)
              _buildEmptyState()
            else
              _buildSitesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucun site visité',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitesList(BuildContext context) {
    return Column(
      children: sites.asMap().entries.map((entry) {
        final index = entry.key;
        final site = entry.value;
        return _SiteListItem(
          site: site,
          rank: index + 1,
          onTap: onSiteTap != null ? () => onSiteTap!(site) : null,
          isLast: index == sites.length - 1,
        );
      }).toList(),
    );
  }
}

class _SiteListItem extends StatelessWidget {
  final TopSiteData site;
  final int rank;
  final VoidCallback? onTap;
  final bool isLast;

  const _SiteListItem({
    required this.site,
    required this.rank,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                _buildRankBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.siteName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.clientName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildVisitBadge(),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Or
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Argent
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: rank <= 3 ? badgeColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '${site.visitCount}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
