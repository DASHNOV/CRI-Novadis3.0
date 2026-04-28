/// Document exporté côté serveur (endpoint /api/exported-documents).
class ServerExportedDocument {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? criId;
  final String filename;
  final String fileType;
  final String exportType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime? sharedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? metadata;

  const ServerExportedDocument({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.criId,
    required this.filename,
    required this.fileType,
    required this.exportType,
    required this.sizeBytes,
    required this.createdAt,
    this.sharedAt,
    this.periodStart,
    this.periodEnd,
    this.metadata,
  });

  factory ServerExportedDocument.fromJson(Map<String, dynamic> json) {
    return ServerExportedDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      criId: json['criId'] as String?,
      filename: json['filename'] as String,
      fileType: (json['fileType'] as String).toLowerCase(),
      exportType: json['exportType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      sharedAt: json['sharedAt'] != null
          ? DateTime.parse(json['sharedAt'] as String).toLocal()
          : null,
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'] as String).toLocal()
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.parse(json['periodEnd'] as String).toLocal()
          : null,
      metadata: json['metadata'] as String?,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get extension => fileType.toUpperCase();
}
