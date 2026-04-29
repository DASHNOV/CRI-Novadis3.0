import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
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
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/features/cri_form/widgets/site_selector.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/cri_form/widgets/form_shared_widgets.dart';
import 'dart:async';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Page de formulaire CRI Service avec 6 sections
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

  // Controllers pour auto-complétion des champs à la sélection d'un site
  final _addressController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _paysController = TextEditingController();

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
    _addressController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
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
      debugPrint('Error fetching summary: $e');
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

    // Initialiser les controllers avec les valeurs existantes
    final cri = ref.read(criServiceFormProvider).currentCri;
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
    final notifier = ref.read(criServiceFormProvider.notifier);
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

    // Fetch site summary
    _fetchSiteSummary(site.nomDuSite);
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    _formKey.currentState?.save();
    await ref.read(criServiceFormProvider.notifier).saveDraft();
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
    final state = ref.read(criServiceFormProvider);
    final cri = state.currentCri;

    if (cri == null) {
      return 'Erreur: formulaire non initialisé';
    }

    // Vérifier la signature technicien
    if (cri.technicianSignature == null || cri.technicianSignature!.isEmpty) {
      return 'La signature du technicien est requise';
    }

    // Vérifier qu'au moins un type de système est sélectionné
    if (cri.systemTypes.isEmpty) {
      return 'Sélectionnez au moins un type d\'intervention (Vidéo, Contrôle d\'accès ou Intrusion)';
    }

    return null; // Tout est OK
  }

  Future<void> _submit() async {
    debugPrint('[CRI Service] _submit() appelé');

    // D'abord valider les champs FormBuilder
    final formValid = _formKey.currentState?.saveAndValidate() ?? false;
    debugPrint('[CRI Service] FormBuilder validation: $formValid');

    if (!formValid) {
      final fields = _formKey.currentState?.fields ?? {};
      final errorEntries = fields.entries
          .where((e) => e.value.hasError)
          .toList();
      
      debugPrint('[CRI Service] Champs en erreur: ${errorEntries.map((e) => '${e.key}: ${e.value.errorText}').join(', ')}');

      final errors = errorEntries
          .map((e) => '• ${e.key}: ${e.value.errorText ?? 'invalide'}')
          .toList();
      final message = errors.isEmpty
          ? 'Veuillez corriger les erreurs dans le formulaire'
          : 'Erreurs de validation:\n${errors.join('\n')}';

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Ensuite valider les champs personnalisés (signatures, satisfaction)
    final customValidationError = _validateCompleteForm();
    if (customValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customValidationError),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.surface,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Soumission en cours...'),
          ],
        ),
        duration: const Duration(seconds: 2),
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
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    } else {
      final state = ref.read(criServiceFormProvider);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Erreur lors de la soumission'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Détails',
            textColor: AppTheme.surface,
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
    ref.watch(themeAnimationProvider);
    final state = ref.watch(criServiceFormProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const CriFormLoadingScaffold(title: 'CRI Service');
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildCriFormAppBar(
        context: context,
        title: widget.criId == null ? 'Nouveau CRI Service' : 'Modifier CRI Service',
        isDirty: state.isDirty,
        onSaveDraft: () => ref.read(criServiceFormProvider.notifier).saveDraft(),
        extraActions: [
          if (state.currentCri != null)
            PriorityChip(priority: state.currentCri!.priority, showIcon: true),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: ContentContainer(
          maxWidth: 900,
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
                    _buildRequestStep(state, theme),
                    _buildInterventionStep(state, theme),
                    _buildSecurityStep(state, theme),
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
                  color: AppTheme.background.withValues(alpha: 0.95),
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
      ),
      bottomNavigationBar: CriFormAutoSaveBar(lastAutoSave: state.lastAutoSave),
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
                style: TextStyle(
                  color: AppTheme.primaryContent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Numéro de commande', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: 'ticketNumber',
            initialValue: state.currentCri?.ticketNumber ?? '',
            decoration: InputDecoration(
              hintText: 'CCNNNNN',
              prefixIcon: const Icon(Icons.confirmation_number),
              helperText: 'Format: CCNNNNN (optionnel)',
              suffixIcon: Tooltip(
                message: 'Ex: CC09813',
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.textTertiary,
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
                            .read(criServiceFormProvider.notifier)
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
                                    .read(criServiceFormProvider.notifier)
                                    .updateClientInfo(clientName: val);
                              },
                              onSubmitted: (String value) {
                                onFieldSubmitted();
                              },
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
                    .read(criServiceFormProvider.notifier)
                    .updateClientInfo(site: val);

                if (val.trim().length >= 3) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(
                    const Duration(milliseconds: 1000),
                    () {
                      _fetchSiteSummary(val);
                    },
                  );
                }
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
                  .read(criServiceFormProvider.notifier)
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
                        .read(criServiceFormProvider.notifier)
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
                        .read(criServiceFormProvider.notifier)
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
                        .read(criServiceFormProvider.notifier)
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
          LayoutBuilder(builder: (context, constraints) {
            final field1 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type de demande *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
              ],
            );
            final field2 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Priorité *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                PrioritySelector(
                  selectedPriority: state.currentCri?.priority,
                  onPriorityChanged: (priority) {
                    ref
                        .read(criServiceFormProvider.notifier)
                        .updateRequestInfo(priority: priority);
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
          Text(
            'Motif de l\'intervention *',
            style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
          const SizedBox(height: 24),
          _buildContratTypeField(state),
          const SizedBox(height: 24),
          _buildSystemTypesField(state),
        ],
      ),
    );
  }

  /// Statut du contrat (facultatif) — Sous contrat / Hors contrat
  Widget _buildContratTypeField(CriServiceFormState state) {
    final current = state.currentCri?.contratType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Statut du contrat',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(facultatif)',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...ServiceContratType.values.map((type) {
              final isSelected = current == type;
              return ChoiceChip(
                label: Text(type.label),
                selected: isSelected,
                onSelected: (v) {
                  ref
                      .read(criServiceFormProvider.notifier)
                      .updateContratType(v ? type : null);
                },
              );
            }),
            if (current != null)
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(criServiceFormProvider.notifier)
                      .updateContratType(null);
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Effacer'),
              ),
          ],
        ),
      ],
    );
  }

  /// Type d'intervention (sélection multiple obligatoire) — Vidéo / Contrôle d'accès / Intrusion
  Widget _buildSystemTypesField(CriServiceFormState state) {
    final selected =
        state.currentCri?.systemTypes ?? const <ServiceSystemType>[];

    return FormBuilderField<List<ServiceSystemType>>(
      name: 'systemTypes',
      initialValue: selected,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez au moins un type d\'intervention';
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
                  'Type d\'intervention *',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ServiceSystemType.values.map((sys) {
                final isSelected = selected.contains(sys);
                return FilterChip(
                  label: Text(sys.label),
                  selected: isSelected,
                  onSelected: (v) {
                    final list =
                        List<ServiceSystemType>.from(selected);
                    if (v) {
                      if (!list.contains(sys)) list.add(sys);
                    } else {
                      list.remove(sys);
                    }
                    ref
                        .read(criServiceFormProvider.notifier)
                        .updateSystemTypes(list);
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
          ],
        );
      },
    );
  }

  /// Section 4: Intervention
  Step _buildInterventionStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Intervention'),
      subtitle: const Text('Travail effectué'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travail Effectué *', style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
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
        ],
      ),
    );
  }

  /// Section 5: Sécurité
  Step _buildSecurityStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Sécurité'),
      subtitle: const Text('Cybersécurité'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommandations Cybersécurité',
            style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 6: Validation
  Step _buildValidationStep(CriServiceFormState state, ThemeData theme) {
    return Step(
      title: const Text('Validation'),
      subtitle: const Text('Signatures et photos'),
      isActive: _currentStep >= 5,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statut de l\'intervention',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              CheckboxListTile(
                title: const Text('Terminée'),
                value: state.currentCri?.resolutionStatus == ResolutionStatus.resolu,
                onChanged: null,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('A Suivre'),
                value: state.currentCri?.additionalInterventionRequired ?? false,
                onChanged: (val) {
                  ref.read(criServiceFormProvider.notifier).updateStatutIntervention(
                    additionalInterventionRequired: val ?? false,
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Devis à réaliser'),
                value: state.currentCri?.devisARealiser ?? false,
                onChanged: (val) {
                  ref.read(criServiceFormProvider.notifier).updateStatutIntervention(
                    devisARealiser: val ?? false,
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Facturable'),
                value: state.currentCri?.facturable ?? false,
                onChanged: (val) {
                  ref.read(criServiceFormProvider.notifier).updateStatutIntervention(
                    facturable: val ?? false,
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 24),
          PhotoPicker(
            initialPhotos: state.currentCri?.photos ?? [],
            maxPhotos: 5,
            onPhotosChanged: (photos) {
              ref.read(criServiceFormProvider.notifier).updatePhotos(photos);
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
            label: 'Signature client',
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

