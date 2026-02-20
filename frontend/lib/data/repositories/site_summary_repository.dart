import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/data/models/site_summary_model.dart';

final siteSummaryRepositoryProvider = Provider<SiteSummaryRepository>((ref) {
  return SiteSummaryRepository(ref.read(dioProvider));
});

class SiteSummaryRepository {
  final Dio _dio;

  SiteSummaryRepository(this._dio);

  Future<SiteSummaryModel?> getSummary(String siteName) async {
    try {
      final response = await _dio.get(
        '/sites/summary',
        queryParameters: {'siteName': siteName},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return SiteSummaryModel.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      // If 404 or empty, just return null, don't break the flow
      if (e.response?.statusCode == 404) {
        return null;
      }
      // For other errors, maybe log but don't crash the form
      print('Error fetching site summary: $e');
      return null;
    } catch (e) {
      print('Error fetching site summary: $e');
      return null;
    }
  }
}
