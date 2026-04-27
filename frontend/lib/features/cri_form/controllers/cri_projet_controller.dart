import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';

/// État du formulaire CRI Projet
class CriProjetFormState {
  final CriProjetModel? currentCri;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isDirty;
  final DateTime? lastAutoSave;
  final List<String> knownTechnicians;

  const CriProjetFormState({
    this.currentCri,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isDirty = false,
    this.lastAutoSave,
    this.knownTechnicians = const [],
  });

  CriProjetFormState copyWith({
    CriProjetModel? currentCri,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isDirty,
    DateTime? lastAutoSave,
    List<String>? knownTechnicians,
  }) {
    return CriProjetFormState(
      currentCri: currentCri ?? this.currentCri,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isDirty: isDirty ?? this.isDirty,
      lastAutoSave: lastAutoSave ?? this.lastAutoSave,
      knownTechnicians: knownTechnicians ?? this.knownTechnicians,
    );
  }
}

/// Notifier pour gérer l'état du formulaire CRI Projet
class CriProjetFormNotifier extends StateNotifier<CriProjetFormState> {
  final Uuid _uuid = const Uuid();
  final AppDatabase _db;
  final CriRemoteRepository _remoteRepo;

  CriProjetFormNotifier(this._db, this._remoteRepo)
    : super(const CriProjetFormState());

  /// Initialise un nouveau formulaire
  void initNewForm({required String technicianName}) {
    final id = _uuid.v4();
    final newCri = CriProjetModel.empty(id: id, technicianName: technicianName);
    state = CriProjetFormState(currentCri: newCri, isDirty: false);
    loadTechnicians();
  }

  Future<void> loadTechnicians() async {
    final technicians = await _remoteRepo.getTechnicians();
    if (technicians.isNotEmpty) {
      state = state.copyWith(knownTechnicians: technicians);
    }
  }

  /// Charge un CRI existant pour édition
  Future<void> loadCri(String id) async {
    state = state.copyWith(isLoading: true);

    try {
      final dbCri = await _db.getCriProjetById(id);
      if (dbCri != null) {
        state = state.copyWith(
          currentCri: CriProjetModel.fromDb(dbCri),
          isLoading: false,
        );
        loadTechnicians();
      } else {
        // Todo: Load from remote if not in local
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'CRI introuvable localement',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement du CRI',
      );
    }
  }

  /// Met à jour les informations générales
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

  /// Met à jour les informations client
  void updateClientInfo({
    String? clientName,
    String? site,
    String? ville,
    String? codePostal,
    String? pays,
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
        ville: ville,
        codePostal: codePostal,
        pays: pays,
        address: address,
        clientContact: clientContact,
        phone: phone,
        email: email,
      ),
      isDirty: true,
    );
  }

  /// Met à jour les informations projet
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

  /// Met à jour les interventions
  void updateInterventionInfo({
    ProjetInterventionType? interventionType,
    String? workDescription,
    String? materialsUsed,
    String? problemsEncountered,
    String? solutionsProvided,
    int? interventionDurationMinutes,
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

  /// Met à jour les informations de suivi
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

  /// Met à jour la liste des logiciels utilisés (sélection + versions).
  void updateSoftwares(List<SoftwareEntry> softwares) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(softwares: softwares),
      isDirty: true,
    );
  }

  void updatePhotos(List<String> photos) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(photos: photos),
      isDirty: true,
    );
  }

  void updateTechnicianSignature(String? signaturePath) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        technicianSignature: signaturePath,
      ),
      isDirty: true,
    );
  }

  void updateClientSignature(String? signaturePath) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(clientSignature: signaturePath),
      isDirty: true,
    );
  }

  void updateClientComments(String? comments) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(clientComments: comments),
      isDirty: true,
    );
  }

  void updateTechnicianInfo({String? technicianName}) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(technicianName: technicianName),
      isDirty: true,
    );
  }

  /// Sauvegarde le brouillon (local + distant si possible)
  Future<bool> saveDraft() async {
    if (state.currentCri == null) return false;
    state = state.copyWith(isSaving: true);

    try {
      var updatedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: true,
      );

      // 1. Sauvegarde locale
      await _db.updateCriProjet(updatedCri.toDb());

      // 2. Tentative de push distant (sans bloquer si offline)
      try {
        await _remoteRepo.saveCriProjet(updatedCri);
        updatedCri = updatedCri.copyWith(syncStatus: 'synced');
        await _db.updateCriProjet(updatedCri.toDb());
      } catch (_) {
        updatedCri = updatedCri.copyWith(syncStatus: 'pending');
        await _db.updateCriProjet(updatedCri.toDb());
      }

      state = state.copyWith(
        currentCri: updatedCri,
        isSaving: false,
        isDirty: false,
        lastAutoSave: DateTime.now(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Erreur lors de la sauvegarde');
      return false;
    }
  }

  /// Soumet le formulaire (local + distant)
  Future<bool> submit() async {
    if (state.currentCri == null) return false;
    state = state.copyWith(isSaving: true);

    try {
      var submittedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: false,
        syncStatus: 'pending',
      );

      // 1. Sauvegarde locale (toujours)
      await _db.updateCriProjet(submittedCri.toDb());

      // 2. Push distant
      try {
        await _remoteRepo.saveCriProjet(submittedCri);
        submittedCri = submittedCri.copyWith(syncStatus: 'synced');
        await _db.updateCriProjet(submittedCri.toDb());
      } catch (e) {
        state = state.copyWith(
          currentCri: submittedCri,
          isSaving: false,
          isDirty: false,
          errorMessage: 'CRI sauvegardé localement. Synchronisation distante échouée: $e',
        );
        return true;
      }

      state = state.copyWith(
        currentCri: submittedCri,
        isSaving: false,
        isDirty: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erreur lors de la soumission',
      );
      return false;
    }
  }

  void reset() => state = const CriProjetFormState();
  void clearError() => state = state.copyWith(errorMessage: null);
}

/// Providers
final criProjetFormProvider =
    StateNotifierProvider<CriProjetFormNotifier, CriProjetFormState>((ref) {
      return CriProjetFormNotifier(
        ref.read(appDatabaseProvider),
        ref.read(criRemoteRepositoryProvider),
      );
    });

final currentTechnicianNameProvider = Provider<String>((ref) {
  return ref.watch(userNameProvider) ?? 'Technicien';
});
