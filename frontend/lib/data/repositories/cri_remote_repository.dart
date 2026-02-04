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
      final List<dynamic> rawData = response.data['data'];

      final List<dynamic> result = [];
      for (var item in rawData) {
        final String type = item['interventionType'];
        final String? jsonData = item['data'];

        if (jsonData != null) {
          final Map<String, dynamic> modelData = jsonDecode(jsonData);
          if (type == 'Project') {
            result.add(CriProjetModel.fromJson(modelData));
          } else {
            result.add(CriServiceModel.fromJson(modelData));
          }
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

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'Erreur de communication avec le serveur';
  }
}
