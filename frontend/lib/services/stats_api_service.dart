import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/models/personal_stats.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/technician_activity.dart';
import 'package:novadis_cri/models/daily_activity.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';
import 'package:novadis_cri/models/distribution_stats.dart';

/// Provider pour le StatsApiService
final statsApiServiceProvider = Provider<StatsApiService>((ref) {
  return StatsApiService(ref.watch(dioProvider));
});

/// Service API pour les statistiques personnelles et globales
class StatsApiService {
  final Dio _dio;

  StatsApiService(this._dio);

  // ──────────────────────────────────────────────────
  // 👤 Endpoints personnels (Technician + Admin)
  // ──────────────────────────────────────────────────

  /// Récupère les statistiques personnelles du technicien connecté
  Future<PersonalStats> getPersonalStats() async {
    try {
      final response = await _dio.get('/personal/stats');
      final data = response.data['data'];
      return PersonalStats.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les CRI personnels avec filtre
  /// [filter] peut être: 'all', 'pending', 'signed', 'in_progress'
  Future<List<Map<String, dynamic>>> getPersonalCRIs({
    String filter = 'all',
  }) async {
    try {
      final response = await _dio.get(
        '/personal/cris',
        queryParameters: {'filter': filter},
      );
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les 5 derniers CRI du technicien
  Future<List<Map<String, dynamic>>> getRecentPersonalCRIs() async {
    try {
      final response = await _dio.get('/personal/recent');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────
  // 🌐 Endpoints globaux (Admin uniquement)
  // ──────────────────────────────────────────────────

  /// Récupère les statistiques globales (admin uniquement)
  /// [periodDays] : 1, 7, 30, 90, 365 ou null pour tout
  Future<GlobalStats> getGlobalStats({int? periodDays}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodDays != null) queryParams['period'] = periodDays;
      final response = await _dio.get(
        '/global/stats',
        queryParameters: queryParams,
      );
      final data = response.data['data'];
      return GlobalStats.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les statistiques par site (admin uniquement)
  Future<List<SiteStats>> getStatsBySite({int? periodDays}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodDays != null) queryParams['period'] = periodDays;
      final response = await _dio.get(
        '/global/stats/by-site',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List;
      return data
          .map((item) => SiteStats.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les statistiques par technicien (admin uniquement)
  Future<List<TechnicianDetailedStats>> getStatsByTechnician({
    int? periodDays,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodDays != null) queryParams['period'] = periodDays;
      final response = await _dio.get(
        '/global/stats/by-technician',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List;
      return data
          .map((item) =>
              TechnicianDetailedStats.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les statistiques de distribution croisées (admin uniquement)
  Future<DistributionStats> getDistributionStats({int? periodDays}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodDays != null) queryParams['period'] = periodDays;
      final response = await _dio.get(
        '/global/stats/distribution',
        queryParameters: queryParams,
      );
      final data = response.data['data'];
      return DistributionStats.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère tous les CRI avec info technicien (admin uniquement)
  Future<List<Map<String, dynamic>>> getAllCRIsWithTechnician({
    String? technicienId,
    String filter = 'all',
    String? searchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'filter': filter};
      if (technicienId != null) {
        queryParams['technicienId'] = technicienId;
      }
      if (searchId != null && searchId.isNotEmpty) {
        queryParams['searchId'] = searchId;
      }

      final response = await _dio.get(
        '/global/cris',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère l'activité de tous les techniciens (admin uniquement)
  Future<List<TechnicianActivity>> getTechnicianActivity() async {
    try {
      final response = await _dio.get('/global/activity');
      final data = response.data['data'] as List;
      return data
          .map(
            (item) => TechnicianActivity.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Données pour graphique d'activité des 7 derniers jours (admin uniquement)
  Future<List<DailyActivity>> getActivityChartData() async {
    try {
      final response = await _dio.get('/global/activity-chart');
      final data = response.data['data'] as List;
      return data
          .map((item) => DailyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Marqueur écrit dans `clientSignature` lorsqu'un CRI est validé manuellement
  /// (sans capture de signature physique). Doit rester synchronisé avec
  /// `UpdateSignatureDto.ManualValidationMarker` côté backend.
  static const String manualValidationMarker = 'MANUAL_VALIDATION';

  /// Met à jour manuellement le statut "Signé / En attente" d'un CRI.
  /// Passe `setSigned: true` pour marquer signé, `false` pour repasser en attente.
  /// Le backend rejette toute tentative de modification sur un CRI dont l'appelant
  /// n'est pas le propriétaire (strict, même pour les admins).
  Future<void> toggleClientSignature(String criId, {required bool setSigned}) async {
    try {
      await _dio.patch(
        '/cri/$criId/signature',
        data: {
          'clientSignature': setSigned ? manualValidationMarker : null,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère la liste des techniciens pour le filtre dropdown (admin)
  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final response = await _dio.get('/global/technicians');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────
  // 🔧 Gestion des erreurs
  // ──────────────────────────────────────────────────

  String _handleError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 403) {
      return 'Accès refusé. Ce CRI ne vous appartient pas.';
    }
    if (status == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (status == 404) {
      return 'Endpoint introuvable (404). Le backend est-il à jour ?';
    }
    if (status == 405) {
      return 'Méthode non autorisée (405). Le backend est-il à jour ?';
    }
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    if (status != null) {
      return 'Erreur HTTP $status. Veuillez réessayer.';
    }
    return 'Erreur réseau (${e.type.name}). Veuillez réessayer.';
  }
}
