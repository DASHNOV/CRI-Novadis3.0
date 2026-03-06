import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'dart:convert';

final criRemoteRepositoryProvider = Provider<CriRemoteRepository>((ref) {
  return CriRemoteRepository(ref.read(dioProvider));
});

class CriRemoteRepository {
  final Dio _dio;

  CriRemoteRepository(this._dio);

  Future<List<dynamic>> getAllCris() async {
    try {
      final response = await _dio.get('/CRI');
      final dynamic responseData = response.data['data'];
      
      if (responseData == null || responseData is! List) {
        return [];
      }

      final List<dynamic> rawData = responseData;
      final List<dynamic> result = [];
      
      for (var item in rawData) {
        try {
          final String? type = item['interventionType'];
          final String? jsonData = item['data'];

          if (jsonData != null && jsonData.isNotEmpty) {
            try {
              final Map<String, dynamic> modelData = jsonDecode(jsonData);
              if (type == 'Project') {
                result.add(CriProjetModel.fromJson(modelData));
              } else {
                result.add(CriServiceModel.fromJson(modelData));
              }
              continue; // Successfully decoded from JSON
            } catch (e) {
              // If JSON decode fails, fallback to creating from flat properties
            }
          }

          // FALLBACK: Create minimal model from flat properties if JSON is missing/corrupt
          final id = item['id']?.toString() ?? '';
          final date = DateTime.tryParse(item['interventionDate']?.toString() ?? '') ?? DateTime.now();
          final clientName = item['clientName']?.toString() ?? 'Client Inconnu';
          final techName = '${item['technicianFirstName'] ?? ''} ${item['technicianLastName'] ?? ''}'.trim();
          final technicianName = techName.isNotEmpty ? techName : (item['technicianEmail']?.toString() ?? 'Technicien');

          if (type == 'Project') {
            result.add(CriProjetModel(
              id: id,
              interventionDate: date,
              startTime: date,
              endTime: date.add(const Duration(hours: 2)),
              clientName: clientName,
              site: item['clientSite']?.toString() ?? '',
              address: item['clientAddress']?.toString(),
              projectName: 'Projet sans titre',
              projectNumber: 'PRJ-SQL',
              projectPhase: ProjectPhase.etude,
              interventionType: ProjetInterventionType.installationMateriel,
              workDescription: item['workDescription']?.toString() ?? '',
              projectStatus: ProjectStatus.enCours,
              technicianName: technicianName,
              createdAt: date,
            ));
          } else {
            result.add(CriServiceModel(
              id: id,
              interventionDate: date,
              startTime: date,
              endTime: date.add(const Duration(hours: 1)),
              ticketNumber: 'TICK-SQL',
              clientName: clientName,
              site: item['clientSite']?.toString() ?? '',
              address: item['clientAddress']?.toString(),
              requestType: ServiceRequestType.depannage,
              priority: ServicePriority.normale,
              requestDescription: item['workDescription']?.toString() ?? '',
              actionsPerformed: item['workDescription']?.toString() ?? '',
              interventionDurationMinutes: (item['duration'] != null) 
                  ? ((item['duration'] as num).toDouble()).toInt()
                  : 60,
              resolutionStatus: ResolutionStatus.resolu,
              technicianName: technicianName,
              createdAt: date,
            ));
          }
        } catch (e) {
          // Skip individual corrupt items
          continue;
        }
      }
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> saveCriProjet(CriProjetModel cri) async {
    try {
      final data = {
        'id': cri.id,
        'interventionType': 'Project',
        'category': cri.interventionType.label,
        'interventionDate': cri.interventionDate.toIso8601String(),
        'clientName': cri.clientName,
        'clientAddress': cri.address,
        'clientSite': cri.site,
        'clientPhone': cri.phone,
        'clientEmail': cri.email,
        'workDescription': cri.workDescription,
        'materialsUsed': cri.materialsUsed,
        'duration': cri.durationMinutes / 60.0,
        'status': cri.isDraft ? 'Draft' : 'Submitted',
        'technicianSignature': cri.technicianSignature,
        'clientSignature': cri.clientSignature,
        'data': jsonEncode(
          cri.toJson(),
        ), // Save full JSON in Data column for now
      };

      await _dio.post('/CRI', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> saveCriService(CriServiceModel cri) async {
    try {
      final data = {
        'id': cri.id,
        'interventionType': 'Service',
        'category': cri.requestType.label,
        'interventionDate': cri.interventionDate.toIso8601String(),
        'clientName': cri.clientName,
        'clientAddress': cri.address,
        'clientSite': cri.site,
        'clientPhone': cri.phone,
        'clientEmail': cri.email,
        'workDescription': cri.requestDescription,
        'materialsUsed': cri.replacedParts,
        'duration': cri.interventionDurationMinutes / 60.0,
        'status': cri.isDraft ? 'Draft' : 'Submitted',
        'technicianSignature': cri.technicianSignature,
        'clientSignature': cri.clientSignature,
        'data': jsonEncode(
          cri.toJson(),
        ), // Save full JSON in Data column for now
      };

      await _dio.post('/CRI', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getTechnicians() async {
    try {
      final response = await _dio.get('/Users/technicians');
      final List<dynamic> rawData = response.data['data'];

      return rawData
          .map<String>((e) {
            final firstName = e['firstName'] ?? '';
            final lastName = e['lastName'] ?? '';
            return '$firstName $lastName'.trim();
          })
          .where((name) => name.isNotEmpty)
          .toList();
    } on DioException catch (_) {
      // En cas d'erreur (ex: hors ligne), on retourne une liste vide
      // Idéalement, on devrait cacher cette liste localement
      return [];
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'Erreur de communication avec le serveur';
  }

  Future<List<String>> searchClients(String query) async {
    try {
      if (query.isEmpty) return [];
      final response = await _dio.get(
        '/CRI/clients/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> searchSites(String client, String query) async {
    try {
      if (query.isEmpty) return [];
      final response = await _dio.get(
        '/CRI/sites/search',
        queryParameters: {'client': client, 'q': query},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
