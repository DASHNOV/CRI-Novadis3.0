import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/local/local_storage_service.dart';

/// Écran de création/édition d'un CRI
/// Formulaire avec validation pour créer un nouveau compte rendu d'intervention
class CriFormScreen extends HookWidget {
  const CriFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final clientController = useTextEditingController();
    final siteController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedType = useState<String>('Maintenance préventive');
    final selectedDate = useState<DateTime>(DateTime.now());
    final isLoading = useState(false);
    final storageService = useMemoized(() => LocalStorageService());

    final typeInterventions = [
      'Maintenance préventive',
      'Maintenance corrective',
      'Dépannage',
      'Installation',
      'Mise en service',
      'Contrôle',
      'Autre',
    ];

    Future<void> selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        locale: const Locale('fr', 'FR'),
      );
      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) {
        return;
      }

      isLoading.value = true;

      // Créer le nouveau CRI
      final newCri = CriModel(
        id: storageService.generateId(),
        client: clientController.text.trim(),
        site: siteController.text.trim(),
        typeIntervention: selectedType.value,
        description: descriptionController.text.trim(),
        date: selectedDate.value,
        createdAt: DateTime.now(),
      );

      // Sauvegarder
      final success = await storageService.addCri(newCri);

      isLoading.value = false;

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CRI créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du CRI'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau CRI')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Champ Client
              TextFormField(
                controller: clientController,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  hintText: 'Nom du client',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le client est requis';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Champ Site
              TextFormField(
                controller: siteController,
                decoration: const InputDecoration(
                  labelText: 'Site *',
                  hintText: 'Localisation du site',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le site est requis';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Type d'intervention
              DropdownButtonFormField<String>(
                value: selectedType.value,
                decoration: const InputDecoration(
                  labelText: 'Type d\'intervention *',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                items: typeInterventions.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedType.value = newValue;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date d'intervention
              InkWell(
                onTap: selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'intervention *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate.value),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Détails de l\'intervention',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  if (value.trim().length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              ElevatedButton(
                onPressed: isLoading.value ? null : handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Enregistrer le CRI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Note
              Text(
                '* Champs obligatoires',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
