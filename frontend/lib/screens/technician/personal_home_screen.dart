import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:novadis_cri/models/personal_stats.dart';
import 'package:novadis_cri/models/monthly_activity.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_projet_form_page.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_service_form_page.dart';

import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class PersonalHomeScreen extends ConsumerStatefulWidget {
  const PersonalHomeScreen({super.key});

  @override
  ConsumerState<PersonalHomeScreen> createState() => _PersonalHomeScreenState();
}

class _PersonalHomeScreenState extends ConsumerState<PersonalHomeScreen> {
  PersonalStats _stats = PersonalStats.empty();
  List<Map<String, dynamic>> _recentCris = [];
  List<Map<String, dynamic>> _draftCris = [];
  List<MonthlyActivity> _monthlyActivity = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadData();
  }

  Future<void> _checkConnectivity() async {
    // connectivity_plus ne supporte pas Flutter Web
    if (kIsWeb) return;
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() => _isOnline = !result.contains(ConnectivityResult.none));
      }
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          setState(() => _isOnline = !results.contains(ConnectivityResult.none));
        }
      });
    } catch (_) {
      // Plateforme non supportée, on reste en mode "online"
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);
      final results = await Future.wait([
        statsService.getPersonalStats(),
        statsService.getRecentPersonalCRIs(),
        statsService.getPersonalCRIs(filter: 'in_progress'),
        statsService.getPersonalMonthlyStats(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as PersonalStats;
          _recentCris = results[1] as List<Map<String, dynamic>>;
          final allDrafts = results[2] as List<Map<String, dynamic>>;
          _draftCris = allDrafts.take(3).toList();
          _monthlyActivity = results[3] as List<MonthlyActivity>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryContent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ContentContainer(
              maxWidth: 1200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(AppTheme.space4),
                  _buildWelcomeHeader(dateStr, userName),
                  const Gap(AppTheme.space24),

                  // KPI stats
                  _isLoading ? _buildStatsShimmer() : _buildStatsRow(),
                  const Gap(AppTheme.space24),

                  // Sparkline activité mensuelle
                  if (!_isLoading && _monthlyActivity.isNotEmpty) ...[
                    _buildSparklineSection(),
                    const Gap(AppTheme.space24),
                  ],

                  // Brouillons à compléter
                  if (!_isLoading && _draftCris.isNotEmpty) ...[
                    _buildDraftsSection(),
                    const Gap(AppTheme.space24),
                  ],

                  // CRI récents
                  _isLoading ? _buildCriListShimmer() : _buildRecentCRIsSection(),
                  const Gap(AppTheme.space40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  // ─── Header ───

  Widget _buildWelcomeHeader(String dateStr, String? userName) {
    final initials = _getInitials(userName);

    return Row(
      children: [
        // Avatar → navigue vers l'onglet Profil
        GestureDetector(
          onTap: () {
            ref.read(requestedMainTabProvider.notifier).state = 'Profil';
          },
          child: Stack(
            children: [
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
              // Connectivité badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _isOnline ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.background, width: 2),
                  ),
                ),
              ),
            ],
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
              Row(
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: AppTheme.textTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (!_isOnline) ...[
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        'Hors ligne',
                        style: GoogleFonts.inter(
                          color: AppTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

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
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  // ─── Speed Dial FAB ───

  Widget _buildSpeedDial() {
    return FloatingActionButton.extended(
      heroTag: 'fab_personal_home',
      onPressed: _showNewCriSheet,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        'Nouveau CRI',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    );
  }

  void _showNewCriSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(20),
              Text(
                'Quel type de CRI ?',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Gap(16),
              _SheetOption(
                icon: Icons.description_outlined,
                label: 'CRI Projet',
                subtitle: 'Compte rendu d\'intervention projet',
                color: AppTheme.primaryContent,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CriProjetFormPage()));
                },
              ),
              const Gap(12),
              _SheetOption(
                icon: Icons.build_outlined,
                label: 'CRI Service',
                subtitle: 'Compte rendu d\'intervention service',
                color: AppTheme.success,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CriServiceFormPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── KPI Stats ───

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
      _KpiStatCard(
        icon: Icons.verified_outlined,
        label: 'Résolus total',
        value: _stats.totalResolu.toString(),
        color: AppTheme.primaryContent,
        colorLight: AppTheme.primary.withValues(alpha: 0.1),
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const Gap(AppTheme.space12),
          itemBuilder: (_, i) => SizedBox(
            width: 200,
            child: cards[i]
                .animate()
                .fadeIn(duration: AppTheme.animNormal, delay: Duration(milliseconds: 60 * i))
                .slideX(begin: 0.1, end: 0),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: cards[i]
                .animate()
                .fadeIn(duration: AppTheme.animNormal, delay: Duration(milliseconds: 80 * i))
                .slideY(begin: 0.1, end: 0),
          ),
          if (i < cards.length - 1) const Gap(AppTheme.space12),
        ],
      ],
    );
  }

  // ─── Sparkline ───

  Widget _buildSparklineSection() {
    final maxNb = _monthlyActivity.map((m) => m.nb).fold(0, (a, b) => a > b ? a : b);
    final hasData = maxNb > 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité (6 derniers mois)',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'CRI créés',
                style: GoogleFonts.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(AppTheme.space16),
          SizedBox(
            height: 80,
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _monthlyActivity.length) {
                                return const SizedBox.shrink();
                              }
                              final m = _monthlyActivity[idx];
                              return Text(
                                DateFormat('MMM', 'fr_FR')
                                    .format(DateTime(m.annee, m.mois))
                                    .substring(0, 3),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textTertiary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _monthlyActivity
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value.nb.toDouble()))
                              .toList(),
                          isCurved: true,
                          color: AppTheme.primaryContent,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryContent.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  )
                : Center(
                    child: Text(
                      'Aucune activité sur cette période',
                      style: GoogleFonts.inter(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.animNormal, delay: 150.ms);
  }

  // ─── Brouillons ───

  Widget _buildDraftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Text(
              'Brouillons à compléter',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${_stats.criEnCours}',
                style: GoogleFonts.inter(
                  color: AppTheme.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Gap(AppTheme.space12),
        ..._draftCris.asMap().entries.map((entry) {
          final cri = entry.value;
          final clientName = cri['clientName'] ?? 'Client inconnu';
          final category = cri['category'] ?? '';
          final createdAt = cri['createdAt'] != null
              ? _formatRelativeDate(DateTime.tryParse(cri['createdAt']))
              : '';
          final criId = cri['id']?.toString() ?? '';
          final type = (cri['type'] ?? '').toString().toLowerCase().contains('projet')
              ? 'projet'
              : 'service';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HoverCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => type == 'projet'
                      ? CriProjetFormPage(criId: criId)
                      : CriServiceFormPage(criId: criId),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.warning),
                    ),
                    const Gap(AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            [category, createdAt].where((s) => s.isNotEmpty).join(' · '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textTertiary),
                  ],
                ),
              ),
            ).animate().fadeIn(
                  duration: AppTheme.animNormal,
                  delay: Duration(milliseconds: 60 * entry.key),
                ),
          );
        }),
      ],
    );
  }

  // ─── CRI récents ───

  Widget _buildRecentCRIsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                '${_recentCris.length} récent(s)',
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
        if (_recentCris.isEmpty) _buildEmptyState() else _buildCriGrid(),
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
            child: Icon(Icons.inbox_outlined, size: 28, color: AppTheme.textTertiary),
          ),
          const Gap(AppTheme.space16),
          Text(
            'Aucun CRI récent',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(AppTheme.space4),
          Text(
            'Vos derniers comptes rendus apparaîtront ici',
            style: GoogleFonts.inter(color: AppTheme.textTertiary, fontSize: 13),
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
          .fadeIn(duration: AppTheme.animNormal, delay: Duration(milliseconds: 60 * index))
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
    final criId = cri['id']?.toString() ?? '';
    final type = (cri['type'] ?? '').toString().toLowerCase().contains('projet')
        ? 'projet'
        : 'service';

    return _HoverCard(
      onTap: criId.isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => type == 'projet'
                      ? CriProjetFormPage(criId: criId)
                      : CriServiceFormPage(criId: criId),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textTertiary),
              ],
            ),
            const Gap(AppTheme.space8),
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
            Text(
              [category, createdAt].where((s) => s.isNotEmpty).join(' \u00B7 '),
              style: GoogleFonts.inter(
                color: AppTheme.textTertiary,
                fontSize: 12,
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
      return Row(
        children: [
          Expanded(child: shimmerCard),
          const Gap(AppTheme.space12),
          Expanded(child: shimmerCard),
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

  // ─── Status helpers ───

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
        return 'Validé';
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

// ─── Bottom Sheet Option ───

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hover Card ───

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverCard({required this.child, this.onTap});

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
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
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
      ),
    );
  }
}
