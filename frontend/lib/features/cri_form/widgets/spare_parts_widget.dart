import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

class SparePartsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> initialParts;
  final Function(List<Map<String, dynamic>>) onPartsChanged;

  const SparePartsWidget({
    super.key,
    required this.initialParts,
    required this.onPartsChanged,
  });

  @override
  State<SparePartsWidget> createState() => _SparePartsWidgetState();
}

class _SparePartsWidgetState extends State<SparePartsWidget> {
  late List<Map<String, dynamic>> _parts;

  @override
  void initState() {
    super.initState();
    _parts = List.from(
      widget.initialParts.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  void _addPart() {
    setState(() {
      _parts.add({'ref': '', 'designation': '', 'garantie': false, 'qte': 1});
      widget.onPartsChanged(_parts);
    });
  }

  void _removePart(int index) {
    setState(() {
      _parts.removeAt(index);
      widget.onPartsChanged(_parts);
    });
  }

  void _updatePart(int index, String field, dynamic value) {
    setState(() {
      _parts[index][field] = value;
      widget.onPartsChanged(_parts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pièces Détachées', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary)),
            TextButton.icon(
              onPressed: _addPart,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (_parts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune pièce ajoutée',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textTertiary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _parts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final part = _parts[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Référence',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              controller:
                                  TextEditingController(text: part['ref'])
                                    ..selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: part['ref'].toString().length,
                                      ),
                                    ),
                              onChanged: (value) =>
                                  _updatePart(index, 'ref', value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppTheme.error,
                            ),
                            onPressed: () => _removePart(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Désignation',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        controller:
                            TextEditingController(text: part['designation'])
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: part['designation'].toString().length,
                                ),
                              ),
                        onChanged: (value) =>
                            _updatePart(index, 'designation', value),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: part['garantie'] ?? false,
                                  onChanged: (value) =>
                                      _updatePart(index, 'garantie', value),
                                ),
                                const Text('Garantie'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Quantité',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              controller:
                                  TextEditingController(
                                      text: part['qte'].toString(),
                                    )
                                    ..selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: part['qte'].toString().length,
                                      ),
                                    ),
                              onChanged: (value) {
                                final qte = int.tryParse(value) ?? 1;
                                _updatePart(index, 'qte', qte);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
