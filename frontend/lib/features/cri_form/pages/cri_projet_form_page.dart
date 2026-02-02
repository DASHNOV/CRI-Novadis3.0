import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/utils/form_validators.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_projet_controller.dart';
import 'package:novadis_cri/features/cri_form/widgets/photo_picker.dart';
import 'package:novadis_cri/features/cri_form/widgets/signature_pad.dart';

/// Page de formulaire CRI Projet avec 6 sections
class CriProjetFormPage extends ConsumerStatefulWidget {
  final String? criId; // null pour nouveau, string pour édition

  const CriProjetFormPage({super.key, this.criId});

  @override
  ConsumerState<CriProjetFormPage> createState() => _CriProjetFormPageState();
}

class _CriProjetFormPageState extends ConsumerState<CriProjetFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  final bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForm();
    });
  }

  void _initForm() {
    final technicianName = ref.read(currentTechnicianNameProvider);
    final controller = ref.read(criProjetFormProvider.notifier);

    if (widget.criId != null) {
      controller.loadCri(widget.criId!);
    } else {
      controller.initNewForm(technicianName: technicianName);
    }
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      await ref.read(criProjetFormProvider.notifier).saveDraft();
    }
  }

  void _onStepContinue() {
    if (_currentStep < 5) {
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
      final success = await ref.read(criProjetFormProvider.notifier).submit();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CRI Projet enregistré avec succès'),
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
    final state = ref.watch(criProjetFormProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('CRI Projet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.criId == null ? 'Nouveau CRI Projet' : 'Modifier CRI Projet',
        ),
        actions: [
          if (state.isDirty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () =>
                  ref.read(criProjetFormProvider.notifier).saveDraft(),
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
                  if (_currentStep < 5)
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
            _buildProjectStep(state, theme),
            _buildInterventionStep(state, theme),
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
  Step _buildGeneralStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Général'),
      subtitle: const Text('Date et heures'),
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
                    .read(criProjetFormProvider.notifier)
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
                          .read(criProjetFormProvider.notifier)
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
                          .read(criProjetFormProvider.notifier)
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
                'Durée: ${state.currentCri!.formattedDuration}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section 2: Informations client
  Step _buildClientStep(CriProjetFormState state, ThemeData theme) {
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
                  .read(criProjetFormProvider.notifier)
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
                  .read(criProjetFormProvider.notifier)
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
                  .read(criProjetFormProvider.notifier)
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
                  .read(criProjetFormProvider.notifier)
                  .updateClientInfo(clientContact: value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'phone',
                  initialValue: state.currentCri?.phone ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
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
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(phone: value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'email',
                  initialValue: state.currentCri?.email ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: CriFormValidators.email(required: true),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(email: value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 3: Informations projet
  Step _buildProjectStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Projet'),
      subtitle: const Text('Détails du projet'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderTextField(
            name: 'projectName',
            initialValue: state.currentCri?.projectName ?? '',
            decoration: const InputDecoration(
              labelText: 'Nom du projet *',
              prefixIcon: Icon(Icons.folder),
            ),
            validator: FormBuilderValidators.required(errorText: 'Nom requis'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateProjectInfo(projectName: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'projectNumber',
            initialValue: state.currentCri?.projectNumber ?? '',
            decoration: InputDecoration(
              labelText: 'Numéro de projet *',
              prefixIcon: const Icon(Icons.tag),
              helperText: 'Format: PRJ-YYYY-NNN',
              suffixIcon: Tooltip(
                message: 'Ex: PRJ-2024-001',
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            validator: CriFormValidators.projectNumber(),
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateProjectInfo(projectNumber: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderDropdown<ProjectPhase>(
            name: 'projectPhase',
            initialValue: state.currentCri?.projectPhase ?? ProjectPhase.etude,
            decoration: const InputDecoration(
              labelText: 'Phase du projet *',
              prefixIcon: Icon(Icons.timeline),
            ),
            items: ProjectPhase.values.map((phase) {
              return DropdownMenuItem(value: phase, child: Text(phase.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateProjectInfo(projectPhase: value);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Section 4: Intervention
  Step _buildInterventionStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Intervention'),
      subtitle: const Text('Travaux réalisés'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderDropdown<ProjetInterventionType>(
            name: 'interventionType',
            initialValue:
                state.currentCri?.interventionType ??
                ProjetInterventionType.installationMateriel,
            decoration: const InputDecoration(
              labelText: 'Type d\'intervention *',
              prefixIcon: Icon(Icons.build),
            ),
            items: ProjetInterventionType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateInterventionInfo(interventionType: value);
              }
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'workDescription',
            initialValue: state.currentCri?.workDescription ?? '',
            decoration: const InputDecoration(
              labelText: 'Description des travaux *',
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
                  .read(criProjetFormProvider.notifier)
                  .updateInterventionInfo(workDescription: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'materialsUsed',
            initialValue: state.currentCri?.materialsUsed ?? '',
            decoration: const InputDecoration(
              labelText: 'Matériels utilisés',
              prefixIcon: Icon(Icons.inventory),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateInterventionInfo(materialsUsed: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'problemsEncountered',
            initialValue: state.currentCri?.problemsEncountered ?? '',
            decoration: const InputDecoration(
              labelText: 'Problèmes rencontrés',
              prefixIcon: Icon(Icons.warning_amber),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateInterventionInfo(problemsEncountered: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'solutionsProvided',
            initialValue: state.currentCri?.solutionsProvided ?? '',
            decoration: const InputDecoration(
              labelText: 'Solutions apportées',
              prefixIcon: Icon(Icons.lightbulb_outline),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateInterventionInfo(solutionsProvided: value);
            },
          ),
        ],
      ),
    );
  }

  /// Section 5: Suivi
  Step _buildFollowUpStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Suivi'),
      subtitle: const Text('Actions et statut'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormBuilderTextField(
            name: 'actionsToDo',
            initialValue: state.currentCri?.actionsToDo ?? '',
            decoration: const InputDecoration(
              labelText: 'Actions à faire',
              prefixIcon: Icon(Icons.checklist),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateFollowUpInfo(actionsToDo: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderDateTimePicker(
            name: 'nextInterventionDate',
            initialValue: state.currentCri?.nextInterventionDate,
            decoration: const InputDecoration(
              labelText: 'Prochaine intervention',
              prefixIcon: Icon(Icons.event),
            ),
            inputType: InputType.date,
            format: DateFormat('dd/MM/yyyy'),
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateFollowUpInfo(nextInterventionDate: value);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderDropdown<ProjectStatus>(
            name: 'projectStatus',
            initialValue:
                state.currentCri?.projectStatus ?? ProjectStatus.enCours,
            decoration: const InputDecoration(
              labelText: 'Statut du projet *',
              prefixIcon: Icon(Icons.flag),
            ),
            items: ProjectStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateFollowUpInfo(projectStatus: value);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Section 6: Validation
  Step _buildValidationStep(CriProjetFormState state, ThemeData theme) {
    return Step(
      title: const Text('Validation'),
      subtitle: const Text('Signatures et photos'),
      isActive: _currentStep >= 5,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoPicker(
            initialPhotos: state.currentCri?.photos ?? [],
            maxPhotos: 5,
            onPhotosChanged: (photos) {
              ref.read(criProjetFormProvider.notifier).updatePhotos(photos);
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
                  .read(criProjetFormProvider.notifier)
                  .updateTechnicianSignature(path);
            },
          ),
          const SizedBox(height: 24),
          SignaturePadWidget(
            label: 'Signature client *',
            initialSignaturePath: state.currentCri?.clientSignature,
            onSignatureSaved: (path) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientSignature(path);
            },
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'clientComments',
            initialValue: state.currentCri?.clientComments ?? '',
            decoration: const InputDecoration(
              labelText: 'Commentaires client',
              prefixIcon: Icon(Icons.comment),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientComments(value);
            },
          ),
        ],
      ),
    );
  }
}
