import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/models/personal_stats.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/technician_activity.dart';
import 'package:novadis_cri/models/daily_activity.dart';

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
  Future<GlobalStats> getGlobalStats() async {
    try {
      final response = await _dio.get('/global/stats');
      final data = response.data['data'];
      return GlobalStats.fromJson(data);
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
    if (e.response?.statusCode == 403) {
      return 'Accès refusé. Permissions insuffisantes.';
    }
    if (e.response?.statusCode == 401) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
