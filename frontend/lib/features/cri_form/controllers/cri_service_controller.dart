import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

/// État du formulaire CRI Service
class CriServiceFormState {
  final CriServiceModel? currentCri;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isDirty;
  final DateTime? lastAutoSave;

  const CriServiceFormState({
    this.currentCri,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isDirty = false,
    this.lastAutoSave,
  });

  CriServiceFormState copyWith({
    CriServiceModel? currentCri,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isDirty,
    DateTime? lastAutoSave,
  }) {
    return CriServiceFormState(
      currentCri: currentCri ?? this.currentCri,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isDirty: isDirty ?? this.isDirty,
      lastAutoSave: lastAutoSave ?? this.lastAutoSave,
    );
  }
}

/// Notifier pour gérer l'état du formulaire CRI Service
class CriServiceFormNotifier extends StateNotifier<CriServiceFormState> {
  final Uuid _uuid = const Uuid();
  final AppDatabase _db;
  final CriRemoteRepository _remoteRepo;

  CriServiceFormNotifier(this._db, this._remoteRepo)
    : super(const CriServiceFormState());

  /// Initialise un nouveau formulaire
  void initNewForm({required String technicianName}) {
    final id = _uuid.v4();
    final newCri = CriServiceModel.empty(
      id: id,
      technicianName: technicianName,
    );
    state = CriServiceFormState(currentCri: newCri, isDirty: false);
  }

  /// Charge un CRI existant
  Future<void> loadCri(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final dbCri = await _db.getCriServiceById(id);
      if (dbCri != null) {
        state = state.copyWith(
          currentCri: CriServiceModel.fromDb(dbCri),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'CRI introuvable localement',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erreur lors du chargement du CRI');
    }
  }

  /// Mises à jour des sections
  void updateGeneralInfo({
    DateTime? interventionDate,
    DateTime? startTime,
    DateTime? endTime,
    String? ticketNumber,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        interventionDate: interventionDate,
        startTime: startTime,
        endTime: endTime,
        ticketNumber: ticketNumber,
      ),
      isDirty: true,
    );
  }

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

  void updateRequestInfo({
    ServiceRequestType? requestType,
    ServicePriority? priority,
    String? requestDescription,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        requestType: requestType,
        priority: priority,
        requestDescription: requestDescription,
      ),
      isDirty: true,
    );
  }

  /// Met à jour le statut du contrat (facultatif). Passer null efface la valeur.
  void updateContratType(ServiceContratType? contratType) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        contratType: contratType,
        clearContratType: contratType == null,
      ),
      isDirty: true,
    );
  }

  /// Met à jour la liste des types de système concernés (obligatoire).
  void updateSystemTypes(List<ServiceSystemType> systemTypes) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(systemTypes: systemTypes),
      isDirty: true,
    );
  }

  void updateDiagnosticInfo({
    String? diagnosticPerformed,
    String? identifiedCause,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        diagnosticPerformed: diagnosticPerformed,
        identifiedCause: identifiedCause,
      ),
      isDirty: true,
    );
  }

  void updateInterventionInfo({
    String? actionsPerformed,
    String? replacedParts,
    int? interventionDurationMinutes,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        actionsPerformed: actionsPerformed,
        replacedParts: replacedParts,
        interventionDurationMinutes: interventionDurationMinutes,
      ),
      isDirty: true,
    );
  }

  void updateResultInfo({
    ResolutionStatus? resolutionStatus,
    String? testsPerformed,
    String? recommendations,
    String? cybersecurityRecommendations,
    String? interventionStatus,
    List<dynamic>? fraisSupplementaires,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        resolutionStatus: resolutionStatus,
        testsPerformed: testsPerformed,
        recommendations: recommendations,
        cybersecurityRecommendations: cybersecurityRecommendations,
      ),
      isDirty: true,
    );
  }

  void updateFollowUpInfo({
    bool? additionalInterventionRequired,
    DateTime? followUpDate,
    String? followUpComments,
  }) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(
        additionalInterventionRequired: additionalInterventionRequired,
        followUpDate: followUpDate,
        followUpComments: followUpComments,
      ),
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

  void updateTechnicianName(String? name) {
    if (state.currentCri == null) return;
    state = state.copyWith(
      currentCri: state.currentCri!.copyWith(technicianName: name ?? ''),
      isDirty: true,
    );
  }

  /// Sauvegarde brouillon
  Future<bool> saveDraft() async {
    if (state.currentCri == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      final updatedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: true,
      );
      await _db.updateCriService(updatedCri.toDb());
      state = state.copyWith(
        currentCri: updatedCri,
        isSaving: false,
        isDirty: false,
        lastAutoSave: DateTime.now(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Erreur lors de la sauvegarde: $e');
      return false;
    }
  }

  /// Soumission
  Future<bool> submit() async {
    if (state.currentCri == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      final submittedCri = state.currentCri!.copyWith(
        updatedAt: DateTime.now(),
        isDraft: false,
        syncStatus: 'synced',
      );

      await _db.updateCriService(submittedCri.toDb());
      await _remoteRepo.saveCriService(submittedCri);

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

  void reset() => state = const CriServiceFormState();
  void clearError() => state = state.copyWith(errorMessage: null);
}

/// Providers
final criServiceFormProvider =
    StateNotifierProvider<CriServiceFormNotifier, CriServiceFormState>((ref) {
      return CriServiceFormNotifier(
        ref.read(appDatabaseProvider),
        ref.read(criRemoteRepositoryProvider),
      );
    });
