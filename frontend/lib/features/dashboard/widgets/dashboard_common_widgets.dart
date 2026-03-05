import 'package:flutter/material.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';

/// Widget de filtre de période (Style Pills)
/// Widget de filtre de période (Style Pills)
class PeriodFilterWidget extends StatelessWidget {
  final DashboardPeriod selectedPeriod;
  final Function(DashboardPeriod) onPeriodChanged;

  const PeriodFilterWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ), // Max width to avoid overflow
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: DashboardPeriod.values.map((period) {
              final isSelected = period == selectedPeriod;
              return GestureDetector(
                onTap: () => onPeriodChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1C84C6) // Light Blue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Widget de sélection de technicien
class TechnicianSelectorWidget extends StatelessWidget {
  final List<TechnicianModel> technicians;
  final TechnicianModel? selectedTechnician;
  final Function(TechnicianModel?)? onTechnicianChanged;
  final bool isLoading;

  const TechnicianSelectorWidget({
    super.key,
    required this.technicians,
    this.selectedTechnician,
    this.onTechnicianChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: isLoading
          ? _buildLoadingState()
          : DropdownButtonHideUnderline(
              child: DropdownButton<TechnicianModel?>(
                value: selectedTechnician,
                hint: const Row(
                  children: [
                    Icon(Icons.person_search, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Sélectionner un technicien',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<TechnicianModel?>(
                    value: null,
                    child: Text(
                      'Sélectionner un technicien',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ...technicians.map((tech) {
                    return DropdownMenuItem<TechnicianModel>(
                      value: tech,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Text(
                              tech.name.isNotEmpty
                                  ? tech.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tech.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  tech.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: onTechnicianChanged,
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Chargement des techniciens...'),
        ],
      ),
    );
  }
}

/// Widget d'en-tête du dashboard
class DashboardHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? lastUpdated;
  final VoidCallback? onRefresh;

  const DashboardHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.lastUpdated,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              if (lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.update, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Mis à jour: ${_formatDateTime(lastUpdated!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Badge de statut (online/offline)
class ConnectionStatusBadge extends StatelessWidget {
  final bool isOnline;

  const ConnectionStatusBadge({super.key, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

