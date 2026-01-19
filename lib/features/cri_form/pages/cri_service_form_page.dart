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
  bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForm();
    });
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
    if (_currentStep < 7) {
      setState(() => _currentStep++);
      _autoSave();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final success = await ref.read(criServiceFormProvider.notifier).submit();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CRI Service enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs'),
          backgroundColor: Colors.orange,
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
                  if (_currentStep < 7)
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
            _buildFollowUpStep(state, theme),
            _buildValidationStep(state, theme),
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
          FormBuilderDateTimePicker(
            name: 'interventionDate',
            initialValue: state.currentCri?.interventionDate ?? DateTime.now(),
            decoration: const InputDecoration(
              labelText: 'Date d\'intervention *',
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
                child: FormBuilderDateTimePicker(
                  name: 'startTime',
                  initialValue: state.currentCri?.startTime ?? DateTime.now(),
                  decoration: const InputDecoration(
                    labelText: 'Heure début *',
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderDateTimePicker(
                  name: 'endTime',
                  initialValue:
                      state.currentCri?.endTime ??
                      DateTime.now().add(const Duration(hours: 1)),
                  decoration: const InputDecoration(
                    labelText: 'Heure fin *',
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
          FormBuilderTextField(
            name: 'ticketNumber',
            initialValue: state.currentCri?.ticketNumber ?? '',
            decoration: InputDecoration(
              labelText: 'Numéro de ticket *',
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
          FormBuilderTextField(
            name: 'clientName',
            initialValue: state.currentCri?.clientName ?? '',
            decoration: const InputDecoration(
              labelText: 'Nom du client *',
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
          FormBuilderTextField(
            name: 'site',
            initialValue: state.currentCri?.site ?? '',
            decoration: const InputDecoration(
              labelText: 'Site *',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: FormBuilderValidators.required(errorText: 'Site requis'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(site: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'address',
            initialValue: state.currentCri?.address ?? '',
            decoration: const InputDecoration(
              labelText: 'Adresse *',
              prefixIcon: Icon(Icons.home),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Adresse requise',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            onChanged: (value) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientInfo(address: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'clientContact',
            initialValue: state.currentCri?.clientContact ?? '',
            decoration: const InputDecoration(
              labelText: 'Contact client *',
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
          FormBuilderTextField(
            name: 'phone',
            initialValue: state.currentCri?.phone ?? '',
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Téléphone requis'),
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
          FormBuilderDropdown<ServiceRequestType>(
            name: 'requestType',
            initialValue:
                state.currentCri?.requestType ?? ServiceRequestType.depannage,
            decoration: const InputDecoration(
              labelText: 'Type de demande *',
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
          FormBuilderTextField(
            name: 'requestDescription',
            initialValue: state.currentCri?.requestDescription ?? '',
            decoration: const InputDecoration(
              labelText: 'Description de la demande *',
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
          FormBuilderTextField(
            name: 'diagnosticPerformed',
            initialValue: state.currentCri?.diagnosticPerformed ?? '',
            decoration: const InputDecoration(
              labelText: 'Diagnostic réalisé *',
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
          FormBuilderTextField(
            name: 'identifiedCause',
            initialValue: state.currentCri?.identifiedCause ?? '',
            decoration: const InputDecoration(
              labelText: 'Cause identifiée',
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
          FormBuilderTextField(
            name: 'actionsPerformed',
            initialValue: state.currentCri?.actionsPerformed ?? '',
            decoration: const InputDecoration(
              labelText: 'Actions réalisées *',
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
          FormBuilderTextField(
            name: 'replacedParts',
            initialValue: state.currentCri?.replacedParts ?? '',
            decoration: const InputDecoration(
              labelText: 'Pièces remplacées',
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
          FormBuilderTextField(
            name: 'interventionDurationMinutes',
            initialValue:
                state.currentCri?.interventionDurationMinutes.toString() ??
                '60',
            decoration: InputDecoration(
              labelText: 'Durée intervention (minutes)',
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
          FormBuilderDropdown<ResolutionStatus>(
            name: 'resolutionStatus',
            initialValue:
                state.currentCri?.resolutionStatus ??
                ResolutionStatus.nonResolu,
            decoration: const InputDecoration(
              labelText: 'Statut de résolution *',
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
          FormBuilderTextField(
            name: 'testsPerformed',
            initialValue: state.currentCri?.testsPerformed ?? '',
            decoration: const InputDecoration(
              labelText: 'Tests réalisés',
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
          FormBuilderTextField(
            name: 'recommendations',
            initialValue: state.currentCri?.recommendations ?? '',
            decoration: const InputDecoration(
              labelText: 'Recommandations',
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

  /// Section 7: Suivi
  Step _buildFollowUpStep(CriServiceFormState state, ThemeData theme) {
    final showFollowUpFields =
        state.currentCri?.additionalInterventionRequired ?? false;

    return Step(
      title: const Text('Suivi'),
      subtitle: const Text('Intervention supplémentaire'),
      isActive: _currentStep >= 6,
      state: _currentStep > 6 ? StepState.complete : StepState.indexed,
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
          if (showFollowUpFields) ...[
            const SizedBox(height: 16),
            FormBuilderDateTimePicker(
              name: 'followUpDate',
              initialValue: state.currentCri?.followUpDate,
              decoration: const InputDecoration(
                labelText: 'Date de suivi *',
                prefixIcon: Icon(Icons.event),
              ),
              inputType: InputType.date,
              format: DateFormat('dd/MM/yyyy'),
              validator: showFollowUpFields
                  ? FormBuilderValidators.required(errorText: 'Date requise')
                  : null,
              onChanged: (value) {
                ref
                    .read(criServiceFormProvider.notifier)
                    .updateFollowUpInfo(followUpDate: value);
              },
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'followUpComments',
              initialValue: state.currentCri?.followUpComments ?? '',
              decoration: const InputDecoration(
                labelText: 'Commentaires de suivi',
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

  /// Section 8: Validation
  Step _buildValidationStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Validation'),
      subtitle: const Text('Signatures et satisfaction'),
      isActive: _currentStep >= 7,
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
          FormBuilderTextField(
            name: 'technicianName',
            initialValue: state.currentCri?.technicianName ?? '',
            decoration: const InputDecoration(
              labelText: 'Nom du technicien *',
              prefixIcon: Icon(Icons.person),
            ),
            enabled: false, // Pré-rempli
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
          const SizedBox(height: 24),
          Text('Satisfaction client *', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildSatisfactionSelector(state, theme),
        ],
      ),
    );
  }

  /// Widget de sélection de satisfaction client
  Widget _buildSatisfactionSelector(
    CriServiceFormState state,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ClientSatisfaction.values.map((satisfaction) {
        final isSelected = state.currentCri?.clientSatisfaction == satisfaction;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                satisfaction.rating,
                (index) => Icon(
                  Icons.star,
                  size: 16,
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref
                  .read(criServiceFormProvider.notifier)
                  .updateClientSatisfaction(satisfaction);
            }
          },
          tooltip: satisfaction.label,
        );
      }).toList(),
    );
  }
}
