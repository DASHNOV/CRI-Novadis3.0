import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../models/server_exported_document.dart';
import 'xlsx_export_downloader_stub.dart'
    if (dart.library.io) 'xlsx_export_downloader_native.dart'
    if (dart.library.html) 'xlsx_export_downloader_web.dart';
import 'document_opener_stub.dart'
    if (dart.library.io) 'document_opener_native.dart'
    if (dart.library.html) 'document_opener_web.dart';

/// Client HTTP pour l'historique des documents exportés côté serveur.
///
/// Admin : liste tous les documents. Technicien : uniquement les siens.
class ExportedDocumentsApiService {
  final Dio _dio;
  ExportedDocumentsApiService(this._dio);

  /// Récupère la liste des documents (paginée).
  Future<List<ServerExportedDocument>> list({
    String? fileType,
    String? exportType,
    int skip = 0,
    int take = 200,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/exported-documents',
        queryParameters: {
          if (fileType != null) 'fileType': fileType,
          if (exportType != null) 'exportType': exportType,
          'skip': skip,
          'take': take,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw Exception('Réponse inattendue: ${data.runtimeType}');
      }
      final items = (data['items'] as List?) ?? const [];
      return items
          .cast<Map<String, dynamic>>()
          .map(ServerExportedDocument.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Télécharge un document et le délivre au client (File natif / download web).
  Future<dynamic> download(String id, String filename) async {
    try {
      final response = await _dio.get<List<int>>(
        '/exported-documents/$id/download',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) {
        throw Exception('Fichier vide');
      }
      return await deliverXlsx(bytes, filename);
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Récupère uniquement le binaire (pour partage natif).
  Future<Uint8List> downloadBytes(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/exported-documents/$id/download',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Ouvre (prévisualise) un document : nouvel onglet sur web (preview PDF
  /// native du navigateur), viewer système en natif. Ne télécharge pas le PDF.
  Future<void> open(String id, String filename, String fileType) async {
    final bytes = await downloadBytes(id);
    if (bytes.isEmpty) {
      throw Exception('Fichier vide');
    }
    await openDocumentBytes(bytes, filename, fileType);
  }

  /// Renomme un document.
  Future<void> rename(String id, String newFilename) async {
    try {
      await _dio.patch<dynamic>(
        '/exported-documents/$id',
        data: {'filename': newFilename},
      );
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Marque un document comme partagé.
  Future<void> markShared(String id) async {
    try {
      await _dio.post<dynamic>('/exported-documents/$id/mark-shared');
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Supprime un document.
  Future<void> delete(String id) async {
    try {
      await _dio.delete<dynamic>('/exported-documents/$id');
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  /// Upload un document (ex: PDF généré côté client) et l'enregistre dans l'historique.
  Future<ServerExportedDocument> upload({
    required Uint8List bytes,
    required String filename,
    String? criId,
    String? exportType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        if (criId != null) 'criId': criId,
        if (exportType != null) 'exportType': exportType,
      });
      final response = await _dio.post<dynamic>(
        '/exported-documents/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return ServerExportedDocument.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractServerError(e));
    }
  }

  static String _extractServerError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return 'Serveur: ${data['error']}';
    }
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
}
