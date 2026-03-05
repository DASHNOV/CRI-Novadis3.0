import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:novadis_cri/core/utils/file_utils.dart';

final _fileUtils = createFileUtils();

/// Widget pour sélectionner et afficher des photos
/// Maximum 5 photos avec compression automatique
class PhotoPicker extends StatefulWidget {
  final List<String> initialPhotos;
  final int maxPhotos;
  final ValueChanged<List<String>> onPhotosChanged;
  final bool enabled;

  const PhotoPicker({
    super.key,
    this.initialPhotos = const [],
    this.maxPhotos = 5,
    required this.onPhotosChanged,
    this.enabled = true,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  late List<String> _photos;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  @override
  void didUpdateWidget(PhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotos != widget.initialPhotos) {
      setState(() {
        _photos = List.from(widget.initialPhotos);
      });
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_photos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxPhotos} photos autorisées'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80, // Compression automatique
      );

      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
        widget.onPhotosChanged(_photos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.camera_alt)),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_library)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPhoto(String photoPath, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewScreen(
          photoPath: photoPath,
          onDelete: widget.enabled
              ? () {
                  Navigator.pop(context);
                  _removePhoto(index);
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = _photos.length < widget.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${_photos.length}/${widget.maxPhotos})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.enabled && canAddMore)
              TextButton.icon(
                onPressed: _isLoading ? null : _showPhotoOptions,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                label: const Text('Ajouter'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: widget.enabled ? _showPhotoOptions : null,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter des photos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  _photos.length + (canAddMore && widget.enabled ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Bouton d'ajout à la fin
                if (index == _photos.length) {
                  return _AddPhotoButton(
                    onTap: _isLoading ? null : _showPhotoOptions,
                    isLoading: _isLoading,
                  );
                }

                // Photo existante
                return _PhotoThumbnail(
                  photoPath: _photos[index],
                  onTap: () => _viewPhoto(_photos[index], index),
                  onDelete: widget.enabled ? () => _removePhoto(index) : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Thumbnail d'une photo
class _PhotoThumbnail extends StatelessWidget {
  final String photoPath;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PhotoThumbnail({
    required this.photoPath,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                ? Image.network(
                    photoPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.errorContainer,
                      child: const Icon(Icons.broken_image, color: Colors.red),
                    ),
                  )
                : _fileUtils.getFileWidget(photoPath),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bouton d'ajout de photo
class _AddPhotoButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _AddPhotoButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Ajouter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Écran de visualisation d'une photo
class PhotoViewScreen extends StatelessWidget {
  final String photoPath;
  final VoidCallback? onDelete;

  const PhotoViewScreen({super.key, required this.photoPath, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer la photo ?'),
                    content: const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: kIsWeb
            ? Image.network(
                photoPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                ),
              )
            : _fileUtils.getFileWidget(photoPath),
        ),
      ),
    );
  }
}




