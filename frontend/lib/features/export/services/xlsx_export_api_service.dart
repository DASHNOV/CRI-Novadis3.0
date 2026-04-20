import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'xlsx_export_downloader_stub.dart'
    if (dart.library.io) 'xlsx_export_downloader_native.dart'
    if (dart.library.html) 'xlsx_export_downloader_web.dart';

/// Période pour l'export agrégé.
enum XlsxExportPeriod { day, week, month, year }

extension XlsxExportPeriodX on XlsxExportPeriod {
  String get slug => switch (this) {
        XlsxExportPeriod.day => 'day',
        XlsxExportPeriod.week => 'week',
        XlsxExportPeriod.month => 'month',
        XlsxExportPeriod.year => 'year',
      };

  String get label => switch (this) {
        XlsxExportPeriod.day => 'Jour',
        XlsxExportPeriod.week => 'Semaine',
        XlsxExportPeriod.month => 'Mois',
        XlsxExportPeriod.year => 'Année',
      };
}

/// Résultat d'un export XLSX.
///
/// - `file`: `File` en natif, `String` (nom de fichier) sur le web.
/// - `filename`: nom original du fichier renvoyé par le backend.
class XlsxExportResult {
  final dynamic file;
  final String filename;
  final int byteLength;
  const XlsxExportResult({
    required this.file,
    required this.filename,
    required this.byteLength,
  });
}

/// Appelle le backend pour générer un XLSX et le délivre à l'utilisateur.
class XlsxExportApiService {
  final Dio _dio;
  XlsxExportApiService(this._dio);

  Future<XlsxExportResult> exportCri(String criId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/export/cri/$criId.xlsx',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return _handle(response, fallback: 'cri-$criId.xlsx');
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  Future<XlsxExportResult> exportPeriod({
    required XlsxExportPeriod period,
    DateTime? referenceDate,
  }) async {
    final date = (referenceDate ?? DateTime.now()).toUtc();
    try {
      final response = await _dio.get<List<int>>(
        '/export/period.xlsx',
        queryParameters: {
          'range': period.slug,
          'date': date.toIso8601String(),
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return _handle(response, fallback: 'novadis-${period.slug}.xlsx');
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  static String _extractServerError(DioException e) {
    final data = e.response?.data;
    if (data is List<int>) {
      try {
        final decoded = utf8.decode(data);
        final json = jsonDecode(decoded);
        if (json is Map && json['error'] != null) {
          return 'Serveur: ${json['error']}';
        }
        return 'Serveur: $decoded';
      } catch (_) {}
    } else if (data is String && data.isNotEmpty) {
      return 'Serveur: $data';
    }
    return e.message ?? 'Erreur inconnue';
  }

  Future<XlsxExportResult> _handle(
    Response<List<int>> response, {
    required String fallback,
  }) async {
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.isEmpty) {
      throw Exception('Réponse XLSX vide');
    }
    final filename = _parseFilename(response.headers.value('content-disposition')) ?? fallback;
    final delivered = await deliverXlsx(bytes, filename);
    debugPrint('[XLSX] Délivré: $filename (${bytes.length} bytes)');
    return XlsxExportResult(
      file: delivered,
      filename: filename,
      byteLength: bytes.length,
    );
  }

  static String? _parseFilename(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final star = RegExp(r"""filename\*=(?:[^']*'[^']*')?([^;\r\n]+)""", caseSensitive: false)
        .firstMatch(contentDisposition);
    if (star != null) {
      final raw = star.group(1)?.trim();
      if (raw != null && raw.isNotEmpty) {
        try {
          return Uri.decodeComponent(raw);
        } catch (_) {
          return raw;
        }
      }
    }
    final plain = RegExp(r'filename="?([^";\r\n]+)"?', caseSensitive: false)
        .firstMatch(contentDisposition);
    return plain?.group(1)?.trim();
  }
}
