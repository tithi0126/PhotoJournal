class PhotoModel {
  final String id;
  final String originalPath;
  final String thumbPath;
  final String mediumPath;
  final String largePath;
  final int width;
  final int height;
  final int? fileSize;
  final String? mimeType;
  final String contentHash;
  final String? sourceAssetId;
  final int createdAt;
  final int? trashedAt;

  const PhotoModel({
    required this.id,
    required this.originalPath,
    required this.thumbPath,
    required this.mediumPath,
    required this.largePath,
    required this.width,
    required this.height,
    this.fileSize,
    this.mimeType,
    required this.contentHash,
    this.sourceAssetId,
    required this.createdAt,
    this.trashedAt,
  });

  bool get isTrashed => trashedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_path': originalPath,
      'thumb_path': thumbPath,
      'medium_path': mediumPath,
      'large_path': largePath,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'mime_type': mimeType,
      'content_hash': contentHash,
      'source_asset_id': sourceAssetId,
      'created_at': createdAt,
      'trashed_at': trashedAt,
    };
  }

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as String,
      originalPath: map['original_path'] as String,
      thumbPath: map['thumb_path'] as String,
      mediumPath: map['medium_path'] as String,
      largePath: map['large_path'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      fileSize: map['file_size'] as int?,
      mimeType: map['mime_type'] as String?,
      contentHash: map['content_hash'] as String,
      sourceAssetId: map['source_asset_id'] as String?,
      createdAt: map['created_at'] as int,
      trashedAt: map['trashed_at'] as int?,
    );
  }

  PhotoModel copyWith({
    String? thumbPath,
    String? mediumPath,
    String? largePath,
    int? trashedAt,
  }) {
    return PhotoModel(
      id: id,
      originalPath: originalPath,
      thumbPath: thumbPath ?? this.thumbPath,
      mediumPath: mediumPath ?? this.mediumPath,
      largePath: largePath ?? this.largePath,
      width: width,
      height: height,
      fileSize: fileSize,
      mimeType: mimeType,
      contentHash: contentHash,
      sourceAssetId: sourceAssetId,
      createdAt: createdAt,
      trashedAt: trashedAt ?? this.trashedAt,
    );
  }
}
