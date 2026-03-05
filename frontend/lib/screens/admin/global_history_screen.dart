import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';

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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
    final theme = Theme.of(context);
    final sortedCris = _sortedCris;
    final total = _cris.length;
    final signed = _cris.where((c) => c['clientSignature'] != null).length;
    final pending = total - signed;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tous les CRI'),
            Text(
              '$total CRI trouvé(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Afficher/Masquer Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsPage()),
              );
            },
            tooltip: 'Mes Documents & Exports',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Section (Performance Indicators)
          if (!_isLoading && _cris.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Total',
                      total.toString(),
                      Icons.analytics,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      'Signés',
                      signed.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      'Attente',
                      pending.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          // Filtres
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Filtre par technicien (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _selectedTechnicienId,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par technicien',
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                  const SizedBox(height: 8),

                  // Recherche par ID
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Rechercher par ID exact',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchSubmit('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: _onSearchSubmit,
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),

                  // Tri et Statut
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: InputDecoration(
                            labelText: 'Trier par',
                            prefixIcon: const Icon(Icons.sort),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Filtre par statut (Chips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((filter) {
                        final isSelected = _selectedFilter == filter.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter.label),
                            selected: isSelected,
                            onSelected: (_) =>
                                _onStatusFilterChanged(filter.value),
                            selectedColor: theme.colorScheme.primary
                                .withOpacity(0.2),
                            checkmarkColor: theme.colorScheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),

          // Liste des CRI
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cris.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedCris.length,
                      itemBuilder: (context, index) =>
                          _buildGlobalCriCard(sortedCris[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun CRI trouvé',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajustez les filtres',
            style: TextStyle(color: Colors.grey[500]),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Résumé d\'intervention'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: $createdAt'),
                  const SizedBox(height: 8),
                  Text('Technicien: $techFullName'),
                  const SizedBox(height: 8),
                  Text('Client: $clientName'),
                  const SizedBox(height: 8),
                  Text('Catégorie: $category'),
                  const SizedBox(height: 8),
                  Text('Type: $interventionType'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Client + Badge statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasSigned
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSigned ? Icons.check_circle : Icons.pending,
                          size: 14,
                          color: hasSigned ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasSigned ? 'Signé' : 'En attente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasSigned ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ligne 2: Type + Catégorie + Date
              Row(
                children: [
                  Icon(Icons.build_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$interventionType • $category',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Ligne 3: Nom du technicien
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    techFullName.isNotEmpty ? techFullName : 'Non assigné',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String value;

  const _FilterOption({required this.label, required this.value});
}
