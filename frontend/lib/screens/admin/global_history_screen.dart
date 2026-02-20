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
  List<Map<String, dynamic>> _cris = [];
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);

      // Charger techniciens et CRI en parallèle
      final results = await Future.wait([
        statsService.getAllCRIsWithTechnician(
          technicienId: _selectedTechnicienId,
          filter: _selectedFilter,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tous les CRI'),
            Text(
              '${_cris.length} CRI trouvé(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        elevation: 0,
        actions: [
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
          // Filtres
          Container(
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
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
                      itemCount: _cris.length,
                      itemBuilder: (context, index) =>
                          _buildGlobalCriCard(_cris[index]),
                    ),
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
          // TODO: Naviguer vers le détail du CRI
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
