import 'dart:convert';

/// Modèle pour les documents exportés
class ExportedDocumentModel {
  final int? id;
  final String? criId;
  final String filename;
  final String filePath;
  final DocumentFileType fileType;
  final int fileSize;
  final ExportType exportType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? sharedAt;

  const ExportedDocumentModel({
    this.id,
    this.criId,
    required this.filename,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.exportType,
    this.metadata,
    required this.createdAt,
    this.sharedAt,
  });

  /// Copie avec modifications
  ExportedDocumentModel copyWith({
    int? id,
    String? criId,
    String? filename,
    String? filePath,
    DocumentFileType? fileType,
    int? fileSize,
    ExportType? exportType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? sharedAt,
  }) {
    return ExportedDocumentModel(
      id: id ?? this.id,
      criId: criId ?? this.criId,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      exportType: exportType ?? this.exportType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'criId': criId,
      'filename': filename,
      'filePath': filePath,
      'fileType': fileType.name,
      'fileSize': fileSize,
      'exportType': exportType.name,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'sharedAt': sharedAt?.toIso8601String(),
    };
  }

  /// Création depuis JSON
  factory ExportedDocumentModel.fromJson(Map<String, dynamic> json) {
    return ExportedDocumentModel(
      id: json['id'] as int?,
      criId: json['criId'] as String?,
      filename: json['filename'] as String,
      filePath: json['filePath'] as String,
      fileType: DocumentFileType.fromString(json['fileType'] as String),
      fileSize: json['fileSize'] as int,
      exportType: ExportType.fromString(json['exportType'] as String),
      metadata: json['metadata'] != null
          ? (json['metadata'] is String
                ? jsonDecode(json['metadata'] as String) as Map<String, dynamic>
                : json['metadata'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sharedAt: json['sharedAt'] != null
          ? DateTime.parse(json['sharedAt'] as String)
          : null,
    );
  }

  /// Taille formatée (ex: 1.5 MB)
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Extension du fichier
  String get extension {
    return filename.split('.').last.toUpperCase();
  }
}

/// Types de fichiers exportés
enum DocumentFileType {
  pdf('PDF'),
  csv('CSV');

  final String label;
  const DocumentFileType(this.label);

  static DocumentFileType fromString(String value) {
    return DocumentFileType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label == value,
      orElse: () => DocumentFileType.pdf,
    );
  }
}

/// Types d'export
enum ExportType {
  cri('CRI'),
  dashboard('Dashboard'),
  technician('Technicien');

  final String label;
  const ExportType(this.label);

  static ExportType fromString(String value) {
    return ExportType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label == value,
      orElse: () => ExportType.cri,
    );
  }
}

/// Filtres pour la recherche de documents
class DocumentFilter {
  final DocumentFileType? fileType;
  final ExportType? exportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const DocumentFilter({
    this.fileType,
    this.exportType,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  DocumentFilter copyWith({
    DocumentFileType? fileType,
    ExportType? exportType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearFileType = false,
    bool clearExportType = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearchQuery = false,
  }) {
    return DocumentFilter(
      fileType: clearFileType ? null : (fileType ?? this.fileType),
      exportType: clearExportType ? null : (exportType ?? this.exportType),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Réinitialiser tous les filtres
  DocumentFilter clearAll() {
    return const DocumentFilter();
  }

  /// Réinitialiser uniquement la recherche
  DocumentFilter clearSearch() {
    return DocumentFilter(
      fileType: fileType,
      exportType: exportType,
      startDate: startDate,
      endDate: endDate,
      searchQuery: null,
    );
  }

  bool get hasActiveFilters =>
      fileType != null ||
      exportType != null ||
      startDate != null ||
      endDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFilter &&
          runtimeType == other.runtimeType &&
          fileType == other.fileType &&
          exportType == other.exportType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      fileType.hashCode ^
      exportType.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      searchQuery.hashCode;
}

/// Options de tri
enum DocumentSortOption {
  newestFirst('Plus récent'),
  oldestFirst('Plus ancien'),
  nameAZ('Nom A-Z'),
  nameZA('Nom Z-A'),
  sizeAsc('Taille croissante'),
  sizeDesc('Taille décroissante');

  final String label;
  const DocumentSortOption(this.label);
}
