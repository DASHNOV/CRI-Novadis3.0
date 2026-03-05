import 'dart:typed_data';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

/// Widget pour capturer une signature
/// Permet de dessiner, effacer et sauvegarder en PNG
class SignaturePadWidget extends StatefulWidget {
  final String label;
  final String? initialSignaturePath;
  final ValueChanged<String?> onSignatureSaved;
  final bool enabled;
  final Color penColor;
  final double penStrokeWidth;

  const SignaturePadWidget({
    super.key,
    required this.label,
    this.initialSignaturePath,
    required this.onSignatureSaved,
    this.enabled = true,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late SignatureController _controller;
  String? _savedPath;
  bool _isSaving = false;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _savedPath = widget.initialSignaturePath;
    _hasSignature = _savedPath != null && _savedPath!.isNotEmpty;

    _controller = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor: Colors.white,
      onDrawStart: () {
        setState(() {
          _hasSignature = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _clearSignature() async {
    _controller.clear();
    setState(() {
      _savedPath = null;
      _hasSignature = false;
    });
    widget.onSignatureSaved(null);
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de sauvegarder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Uint8List? signature = await _controller.toPngBytes();

      if (signature == null) {
        throw Exception('Impossible de générer l\'image de signature');
      }

      if (kIsWeb) {
        // Sur le web, on ne sauvegarde pas dans le système de fichiers
        // On pourrait utiliser le localStorage ou simplement garder en mémoire
        // Pour l'instant, on simule une sauvegarde
        setState(() {
          _savedPath = 'web_signature_${DateTime.now().millisecondsSinceEpoch}';
        });
        widget.onSignatureSaved(_savedPath);
      } else {
        // Sauvegarder dans le dossier temporaire de l'app (Natif)
        final directory = await getApplicationDocumentsDirectory();
        final signatureDir = Directory('${directory.path}/signatures');

        if (!await signatureDir.exists()) {
          await signatureDir.create(recursive: true);
        }

        final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${signatureDir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(signature);

        setState(() {
          _savedPath = filePath;
        });

        widget.onSignatureSaved(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        label: widget.label,
        controller: _controller,
        onClear: () {
          _controller.clear();
        },
        onSave: () async {
          Navigator.pop(context);
          await _saveSignature();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
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
            Text(
              widget.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.enabled && _hasSignature)
              TextButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Effacer'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.enabled ? _showSignatureDialog : null,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasSignature
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: _hasSignature ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _savedPath != null && _savedPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb 
                      ? const Center(child: Text('Signature enregistrée (Web)'))
                      : Image.file(
                          File(_savedPath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(theme),
                        ),
                  )
                : _buildPlaceholder(theme),
          ),
        ),
        if (_isSaving)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enregistrement...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.draw_outlined, size: 32, color: theme.colorScheme.outline),
        const SizedBox(height: 8),
        Text(
          widget.enabled ? 'Appuyer pour signer' : 'Aucune signature',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Dialog de signature plein écran
class _SignatureDialog extends StatelessWidget {
  final String label;
  final SignatureController controller;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _SignatureDialog({
    required this.label,
    required this.controller,
    required this.onClear,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),

            // Zone de signature
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Indication
            Text(
              'Dessinez votre signature ci-dessus',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Effacer'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour prévisualiser une signature existante
class SignaturePreview extends StatelessWidget {
  final String? signaturePath;
  final String label;
  final double height;

  const SignaturePreview({
    super.key,
    this.signaturePath,
    required this.label,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSignature = signaturePath != null && signaturePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: hasSignature
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: kIsWeb
                    ? const Center(child: Text('Signé'))
                    : Image.file(
                        File(signaturePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                )
              : Center(
                  child: Text(
                    'Non signé',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

