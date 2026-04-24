import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/utils/form_validators.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/cri_form/controllers/cri_projet_controller.dart';
import 'package:novadis_cri/features/cri_form/widgets/photo_picker.dart';
import 'package:novadis_cri/features/cri_form/widgets/signature_pad.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/features/cri_form/widgets/site_selector.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/cri_form/widgets/form_shared_widgets.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

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

  // Controllers pour auto-complétion des champs à la sélection d'un site
  final _addressController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
    super.dispose();
  }

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

    // Initialiser les controllers avec les valeurs existantes
    final cri = ref.read(criProjetFormProvider).currentCri;
    if (cri != null) {
      _addressController.text = cri.address ?? '';
      _villeController.text = cri.ville ?? '';
      _codePostalController.text = cri.codePostal ?? '';
      _paysController.text = cri.pays ?? '';
    }
  }

  /// Appelé quand un site est sélectionné depuis le dropdown.
  /// Auto-remplit les champs adresse, ville, code postal et pays.
  void _onSiteSelected(SiteModel site) {
    final notifier = ref.read(criProjetFormProvider.notifier);
    notifier.updateClientInfo(
      site: site.nomDuSite,
      address: site.adresse,
      ville: site.ville,
      codePostal: site.codePostal,
      pays: site.pays,
    );

    // Mettre à jour les controllers de texte
    _addressController.text = site.adresse ?? '';
    _villeController.text = site.ville ?? '';
    _codePostalController.text = site.codePostal ?? '';
    _paysController.text = site.pays ?? '';

    // Mettre à jour les champs FormBuilder
    _formKey.currentState?.fields['address']?.didChange(site.adresse ?? '');
    _formKey.currentState?.fields['ville']?.didChange(site.ville ?? '');
    _formKey.currentState?.fields['codePostal']?.didChange(site.codePostal ?? '');
    _formKey.currentState?.fields['pays']?.didChange(site.pays ?? '');
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    _formKey.currentState?.save();
    await ref.read(criProjetFormProvider.notifier).saveDraft();
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

  /// Valide tous les champs du formulaire, y compris ceux hors FormBuilder
  String? _validateCompleteForm() {
    final state = ref.read(criProjetFormProvider);
    final cri = state.currentCri;

    if (cri == null) {
      return 'Erreur: formulaire non initialisé';
    }

    // Vérifier qu'au moins un logiciel est sélectionné
    if (cri.softwares.isEmpty) {
      return 'Veuillez sélectionner au moins un logiciel utilisé';
    }

    // Vérifier la signature technicien
    if (cri.technicianSignature == null || cri.technicianSignature!.isEmpty) {
      return 'La signature du technicien est requise';
    }

    return null; // Tout est OK
  }

  Future<void> _submit() async {
    // D'abord valider les champs FormBuilder
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      final fields = _formKey.currentState?.fields ?? {};
      final errors = fields.entries
          .where((e) => e.value.hasError)
          .map((e) => '• ${e.value.errorText ?? ''}')
          .where((e) => e.isNotEmpty)
          .toList();
      final message = errors.isEmpty
          ? 'Veuillez corriger les erreurs dans le formulaire'
          : errors.join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Ensuite valider les champs personnalisés (signatures)
    final customValidationError = _validateCompleteForm();
    if (customValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customValidationError),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Tout est valide, soumettre
    final success = await ref.read(criProjetFormProvider.notifier).submit();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CRI Projet enregistré avec succès'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final state = ref.watch(criProjetFormProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const CriFormLoadingScaffold(title: 'CRI Projet');
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildCriFormAppBar(
        context: context,
        title: widget.criId == null ? 'Nouveau CRI Projet' : 'Modifier CRI Projet',
        isDirty: state.isDirty,
        onSaveDraft: () => ref.read(criProjetFormProvider.notifier).saveDraft(),
      ),
      body: FormBuilder(
        key: _formKey,
        child: ContentContainer(
          maxWidth: 900,
          child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (index) => setState(() => _currentStep = index),
          controlsBuilder: (context, details) => buildCriFormControls(
            context,
            details,
            currentStep: _currentStep,
            lastStep: 5,
            isSaving: state.isSaving,
            onSubmit: _submit,
          ),
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
      ),
      bottomNavigationBar: CriFormAutoSaveBar(lastAutoSave: state.lastAutoSave),
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
          Text('Date d\'intervention *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
                    .read(criProjetFormProvider.notifier)
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
                    Text('Heure début *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
                              .read(criProjetFormProvider.notifier)
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
                    Text('Heure fin *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
                              .read(criProjetFormProvider.notifier)
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
                'Durée: ${state.currentCri!.formattedDuration}',
                style: TextStyle(
                  color: AppTheme.primaryContent,
                  fontSize: 14,
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
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom du client *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderField<String>(
                  name: 'clientName',
                  initialValue: state.currentCri?.clientName ?? '',
                  validator: FormBuilderValidators.required(errorText: 'Nom requis'),
                  builder: (FormFieldState<String> field) {
                    return Autocomplete<String>(
                      initialValue: TextEditingValue(text: field.value ?? ''),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return await ref
                            .read(criRemoteRepositoryProvider)
                            .searchClients(textEditingValue.text);
                      },
                      onSelected: (String selection) {
                        field.didChange(selection);
                        ref
                            .read(criProjetFormProvider.notifier)
                            .updateClientInfo(clientName: selection);
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            if (textEditingController.text != field.value &&
                                field.value != null &&
                                !focusNode.hasFocus) {
                              textEditingController.text = field.value!;
                            }
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Nom du client',
                                prefixIcon: const Icon(Icons.business),
                                errorText: field.errorText,
                              ),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (val) {
                                field.didChange(val);
                                ref
                                    .read(criProjetFormProvider.notifier)
                                    .updateClientInfo(clientName: val);
                              },
                              onSubmitted: (_) => onFieldSubmitted(),
                            );
                          },
                    );
                  },
                ),
              ],
            );
            final field2 = SiteSelector(
              initialValue: state.currentCri?.site ?? '',
              repository: ref.read(criRemoteRepositoryProvider),
              onSiteSelected: _onSiteSelected,
              onSiteTextChanged: (val) {
                ref
                    .read(criProjetFormProvider.notifier)
                    .updateClientInfo(site: val);
              },
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field1),
                  const SizedBox(width: 16),
                  Expanded(child: field2),
                ],
              );
            }
            return Column(children: [field1, const SizedBox(height: 16), field2]);
          }),
          const SizedBox(height: 16),
          Text('Adresse *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'address',
            controller: _addressController,
            initialValue: null,
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
                  .read(criProjetFormProvider.notifier)
                  .updateClientInfo(address: value);
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final villeField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ville *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'ville',
                  controller: _villeController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Ville',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'Ville requise',
                  ),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(ville: value);
                  },
                ),
              ],
            );
            final codePostalField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code postal', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'codePostal',
                  controller: _codePostalController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Code postal',
                    prefixIcon: Icon(Icons.markunread_mailbox),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(codePostal: value);
                  },
                ),
              ],
            );
            final paysField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pays', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'pays',
                  controller: _paysController,
                  initialValue: null,
                  decoration: const InputDecoration(
                    hintText: 'Pays',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  onChanged: (value) {
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateClientInfo(pays: value);
                  },
                ),
              ],
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: villeField),
                  const SizedBox(width: 16),
                  Expanded(child: codePostalField),
                  const SizedBox(width: 16),
                  Expanded(child: paysField),
                ],
              );
            }
            return Column(children: [
              villeField,
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: codePostalField),
                const SizedBox(width: 16),
                Expanded(child: paysField),
              ]),
            ]);
          }),
          const SizedBox(height: 16),
          Text('Contact client', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientContact',
            initialValue: state.currentCri?.clientContact ?? '',
            decoration: const InputDecoration(
              hintText: 'Contact client',
              prefixIcon: Icon(Icons.person),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Téléphone', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'phone',
                      initialValue: state.currentCri?.phone ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: CriFormValidators.frenchPhone(),
                      onChanged: (value) {
                        ref
                            .read(criProjetFormProvider.notifier)
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
                    Text('Email', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      initialValue: state.currentCri?.email ?? '',
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: CriFormValidators.email(required: false),
                      onChanged: (value) {
                        ref
                            .read(criProjetFormProvider.notifier)
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
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom du projet *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'projectName',
                  initialValue: state.currentCri?.projectName ?? '',
                  decoration: const InputDecoration(
                    hintText: 'Nom du projet',
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
              ],
            );
            final field2 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Numéro de projet *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'projectNumber',
                  initialValue: state.currentCri?.projectNumber ?? '',
                  decoration: InputDecoration(
                    hintText: 'PRJ-YYYY-NNN',
                    prefixIcon: const Icon(Icons.tag),
                    helperText: 'Format: PRJ-YYYY-NNN',
                    suffixIcon: Tooltip(
                      message: 'Ex: PRJ-2024-001',
                      child: Icon(
                        Icons.info_outline,
                        color: AppTheme.textTertiary,
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
              ],
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field1),
                  const SizedBox(width: 16),
                  Expanded(child: field2),
                ],
              );
            }
            return Column(children: [field1, const SizedBox(height: 16), field2]);
          }),
          const SizedBox(height: 16),
          Text('Phase du projet *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderDropdown<ProjectPhase>(
            name: 'projectPhase',
            initialValue: state.currentCri?.projectPhase ?? ProjectPhase.etude,
            decoration: const InputDecoration(
              hintText: 'Phase du projet',
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
          const SizedBox(height: 24),
          _buildSoftwaresSection(state),
        ],
      ),
    );
  }

  /// Section "Logiciels utilisés" — sélection multiple + version par logiciel.
  /// Obligatoire : au moins un logiciel doit être sélectionné.
  Widget _buildSoftwaresSection(CriProjetFormState state) {
    final selected = state.currentCri?.softwares ?? const <SoftwareEntry>[];

    return FormBuilderField<List<SoftwareEntry>>(
      name: 'softwares',
      initialValue: selected,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez au moins un logiciel';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Logiciels utilisés *',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(sélection multiple)',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Chips de sélection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjetSoftware.values.map((sw) {
                final isSelected =
                    selected.any((e) => e.software == sw);
                return FilterChip(
                  label: Text(sw.label),
                  selected: isSelected,
                  onSelected: (v) {
                    final list =
                        List<SoftwareEntry>.from(selected);
                    if (v) {
                      list.add(SoftwareEntry(software: sw));
                    } else {
                      list.removeWhere((e) => e.software == sw);
                    }
                    ref
                        .read(criProjetFormProvider.notifier)
                        .updateSoftwares(list);
                    field.didChange(list);
                  },
                );
              }).toList(),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            // Pour chaque logiciel sélectionné : champ Version libre.
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Version (facultatif)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...selected.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          entry.software.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                              'version-${entry.software.name}'),
                          initialValue: entry.version ?? '',
                          decoration: const InputDecoration(
                            hintText: 'Ex: 5.4.2',
                            isDense: true,
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          onChanged: (value) {
                            final list = selected.map((e) {
                              if (e.software == entry.software) {
                                return e.copyWith(
                                    version: value.isEmpty
                                        ? null
                                        : value);
                              }
                              return e;
                            }).toList();
                            ref
                                .read(criProjetFormProvider.notifier)
                                .updateSoftwares(list);
                            field.didChange(list);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
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
          Text('Type d\'intervention *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderDropdown<ProjetInterventionType>(
            name: 'interventionType',
            initialValue:
                state.currentCri?.interventionType ??
                ProjetInterventionType.installationMateriel,
            decoration: const InputDecoration(
              hintText: 'Type d\'intervention',
              prefixIcon: Icon(Icons.category),
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
          Text('Description des travaux *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'workDescription',
            initialValue: state.currentCri?.workDescription ?? '',
            decoration: const InputDecoration(
              hintText: 'Description des travaux',
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
          Text('Matériels utilisés', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'materialsUsed',
            initialValue: state.currentCri?.materialsUsed ?? '',
            decoration: const InputDecoration(
              hintText: 'Matériels utilisés',
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
          Text('Problèmes rencontrés', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'problemsEncountered',
            initialValue: state.currentCri?.problemsEncountered ?? '',
            decoration: const InputDecoration(
              hintText: 'Problèmes rencontrés',
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
          Text('Solutions apportées', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'solutionsProvided',
            initialValue: state.currentCri?.solutionsProvided ?? '',
            decoration: const InputDecoration(
              hintText: 'Solutions apportées',
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
          const SizedBox(height: 16),
          Text(
            'Durée intervention (minutes)',
            style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
              helperStyle: TextStyle(color: AppTheme.textTertiary),
            ),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.numeric(
              errorText: 'Nombre invalide',
            ),
            onChanged: (value) {
              final duration = int.tryParse(value ?? '');
              if (duration != null) {
                ref
                    .read(criProjetFormProvider.notifier)
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
          Text('Actions à faire', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'actionsToDo',
            initialValue: state.currentCri?.actionsToDo ?? '',
            decoration: const InputDecoration(
              hintText: 'Actions à faire',
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
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prochaine intervention', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderDateTimePicker(
                  name: 'nextInterventionDate',
                  initialValue: state.currentCri?.nextInterventionDate,
                  decoration: const InputDecoration(
                    hintText: 'Prochaine intervention',
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
              ],
            );
            final field2 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut du projet *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                FormBuilderDropdown<ProjectStatus>(
                  name: 'projectStatus',
                  initialValue:
                      state.currentCri?.projectStatus ?? ProjectStatus.enCours,
                  decoration: const InputDecoration(
                    hintText: 'Statut du projet',
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
            );
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field1),
                  const SizedBox(width: 16),
                  Expanded(child: field2),
                ],
              );
            }
            return Column(children: [field1, const SizedBox(height: 16), field2]);
          }),
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
          Text('Nom du technicien *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'technicianName',
            initialValue: state.currentCri?.technicianName ?? '',
            decoration: const InputDecoration(
              hintText: 'Nom du technicien',
              prefixIcon: Icon(Icons.person),
              helperText: 'Format: Prénom Nom',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nom du technicien requis';
              }
              final trimmed = value.trim().toLowerCase();
              if (state.knownTechnicians.isNotEmpty &&
                  !state.knownTechnicians
                      .any((t) => t.toLowerCase() == trimmed)) {
                return 'Technicien "$value" inconnu. Vérifiez le nom (Prénom Nom)';
              }
              return null;
            },
            onChanged: (value) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateTechnicianInfo(technicianName: value);
            },
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
            label: 'Signature client',
            initialSignaturePath: state.currentCri?.clientSignature,
            onSignatureSaved: (path) {
              ref
                  .read(criProjetFormProvider.notifier)
                  .updateClientSignature(path);
            },
          ),
          const SizedBox(height: 16),
          Text('Commentaires client', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'clientComments',
            initialValue: state.currentCri?.clientComments ?? '',
            decoration: const InputDecoration(
              hintText: 'Commentaires client',
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
