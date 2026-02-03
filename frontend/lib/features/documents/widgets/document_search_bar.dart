import 'package:flutter/material.dart';

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
    return TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Rechercher par nom, client, numéro...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _controller.clear();
            widget.onChanged('');
            widget.onClose();
          },
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
