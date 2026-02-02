import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';

/// État du formulaire CRI Projet
class CriProjetFormState {
  final CriProjetModel? currentCri;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isDirty;
  final DateTime? lastAutoSave;

  const CriProjetFormState({
    this.currentCri,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isDirty = false,
    this.lastAutoSave,
  });

  CriProjetFormState copyWith({
    CriProjetModel? currentCri,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isDirty,
    DateTime? lastAutoSave,
  }) {
    return CriProjetFormState(
      currentCri: currentCri ?? this.currentCri,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isDirty: isDirty ?? this.isDirty,
      lastAutoSave: lastAutoSave ?? this.lastAutoSave,
    );
  }
}

/// Notifier pour gérer l'état du formulaire CRI Projet
class CriProjetFormNotifier extends StateNotifier<CriProjetFormState> {
  final Uuid _uuid = const Uuid();

  CriProjetFormNotifier() : super(const CriProjetFormState());

  /// Initialise un nouveau formulaire
  void initNewForm({required String technicianName}) {
    final id = _uuid.v4();
    final newCri = CriProjetModel.empty(id: id, technicianName: technicianName);
    state = CriProjetFormState(currentCri: newCri, isDirty: false);
  }

  /// Charge un CRI existant pour édition
  Future<void> loadCri(String id) async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Implémenter le chargement depuis Drift
      // Pour l'instant, crée un nouveau formulaire
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Met à jour les informations générales (Section 1)
  void updateGeneralInfo({
    DateTime? interventionDate,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        interventionDate: interventionDate,
        startTime: startTime,
        endTime: endTime,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les informations client (Section 2)
  void updateClientInfo({
    String? clientName,
    String? site,
    String? address,
    String? clientContact,
    String? phone,
    String? email,
  }) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        clientName: clientName,
        site: site,
        address: address,
        clientContact: clientContact,
        phone: phone,
        email: email,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les informations projet (Section 3)
  void updateProjectInfo({
    String? projectName,
    String? projectNumber,
    ProjectPhase? projectPhase,
  }) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        projectName: projectName,
        projectNumber: projectNumber,
        projectPhase: projectPhase,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les informations d'intervention (Section 4)
  void updateInterventionInfo({
    ProjetInterventionType? interventionType,
    String? workDescription,
    String? materialsUsed,
    String? problemsEncountered,
    String? solutionsProvided,
  }) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        interventionType: interventionType,
        workDescription: workDescription,
        materialsUsed: materialsUsed,
        problemsEncountered: problemsEncountered,
        solutionsProvided: solutionsProvided,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les informations de suivi (Section 5)
  void updateFollowUpInfo({
    String? actionsToDo,
    DateTime? nextInterventionDate,
    ProjectStatus? projectStatus,
  }) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        actionsToDo: actionsToDo,
        nextInterventionDate: nextInterventionDate,
        projectStatus: projectStatus,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les photos
  void updatePhotos(List<String> photos) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(photos: photos),
      isDirty: true,
    );
  }

  /// Met à jour la signature du technicien
  void updateTechnicianSignature(String? signaturePath) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        technicianSignature: signaturePath,
      ),
      isDirty: true,
    );
  }

  /// Met à jour la signature du client
  void updateClientSignature(String? signaturePath) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(clientSignature: signaturePath),
      isDirty: true,
    );
  }

  /// Met à jour les commentaires du client
  void updateClientComments(String? comments) {
    if (state.currentCri == null) return;

    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(clientComments: comments),
      isDirty: true,
    );
  }

  /// Sauvegarde le brouillon
  Future<bool> saveDraft() async {
    if (state.currentCri == null) return false;

    state = state.copyWith(isSaving: true);

    try {
      final updatedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: true,
      );

      // TODO: Sauvegarder dans Drift
      // await _database.saveCriProjet(updatedCri);

      state = state.copyWith(
        currentCri: updatedCri,
        isSaving: false,
        isDirty: false,
        lastAutoSave: DateTime.now(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erreur lors de la sauvegarde: $e',
      );
      return false;
    }
  }

  /// Soumet le formulaire final
  Future<bool> submit() async {
    if (state.currentCri == null) return false;

    state = state.copyWith(isSaving: true);

    try {
      final submittedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: false,
        syncStatus: 'pending',
      );

      // TODO: Sauvegarder dans Drift et ajouter à la file de sync
      // await _database.saveCriProjet(submittedCri);
      // await _syncQueue.add(submittedCri);

      state = state.copyWith(
        currentCri: submittedCri,
        isSaving: false,
        isDirty: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erreur lors de la soumission: $e',
      );
      return false;
    }
  }

  /// Réinitialise le formulaire
  void reset() {
    state = const CriProjetFormState();
  }

  /// Efface le message d'erreur
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider pour le contrôleur de formulaire CRI Projet
final criProjetFormProvider =
    StateNotifierProvider<CriProjetFormNotifier, CriProjetFormState>(
      (ref) => CriProjetFormNotifier(),
    );

/// Provider pour le nom du technicien courant
/// TODO: À implémenter avec l'authentification
final currentTechnicianNameProvider = Provider<String>((ref) {
  return 'Technicien Test'; // Valeur par défaut
});
