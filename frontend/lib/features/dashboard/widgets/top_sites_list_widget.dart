import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.success,
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
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
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
            Icon(Icons.location_off, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 8),
            Text(
              'Aucun site visité',
              style: TextStyle(color: AppTheme.textSecondary),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.clientName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildVisitBadge(),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700);
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32);
        break;
      default:
        badgeColor = AppTheme.textTertiary;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: rank <= 3 ? badgeColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryContent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility, size: 14, color: AppTheme.primaryContent),
          const SizedBox(width: 4),
          Text(
            '${site.visitCount}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.primaryContent,
            ),
          ),
        ],
      ),
    );
  }
}
