import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';

/// Nombre de CRI soumis en attente de synchronisation serveur.
/// Mis à jour par [SyncService] après chaque passe de synchronisation.
final pendingCriCountProvider = StateProvider<int>((ref) => 0);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(appDatabaseProvider),
    ref.read(criRemoteRepositoryProvider),
    ref,
  );
});

/// Resynchronise les CRI soumis restés en local (syncStatus 'pending')
/// vers le serveur — au démarrage de l'app et au retour de la connectivité.
///
/// Un CRI soumis sur site sans réseau est sauvegardé localement avec
/// syncStatus 'pending' ; sans ce service, il n'apparaissait jamais dans
/// « Tous les CRI » ni « Mes Documents ».
class SyncService {
  final AppDatabase _db;
  final CriRemoteRepository _remote;
  final Ref _ref;

  bool _started = false;
  bool _syncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncService(this._db, this._remote, this._ref);

  /// Démarre la synchronisation automatique : une passe immédiate,
  /// puis une passe à chaque retour de connectivité (mobile uniquement,
  /// connectivity_plus ne supporte pas Flutter Web). Idempotent.
  void start() {
    if (_started) return;
    _started = true;

    // Passe initiale (à l'ouverture de l'app, après login)
    unawaited(syncPendingCris());

    if (!kIsWeb) {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final isOnline = !results.contains(ConnectivityResult.none);
        if (isOnline) {
          unawaited(syncPendingCris());
        }
      });
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _started = false;
  }

  /// Pousse vers le serveur tous les CRI soumis (non-brouillons) restés en
  /// 'pending'. Retourne le nombre de CRI synchronisés avec succès.
  Future<int> syncPendingCris() async {
    if (_syncing) return 0;
    _syncing = true;
    var synced = 0;
    try {
      final services = await _db.getAllCriService();
      for (final row in services.where(_needsSync)) {
        try {
          final model = CriServiceModel.fromDb(row);
          await _remote.saveCriService(model);
          if (model.photos.isNotEmpty) {
            try {
              await _remote.uploadPhotos(model.id, model.photos);
            } catch (_) {}
          }
          await _db.updateCriService(
            model.copyWith(syncStatus: 'synced').toDb(),
          );
          synced++;
        } catch (e) {
          debugPrint('Sync CRI Service ${row.id} échouée: $e');
        }
      }

      final projets = await _db.getAllCriProjet();
      for (final row in projets.where(_needsSync)) {
        try {
          final model = CriProjetModel.fromDb(row);
          await _remote.saveCriProjet(model);
          if (model.photos.isNotEmpty) {
            try {
              await _remote.uploadPhotos(model.id, model.photos);
            } catch (_) {}
          }
          await _db.updateCriProjet(
            model.copyWith(syncStatus: 'synced').toDb(),
          );
          synced++;
        } catch (e) {
          debugPrint('Sync CRI Projet ${row.id} échouée: $e');
        }
      }

      await refreshPendingCount();
    } finally {
      _syncing = false;
    }
    return synced;
  }

  bool _needsSync(dynamic row) => !row.isDraft && row.syncStatus == 'pending';

  /// Recompte les CRI soumis encore en attente et met à jour le provider.
  Future<int> refreshPendingCount() async {
    final services = await _db.getAllCriService();
    final projets = await _db.getAllCriProjet();
    final count =
        services.where(_needsSync).length + projets.where(_needsSync).length;
    _ref.read(pendingCriCountProvider.notifier).state = count;
    return count;
  }
}
