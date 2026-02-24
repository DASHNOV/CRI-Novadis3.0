import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/features/history/widgets/cri_details_dialog.dart';

/// Historique personnel - uniquement les CRI du technicien connecté
class PersonalHistoryScreen extends ConsumerStatefulWidget {
  const PersonalHistoryScreen({super.key});

  @override
  ConsumerState<PersonalHistoryScreen> createState() =>
      _PersonalHistoryScreenState();
}

class _PersonalHistoryScreenState extends ConsumerState<PersonalHistoryScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _cris = [];
  bool _isLoading = true;
  int _pendingCount = 0;

  final List<_FilterOption> _filters = [
    _FilterOption(label: 'Tous', value: 'all'),
    _FilterOption(label: 'En attente', value: 'pending'),
    _FilterOption(label: 'Signés', value: 'signed'),
    _FilterOption(label: 'En cours', value: 'in_progress'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCRIs();
  }

  Future<void> _loadCRIs() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);
      final cris = await statsService.getPersonalCRIs(filter: _selectedFilter);

      // Compter les CRI en attente pour le badge
      if (_selectedFilter == 'all') {
        _pendingCount = cris.where((c) => c['clientSignature'] == null).length;
      }

      if (mounted) {
        setState(() {
          _cris = cris;
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

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCRIs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes CRI'),
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
            onPressed: _loadCRIs,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter.value;
                  final showBadge =
                      filter.value == 'pending' && _pendingCount > 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filter.label),
                          if (showBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => _onFilterChanged(filter.value),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }).toList(),
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
                    onRefresh: _loadCRIs,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cris.length,
                      itemBuilder: (context, index) =>
                          _buildCriCard(_cris[index]),
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
            _selectedFilter == 'all'
                ? 'Créez votre premier CRI'
                : 'Aucun CRI avec ce filtre',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCriCard(Map<String, dynamic> cri) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final interventionType = cri['interventionType'] ?? '';

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
          final criModel = CriModel(
            id: cri['id'],
            client: clientName,
            site: cri['clientSite'] ?? clientName,
            typeIntervention: interventionType,
            description: cri['workDescription'] ?? '',
            date: cri['interventionDate'] != null 
                ? DateTime.tryParse(cri['interventionDate']) ?? DateTime.now()
                : DateTime.now(),
            createdAt: cri['createdAt'] != null 
                ? DateTime.tryParse(cri['createdAt']) ?? DateTime.now()
                : DateTime.now(),
          );
          
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => CriDetailsDialog(cri: criModel),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
