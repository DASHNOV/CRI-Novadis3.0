import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/models/personal_stats.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';

import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Page d'accueil personnalisee pour le technicien
/// Affiche ses statistiques personnelles et ses derniers CRI
class PersonalHomeScreen extends ConsumerStatefulWidget {
  const PersonalHomeScreen({super.key});

  @override
  ConsumerState<PersonalHomeScreen> createState() => _PersonalHomeScreenState();
}

class _PersonalHomeScreenState extends ConsumerState<PersonalHomeScreen> {
  PersonalStats _stats = PersonalStats.empty();
  List<Map<String, dynamic>> _recentCris = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);

      final results = await Future.wait([
        statsService.getPersonalStats(),
        statsService.getRecentPersonalCRIs(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as PersonalStats;
          _recentCris = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryContent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContentContainer(
            maxWidth: 1200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(AppTheme.space16),

                // Welcome header
                _buildWelcomeHeader(dateStr, userName),
                const Gap(AppTheme.space24),

                // KPI stat cards
                _isLoading ? _buildStatsShimmer() : _buildStatsRow(),
                const Gap(AppTheme.space32),

                // Recent CRI section
                _isLoading ? _buildCriListShimmer() : _buildRecentCRIsSection(),
                const Gap(AppTheme.space40),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriFormScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Nouveau CRI',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String dateStr, String? userName) {
    final initials = _getInitials(userName);

    return Row(
      children: [
        // Avatar circle with initials
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Gap(AppTheme.space16),

        // Greeting + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName != null && userName.isNotEmpty
                    ? 'Bonjour, $userName'
                    : 'Bonjour',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(AppTheme.space4),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Actions
        _buildHeaderIconButton(
          icon: Icons.folder_outlined,
          tooltip: 'Mes Documents & Exports',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsPage()),
            );
          },
        ),
        const Gap(AppTheme.space8),
        _buildHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Actualiser',
          onPressed: _loadData,
        ),
      ],
    ).animate().fadeIn(duration: AppTheme.animNormal);
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 20, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ─── KPI Stats Row ───

  Widget _buildStatsRow() {
    final isMobile = Responsive.isMobile(context);

    final cards = [
      _KpiStatCard(
        icon: Icons.check_circle_outline_rounded,
        label: 'CRI ce mois',
        value: _stats.criCeMois.toString(),
        color: AppTheme.success,
        colorLight: AppTheme.successLight,
      ),
      _KpiStatCard(
        icon: Icons.schedule_rounded,
        label: 'En cours',
        value: _stats.criEnCours.toString(),
        color: AppTheme.warning,
        colorLight: AppTheme.warningLight,
      ),
      _KpiStatCard(
        icon: Icons.warning_amber_rounded,
        label: 'En attente',
        value: _stats.criEnAttente.toString(),
        color: AppTheme.error,
        colorLight: AppTheme.errorLight,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i]
                .animate()
                .fadeIn(
                  duration: AppTheme.animNormal,
                  delay: Duration(milliseconds: 80 * i),
                )
                .slideY(begin: 0.1, end: 0),
            if (i < cards.length - 1) const Gap(AppTheme.space12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: cards[i]
                .animate()
                .fadeIn(
                  duration: AppTheme.animNormal,
                  delay: Duration(milliseconds: 80 * i),
                )
                .slideY(begin: 0.1, end: 0),
          ),
          if (i < cards.length - 1) const Gap(AppTheme.space12),
        ],
      ],
    );
  }

  // ─── Recent CRIs Section ───

  Widget _buildRecentCRIsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes derniers CRI',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${_recentCris.length} recent(s)',
                style: GoogleFonts.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const Gap(AppTheme.space16),

        if (_recentCris.isEmpty)
          _buildEmptyState()
        else
          _buildCriGrid(),
      ],
    ).animate().fadeIn(duration: AppTheme.animNormal, delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space48),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 28,
              color: AppTheme.textTertiary,
            ),
          ),
          const Gap(AppTheme.space16),
          Text(
            'Aucun CRI recent',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(AppTheme.space4),
          Text(
            'Vos derniers comptes rendus apparaitront ici',
            style: GoogleFonts.inter(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriGrid() {
    final crossAxisCount = Responsive.cardGridCrossAxisCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 3.2 : 2.4,
        crossAxisSpacing: AppTheme.space12,
        mainAxisSpacing: AppTheme.space12,
      ),
      itemCount: _recentCris.length,
      itemBuilder: (context, index) => _buildCriCard(_recentCris[index])
          .animate()
          .fadeIn(
            duration: AppTheme.animNormal,
            delay: Duration(milliseconds: 60 * index),
          )
          .slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildCriCard(Map<String, dynamic> cri) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final status = cri['status'] ?? 'Draft';
    final createdAt = cri['createdAt'] != null
        ? _formatRelativeDate(DateTime.tryParse(cri['createdAt']))
        : '';

    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
            const Gap(AppTheme.space8),

            // Client name
            Text(
              clientName,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Category + date
            Text(
              [category, createdAt].where((s) => s.isNotEmpty).join(' \u00B7 '),
              style: GoogleFonts.inter(
                color: AppTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // ─── Shimmer loading states ───

  Widget _buildStatsShimmer() {
    final isMobile = Responsive.isMobile(context);
    final shimmerCard = _buildShimmerBox(height: isMobile ? 80 : 100);

    if (isMobile) {
      return Column(
        children: [
          shimmerCard,
          const Gap(AppTheme.space12),
          shimmerCard,
          const Gap(AppTheme.space12),
          shimmerCard,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: shimmerCard),
        const Gap(AppTheme.space12),
        Expanded(child: shimmerCard),
        const Gap(AppTheme.space12),
        Expanded(child: shimmerCard),
      ],
    );
  }

  Widget _buildCriListShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerBox(height: 24, width: 180),
        const Gap(AppTheme.space16),
        _buildShimmerBox(height: 88),
        const Gap(AppTheme.space12),
        _buildShimmerBox(height: 88),
        const Gap(AppTheme.space12),
        _buildShimmerBox(height: 88),
      ],
    );
  }

  Widget _buildShimmerBox({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  // ─── Status helpers (unchanged logic) ───

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppTheme.success;
      case 'validated':
        return AppTheme.primaryContent;
      case 'draft':
      default:
        return AppTheme.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Soumis';
      case 'validated':
        return 'Valide';
      case 'draft':
      default:
        return 'Brouillon';
    }
  }
}

// ─── KPI Stat Card ───

class _KpiStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color colorLight;

  const _KpiStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colorLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          // Icon in colored circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const Gap(AppTheme.space16),

          // Value + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const Gap(AppTheme.space4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hover Card with subtle interaction ───

class _HoverCard extends StatefulWidget {
  final Widget child;
  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceVariant : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryLight : AppTheme.border,
          ),
          boxShadow: _isHovered ? AppTheme.shadowMd : AppTheme.shadowSm,
        ),
        child: widget.child,
      ),
    );
  }
}
