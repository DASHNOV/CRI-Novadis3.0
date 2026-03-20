import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Barre de recherche pour les documents
class DocumentSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const DocumentSearchBar({
    super.key,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<DocumentSearchBar> createState() => _DocumentSearchBarState();
}

class _DocumentSearchBarState extends State<DocumentSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, client, numéro...',
          hintStyle: TextStyle(color: AppTheme.textTertiary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textSecondary,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: AppTheme.textSecondary),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
              widget.onClose();
            },
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
