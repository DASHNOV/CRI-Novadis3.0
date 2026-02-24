import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/utils/form_validators.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_service_controller.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_projet_controller.dart';
import 'package:novadis_cri/features/cri_form/widgets/photo_picker.dart';
import 'package:novadis_cri/features/cri_form/widgets/signature_pad.dart';
import 'package:novadis_cri/features/cri_form/widgets/priority_chip.dart';
import 'package:novadis_cri/data/repositories/site_summary_repository.dart';
import 'package:novadis_cri/data/models/site_summary_model.dart';
import 'package:novadis_cri/features/cri_form/widgets/site_summary_card.dart';
import 'dart:async';

/// Page de formulaire CRI Service avec 8 sections
class CriServiceFormPage extends ConsumerStatefulWidget {
  final String? criId; // null pour nouveau, string pour édition

  const CriServiceFormPage({super.key, this.criId});

  @override
  ConsumerState<CriServiceFormPage> createState() => _CriServiceFormPageState();
}

class _CriServiceFormPageState extends ConsumerState<CriServiceFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  final bool _autoSaveEnabled = true;

  Timer? _debounceTimer;
  SiteSummaryModel? _siteSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForm();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSiteSummary(String siteName) async {
    if (siteName.trim().length < 3) {
      setState(() => _siteSummary = null);
      return;
    }

    try {
      final repo = ref.read(siteSummaryRepositoryProvider);
      final summary = await repo.getSummary(siteName.trim());
      if (mounted) {
        setState(() => _siteSummary = summary);
      }
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  void _initForm() {
    final technicianName = ref.read(currentTechnicianNameProvider);
    final controller = ref.read(criServiceFormProvider.notifier);

    if (widget.criId != null) {
      controller.loadCri(widget.criId!);
    } else {
      controller.initNewForm(technicianName: technicianName);
    }
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      await ref.read(criServiceFormProvider.notifier).saveDraft();
    }
  }

  void _onStepContinue() {
    if (_currentStep < 8) {
      setState(() => _currentStep++);
      _autoSave();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Valide tous les champs du formulaire, y compris ceux hors FormBuilder
  String? _validateCompleteForm() {
    final state = ref.read(criServiceFormProvider);
    final cri = state.currentCri;

    if (cri == null) {
      return 'Erreur: formulaire non initialisé';
    }

    // Vérifier la signature technicien
    if (cri.technicianSignature == null || cri.technicianSignature!.isEmpty) {
      return 'La signature du technicien est requise';
    }

    // Vérifier la signature client
    if (cri.clientSignature == null || cri.clientSignature!.isEmpty) {
      return 'La signature du client est requise';
    }

    // Vérifier le diagnostic réalisé
    if (cri.diagnosticPerformed == null || cri.diagnosticPerformed!.isEmpty) {
      return 'Le diagnostic réalisé est requis';
    }

    return null; // Tout est OK
  }

  Future<void> _submit() async {
    // D'abord valider les champs FormBuilder
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      // Identifier quel champ pose problème
      String errorMessage = 'Veuillez corriger les erreurs';
      final fields = _formKey.currentState!.fields;
      for (var entry in fields.entries) {
        if (entry.value.hasError) {
          errorMessage = 'Erreur: ${entry.value.errorText ?? entry.key}';
          break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Ensuite valider les champs personnalisés (signatures, satisfaction)
    final customValidationError = _validateCompleteForm();
    if (customValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customValidationError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Soumission en cours...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Tout est valide, soumettre
    final success = await ref.read(criServiceFormProvider.notifier).submit();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CRI Service enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final state = ref.read(criServiceFormProvider);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Erreur lors de la soumission'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Détails',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Détails de l\'erreur'),
                  content: Text(state.errorMessage ?? 'Erreur inconnue'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(criServiceFormProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('CRI Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.criId == null ? 'Nouveau CRI Service' : 'Modifier CRI Service',
        ),
        actions: [
          if (state.currentCri != null)
            PriorityChip(priority: state.currentCri!.priority, showIcon: true),
          if (state.isDirty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () =>
                  ref.read(criServiceFormProvider.notifier).saveDraft(),
              tooltip: 'Sauvegarder brouillon',
            ),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: _siteSummary != null ? 120 : 0),
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _onStepContinue,
                  onStepCancel: _onStepCancel,
                  onStepTapped: (index) => setState(() => _currentStep = index),
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (_currentStep < 8)
                            FilledButton(
                              onPressed: details.onStepContinue,
                              child: const Text('Suivant'),
                            )
                          else
                            FilledButton(
                              onPressed: state.isSaving ? null : _submit,
                              child: state.isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Soumettre'),
                            ),
                          const SizedBox(width: 12),
                          if (_currentStep > 0)
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Précédent'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    _buildGeneralStep(state, theme),
                    _buildClientStep(state, theme),
                    _buildRequestStep(state, theme),
                    _buildDiagnosticStep(state, theme),
                    _buildInterventionStep(state, theme),
                    _buildResultStep(state, theme),
                    _buildSecurityStep(state, theme),
                    _buildFollowUpStep(state, theme),
                    _buildValidationStep(state, theme),
                  ],
                ),
              ),
            ),
            if (_siteSummary != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SiteSummaryCard(
                    summary: _siteSummary!,
                    onDismiss: () => setState(() => _siteSummary = null),
                    onSeeHistory: () {
                      context.push('/history');
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: state.lastAutoSave != null
          ? Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                'Dernière sauvegarde: ${DateFormat('HH:mm').format(state.lastAutoSave!)}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }

  /// Section 1: Informations générales
  Step _buildGeneralStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Général'),
      subtitle: const Text('Date, heures et ticket'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date d\'intervention *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderDateTimePicker(
            name: 'interventionDate',
            initialValue: state.currentCri?.interventionDate ?? DateTime.now(),
            decoration: const InputDecoration(
              hintText: 'Date d\'intervention',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            inputType: InputType.date,
            format: DateFormat('dd/MM/yyyy'),
            validator: FormBuilderValidators.required(
              errorText: 'Date requise',
            ),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateGeneralInfo(interventionDate: value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heure début *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'startTime',
                      initialValue:
                          state.currentCri?.startTime ?? DateTime.now(),
                      decoration: const InputDecoration(
                        hintText: 'Heure début',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      inputType: InputType.time,
                      format: DateFormat('HH:mm'),
                      validator: FormBuilderValidators.required(
                        errorText: 'Requise',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(criServiceFormProvider.notifier)
                              .updateGeneralInfo(startTime: value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heure fin *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'endTime',
                      initialValue:
                          state.currentCri?.endTime ??
                          DateTime.now().add(const Duration(hours: 1)),
                      decoration: const InputDecoration(
                        hintText: 'Heure fin',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      inputType: InputType.time,
                      format: DateFormat('HH:mm'),
                      validator: FormBuilderValidators.required(
                        errorText: 'Requise',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(criServiceFormProvider.notifier)
                              .updateGeneralInfo(endTime: value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.currentCri != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Durée calculée: ${state.currentCri!.formattedDuration}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Numéro de ticket *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'ticketNumber',
            initialValue: state.currentCri?.ticketNumber ?? '',
            decoration: InputDecoration(
              hintText: 'Numéro de ticket',
              prefixIcon: const Icon(Icons.confirmation_number),
              helperText: 'Format: TICK-YYYY-NNNNN',
              suffixIcon: Tooltip(
                message: 'Ex: TICK-2024-00001',
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            validator: CriFormValidators.ticketNumber(),
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateGeneralInfo(ticketNumber: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 2: Informations client
  Step _buildClientStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Client'),
      subtitle: const Text('Informations client'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nom du client *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientName',
            initialValue: state.currentCri?.clientName ?? '',
            decoration: const InputDecoration(
              hintText: 'Nom du client',
              prefixIcon: Icon(Icons.business),
            ),
            validator: FormBuilderValidators.required(errorText: 'Nom requis'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(clientName: value);
            },
          ),
          const SizedBox(height: 16),
          Text('Site *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'site',
            initialValue: state.currentCri?.site ?? '',
            decoration: const InputDecoration(
              hintText: 'Site',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: FormBuilderValidators.required(errorText: 'Site requis'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(site: value);

              if (value != null) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                  _fetchSiteSummary(value);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Adresse *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'address',
            initialValue: state.currentCri?.address ?? '',
            decoration: const InputDecoration(
              hintText: 'Adresse',
              prefixIcon: Icon(Icons.home),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Adresse requise',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(address: value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ville *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'ville',
                      initialValue: state.currentCri?.ville ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Ville',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: FormBuilderValidators.required(
                        errorText: 'Ville requise',
                      ),
                      onChanged: (value) {
                        ref
                            .read(criServiceFormProvider.notifier)
                            .updateClientInfo(ville: value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Département *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'departement',
                      initialValue: state.currentCri?.departement ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Département',
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: FormBuilderValidators.required(
                        errorText: 'Requis',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        ref
                            .read(criServiceFormProvider.notifier)
                            .updateClientInfo(departement: value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Contact client *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientContact',
            initialValue: state.currentCri?.clientContact ?? '',
            decoration: const InputDecoration(
              hintText: 'Contact client',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Contact requis',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(clientContact: value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Téléphone *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'phone',
                      initialValue: state.currentCri?.phone ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Téléphone requis',
                        ),
                        CriFormValidators.frenchPhone(),
                      ]),
                      onChanged: (value) {
                        ref
                            .read(criServiceFormProvider.notifier)
                            .updateClientInfo(phone: value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      initialValue: state.currentCri?.email ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: CriFormValidators.email(required: true),
                      onChanged: (value) {
                        ref
                            .read(criServiceFormProvider.notifier)
                            .updateClientInfo(email: value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 3: Demande
  Step _buildRequestStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Demande'),
      subtitle: const Text('Type et priorité'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type de demande *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderDropdown<ServiceRequestType>(
            name: 'requestType',
            initialValue:
                state.currentCri?.requestType ?? ServiceRequestType.depannage,
            decoration: const InputDecoration(
              hintText: 'Type de demande',
              prefixIcon: Icon(Icons.category),
            ),
            items: ServiceRequestType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateRequestInfo(requestType: value);
              }
            },
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Text('Priorité *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          PrioritySelector(
            selectedPriority: state.currentCri?.priority,
            onPriorityChanged: (priority) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateRequestInfo(priority: priority);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Description de la demande *',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'requestDescription',
            initialValue: state.currentCri?.requestDescription ?? '',
            decoration: const InputDecoration(
              hintText: 'Description de la demande',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Description requise'),
              FormBuilderValidators.minLength(
                10,
                errorText: 'Minimum 10 caractères',
              ),
            ]),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateRequestInfo(requestDescription: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 4: Diagnostic
  Step _buildDiagnosticStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Diagnostic'),
      subtitle: const Text('Analyse du problème'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostic réalisé *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'diagnosticPerformed',
            initialValue: state.currentCri?.diagnosticPerformed ?? '',
            decoration: const InputDecoration(
              hintText: 'Diagnostic réalisé',
              prefixIcon: Icon(Icons.search),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: FormBuilderValidators.required(
              errorText: 'Diagnostic requis',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateDiagnosticInfo(diagnosticPerformed: value);
            },
          ),
          const SizedBox(height: 16),
          Text('Cause identifiée', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'identifiedCause',
            initialValue: state.currentCri?.identifiedCause ?? '',
            decoration: const InputDecoration(
              hintText: 'Cause identifiée',
              prefixIcon: Icon(Icons.find_in_page),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateDiagnosticInfo(identifiedCause: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 5: Intervention
  Step _buildInterventionStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Intervention'),
      subtitle: const Text('Actions réalisées'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions réalisées *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'actionsPerformed',
            initialValue: state.currentCri?.actionsPerformed ?? '',
            decoration: const InputDecoration(
              hintText: 'Actions réalisées',
              prefixIcon: Icon(Icons.build),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            validator: FormBuilderValidators.required(errorText: 'Requis'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateInterventionInfo(actionsPerformed: value);
            },
          ),
          const SizedBox(height: 16),
          Text('Pièces remplacées', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'replacedParts',
            initialValue: state.currentCri?.replacedParts ?? '',
            decoration: const InputDecoration(
              hintText: 'Résumé des pièces remplacées',
              prefixIcon: Icon(Icons.settings_input_component),
              alignLabelWithHint: true,
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateInterventionInfo(replacedParts: value);
            },
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Text(
            'Durée intervention (minutes)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'interventionDurationMinutes',
            initialValue:
                state.currentCri?.interventionDurationMinutes.toString() ??
                '60',
            decoration: InputDecoration(
              hintText: '60',
              prefixIcon: const Icon(Icons.timer),
              suffixText: 'min',
              helperText: 'Calculé automatiquement, modifiable',
              helperStyle: TextStyle(color: theme.colorScheme.outline),
            ),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.numeric(
              errorText: 'Nombre invalide',
            ),
            onChanged: (value) {
              final duration = int.tryParse(value ?? '');
              if (duration != null) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateInterventionInfo(
                      interventionDurationMinutes: duration,
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Section 6: Résultat
  Step _buildResultStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Résultat'),
      subtitle: const Text('Statut et tests'),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statut de résolution *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderDropdown<ResolutionStatus>(
            name: 'resolutionStatus',
            initialValue:
                state.currentCri?.resolutionStatus ??
                ResolutionStatus.nonResolu,
            decoration: const InputDecoration(
              hintText: 'Statut de résolution',
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
            items: ResolutionStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateResultInfo(resolutionStatus: value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Tests effectués', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'testsPerformed',
            initialValue: state.currentCri?.testsPerformed ?? '',
            decoration: const InputDecoration(
              hintText: 'Tests effectués',
              prefixIcon: Icon(Icons.science),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateResultInfo(testsPerformed: value);
            },
          ),
          const SizedBox(height: 16),
          Text('Recommandations', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'recommendations',
            initialValue: state.currentCri?.recommendations ?? '',
            decoration: const InputDecoration(
              hintText: 'Recommandations',
              prefixIcon: Icon(Icons.recommend),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateResultInfo(recommendations: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 7: Sécurité
  Step _buildSecurityStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Sécurité'),
      subtitle: const Text('Cybersécurité'),
      isActive: _currentStep >= 6,
      state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommandations Cybersécurité',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'cybersecurityRecommendations',
            initialValue: state.currentCri?.cybersecurityRecommendations ?? '',
            decoration: const InputDecoration(
              hintText: 'Suggestions de cybersécurité (optionnel)',
              prefixIcon: Icon(Icons.security),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateResultInfo(cybersecurityRecommendations: value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Laissez vide si aucune recommandation.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  /// Section 8: Suivi
  Step _buildFollowUpStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Suivi'),
      subtitle: const Text('Actions et statut'),
      isActive: _currentStep >= 7,
      state: _currentStep > 7 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderSwitch(
            name: 'additionalInterventionRequired',
            initialValue:
                state.currentCri?.additionalInterventionRequired ?? false,
            title: const Text('Intervention supplémentaire requise'),
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateFollowUpInfo(additionalInterventionRequired: value);
            },
          ),
          if (state.currentCri?.additionalInterventionRequired ?? false) ...[
            const SizedBox(height: 16),
            Text('Date de suivi *', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            FormBuilderDateTimePicker(
              name: 'followUpDate',
              initialValue: state.currentCri?.followUpDate,
              decoration: const InputDecoration(
                hintText: 'Date de suivi',
                prefixIcon: Icon(Icons.event),
              ),
              inputType: InputType.date,
              format: DateFormat('dd/MM/yyyy'),
              validator:
                  (state.currentCri?.additionalInterventionRequired ?? false)
                  ? FormBuilderValidators.required(errorText: 'Date requise')
                  : null,
              onChanged: (value) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateFollowUpInfo(followUpDate: value);
              },
            ),
            const SizedBox(height: 16),
            Text('Commentaires de suivi', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'followUpComments',
              initialValue: state.currentCri?.followUpComments ?? '',
              decoration: const InputDecoration(
                hintText: 'Commentaires de suivi',
                prefixIcon: Icon(Icons.comment),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateFollowUpInfo(followUpComments: value);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Section 9: Validation
  Step _buildValidationStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Validation'),
      subtitle: const Text('Signatures et photos'),
      isActive: _currentStep >= 8,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoPicker(
            initialPhotos: state.currentCri?.photos ?? [],
            maxPhotos: 5,
            onPhotosChanged: (photos) {
              ref.read(criServiceFormProvider.notifier).updatePhotos(photos);
            },
          ),
          const SizedBox(height: 24),
          Text('Nom du technicien *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'technicianName',
            initialValue: state.currentCri?.technicianName ?? '',
            decoration: const InputDecoration(
              hintText: 'Nom du technicien',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormBuilderValidators.required(errorText: 'Nom requis'),
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateTechnicianName(value);
            },
          ),
          const SizedBox(height: 24),
          SignaturePadWidget(
            label: 'Signature technicien *',
            initialSignaturePath: state.currentCri?.technicianSignature,
            onSignatureSaved: (path) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateTechnicianSignature(path);
            },
          ),
          const SizedBox(height: 24),
          SignaturePadWidget(
            label: 'Signature client *',
            initialSignaturePath: state.currentCri?.clientSignature,
            onSignatureSaved: (path) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientSignature(path);
            },
          ),
        ],
      ),
    );
  }
}
