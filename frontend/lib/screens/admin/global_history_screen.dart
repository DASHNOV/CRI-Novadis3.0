import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Historique global - tous les CRI de tous les techniciens (admin uniquement)
class GlobalHistoryScreen extends ConsumerStatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  ConsumerState<GlobalHistoryScreen> createState() =>
      _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends ConsumerState<GlobalHistoryScreen> {
  String _selectedFilter = 'all';
  String? _selectedTechnicienId;
  String _searchId = '';
  String _sortBy = 'date_desc';
  bool _showFilters = false;
  List<Map<String, dynamic>> _cris = [];
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  final List<_FilterOption> _statusFilters = [
    _FilterOption(label: 'Tous', value: 'all'),
    _FilterOption(label: 'En attente', value: 'pending'),
    _FilterOption(label: 'Signés', value: 'signed'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);

      // Charger techniciens et CRI en parallèle
      final results = await Future.wait([
        statsService.getAllCRIsWithTechnician(
          technicienId: _selectedTechnicienId,
          filter: _selectedFilter,
          searchId: _searchId.isNotEmpty ? _searchId : null,
        ),
        statsService.getTechnicians(),
      ]);

      if (mounted) {
        setState(() {
          _cris = List<Map<String, dynamic>>.from(results[0] as List);
          _technicians = List<Map<String, dynamic>>.from(results[1] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  void _onStatusFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadData();
  }

  void _onTechnicienFilterChanged(String? techId) {
    setState(() => _selectedTechnicienId = techId);
    _loadData();
  }

  void _onSearchSubmit(String value) {
    setState(() => _searchId = value.trim());
    _loadData();
  }

  List<Map<String, dynamic>> get _sortedCris {
    final sorted = List<Map<String, dynamic>>.from(_cris);
    sorted.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          final dateA =
              DateTime.tryParse(a['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse(b['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateA.compareTo(dateB);
        case 'client_asc':
          final clientA = (a['clientName'] ?? '').toString().toLowerCase();
          final clientB = (b['clientName'] ?? '').toString().toLowerCase();
          return clientA.compareTo(clientB);
        case 'tech_asc':
          final techA = '${a['technicianFirstName']} ${a['technicianLastName']}'
              .toLowerCase();
          final techB = '${b['technicianFirstName']} ${b['technicianLastName']}'
              .toLowerCase();
          return techA.compareTo(techB);
        case 'date_desc':
        default:
          final dateA =
              DateTime.tryParse(a['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse(b['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
      }
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final sortedCris = _sortedCris;
    final total = _cris.length;
    final signed = _cris.where((c) => c['clientSignature'] != null).length;
    final pending = total - signed;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 1400,
          child: Column(
            children: [
              // Custom inline header (no AppBar)
              _buildHeader(total),

              // KPI Section
              if (!_isLoading && _cris.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space8,
                    AppTheme.space16,
                    AppTheme.space8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Total',
                          total.toString(),
                          Icons.analytics_rounded,
                          AppTheme.primaryContent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: _buildKpiCard(
                          'Signés',
                          signed.toString(),
                          Icons.check_circle_rounded,
                          AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: _buildKpiCard(
                          'Attente',
                          pending.toString(),
                          Icons.pending_rounded,
                          AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),

              // Collapsible Filters
              _buildFiltersPanel(),

              // Status filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space4,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedFilter == filter.value;
                      final count = filter.value == 'all'
                          ? total
                          : filter.value == 'signed'
                              ? signed
                              : pending;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.space8),
                        child: _buildStatusChip(
                          filter.label,
                          count,
                          isSelected,
                          () => _onStatusFilterChanged(filter.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space8),

              // CRI List
              Expanded(
                child: _isLoading
                    ? _buildShimmerList()
                    : _cris.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primaryContent,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth >= 1000) {
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(
                                        AppTheme.space16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: AppTheme.space16,
                                      mainAxisSpacing: AppTheme.space12,
                                      childAspectRatio: 2.5,
                                    ),
                                    itemCount: sortedCris.length,
                                    itemBuilder: (context, index) =>
                                        _buildGlobalCriCard(
                                            sortedCris[index]),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(
                                      AppTheme.space16),
                                  itemCount: sortedCris.length,
                                  itemBuilder: (context, index) =>
                                      _buildGlobalCriCard(sortedCris[index]),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space8,
        AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tous les CRI',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '$total CRI trouvé(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderAction(
            icon: _showFilters
                ? Icons.filter_list_off_rounded
                : Icons.filter_list_rounded,
            tooltip: 'Filtres',
            onPressed: () => setState(() => _showFilters = !_showFilters),
            isActive: _showFilters,
          ),
          _buildHeaderAction(
            icon: Icons.folder_outlined,
            tooltip: 'Documents',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsPage()),
              );
            },
          ),
          _buildHeaderAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualiser',
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.space4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? AppTheme.primaryContent : AppTheme.textSecondary,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
        constraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 38,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space8,
          AppTheme.space16,
          0,
        ),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            // Technician dropdown
            DropdownButtonFormField<String>(
              value: _selectedTechnicienId,
              decoration: InputDecoration(
                labelText: 'Filtrer par technicien',
                labelStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.person_search_rounded,
                    color: AppTheme.textTertiary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                      BorderSide(color: AppTheme.primaryContent, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                isDense: true,
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tous les techniciens'),
                ),
                ..._technicians.map((tech) {
                  final id = tech['id']?.toString();
                  final firstName = tech['firstName'] ?? '';
                  final lastName = tech['lastName'] ?? '';
                  final role = tech['role'] ?? '';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text('$firstName $lastName ($role)'),
                  );
                }),
              ],
              onChanged: _onTechnicienFilterChanged,
            ),
            const SizedBox(height: AppTheme.space8),

            // Search by ID
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par ID exact',
                labelStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textTertiary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: AppTheme.textTertiary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmit('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                      BorderSide(color: AppTheme.primaryContent, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                isDense: true,
              ),
              onSubmitted: _onSearchSubmit,
              onChanged: (val) {
                setState(() {});
              },
            ),
            const SizedBox(height: AppTheme.space8),

            // Sort dropdown
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'Trier par',
                labelStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.sort_rounded,
                    color: AppTheme.textTertiary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                      BorderSide(color: AppTheme.primaryContent, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'date_desc',
                  child: Text('Date (récent)'),
                ),
                DropdownMenuItem(
                  value: 'date_asc',
                  child: Text('Date (ancien)'),
                ),
                DropdownMenuItem(
                  value: 'client_asc',
                  child: Text('Client (A-Z)'),
                ),
                DropdownMenuItem(
                  value: 'tech_asc',
                  child: Text('Technicien (A-Z)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _sortBy = val);
              },
            ),
          ],
        ),
      ),
      crossFadeState:
          _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: AppTheme.animNormal,
      sizeCurve: Curves.easeOut,
    );
  }

  Widget _buildStatusChip(
      String label, int count, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryContent
                : AppTheme.border.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected ? AppTheme.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.space12),
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Aucun CRI trouvé',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Ajustez les filtres pour trouver des résultats',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedTechnicienId = null;
                _searchId = '';
                _searchController.clear();
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réinitialiser les filtres'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryContent,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: AppTheme.primaryContent.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCriCard(Map<String, dynamic> cri) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final interventionType = cri['interventionType'] ?? '';
    final techFirstName = cri['technicianFirstName'] ?? '';
    final techLastName = cri['technicianLastName'] ?? '';
    final techFullName = '$techFirstName $techLastName'.trim();
    final createdAt = cri['createdAt'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.tryParse(cri['createdAt']) ?? DateTime.now())
        : '';
    final hasSigned = cri['clientSignature'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          hoverColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                title: Text(
                  'Résumé d\'intervention',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.calendar_today_rounded, 'Date',
                        createdAt),
                    const SizedBox(height: AppTheme.space8),
                    _buildDetailRow(Icons.person_rounded, 'Technicien',
                        techFullName),
                    const SizedBox(height: AppTheme.space8),
                    _buildDetailRow(Icons.business_rounded, 'Client',
                        clientName),
                    const SizedBox(height: AppTheme.space8),
                    _buildDetailRow(Icons.category_rounded, 'Catégorie',
                        category),
                    const SizedBox(height: AppTheme.space8),
                    _buildDetailRow(Icons.build_rounded, 'Type',
                        interventionType),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryContent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Client + Status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildStatusBadge(hasSigned),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),

                // Row 2: Type + Category + Date
                Row(
                  children: [
                    Icon(Icons.build_rounded,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        '$interventionType • $category',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),

                // Row 3: Technician name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        techFullName.isNotEmpty
                            ? techFullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryContent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      techFullName.isNotEmpty ? techFullName : 'Non assigné',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryContent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool hasSigned) {
    final color = hasSigned ? AppTheme.success : AppTheme.warning;
    final bgColor = hasSigned ? AppTheme.successLight : AppTheme.warningLight;
    final label = hasSigned ? 'Signé' : 'En attente';
    final iconData = hasSigned
        ? Icons.check_circle_rounded
        : Icons.pending_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.space8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterOption {
  final String label;
  final String value;

  const _FilterOption({required this.label, required this.value});
}
