class CriPhotoModel {
  final String id;
  final String criFormId;
  final String? originalFileName;
  final String? mimeType;

  const CriPhotoModel({
    required this.id,
    required this.criFormId,
    this.originalFileName,
    this.mimeType,
  });

  factory CriPhotoModel.fromJson(Map<String, dynamic> json) {
    return CriPhotoModel(
      id: json['id'] as String,
      criFormId: json['criFormId'] as String,
      originalFileName: json['originalFileName'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }
}
