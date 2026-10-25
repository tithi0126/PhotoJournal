import 'photo_model.dart';
import 'photo_metadata_model.dart';

enum SyncState { local, pending, synced, conflict }

class EntryModel {
  final String id;
  final String entryDate; // 'YYYY-MM-DD'
  final String? title;
  final String? description;
  final String photoId;
  final bool hideLocation;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final SyncState syncState;

  // Joined from photos + photo_metadata
  final PhotoModel? photo;
  final PhotoMetadataModel? metadata;

  const EntryModel({
    required this.id,
    required this.entryDate,
    this.title,
    this.description,
    required this.photoId,
    this.hideLocation = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncState = SyncState.local,
    this.photo,
    this.metadata,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_date': entryDate,
      'title': title,
      'description': description,
      'photo_id': photoId,
      'hide_location': hideLocation ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_state': syncState.name,
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'] as String,
      entryDate: map['entry_date'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      photoId: map['photo_id'] as String,
      hideLocation: (map['hide_location'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deletedAt: map['deleted_at'] as int?,
      syncState: SyncState.values.firstWhere(
        (s) => s.name == (map['sync_state'] as String? ?? 'local'),
        orElse: () => SyncState.local,
      ),
    );
  }

  EntryModel copyWith({
    String? title,
    String? description,
    String? photoId,
    bool? hideLocation,
    int? updatedAt,
    int? deletedAt,
    SyncState? syncState,
    PhotoModel? photo,
    PhotoMetadataModel? metadata,
  }) {
    return EntryModel(
      id: id,
      entryDate: entryDate,
      title: title ?? this.title,
      description: description ?? this.description,
      photoId: photoId ?? this.photoId,
      hideLocation: hideLocation ?? this.hideLocation,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
      photo: photo ?? this.photo,
      metadata: metadata ?? this.metadata,
    );
  }
}
