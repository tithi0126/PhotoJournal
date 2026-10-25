import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/entry_model.dart';
import '../models/photo_model.dart';
import '../models/photo_metadata_model.dart';

class EntryRepository {
  final AppDatabase _db;

  EntryRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  Future<Database> get _database => _db.database;

  /// Fetch the entry for a specific date (YYYY-MM-DD), joins photo + metadata
  Future<EntryModel?> getEntryForDate(String isoDate) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT e.*, p.*, pm.*,
             e.id AS e_id, p.id AS p_id
      FROM entries e
      JOIN photos p ON p.id = e.photo_id
      LEFT JOIN photo_metadata pm ON pm.photo_id = p.id
      WHERE e.entry_date = ? AND e.deleted_at IS NULL
      LIMIT 1
    ''', [isoDate]);

    if (rows.isEmpty) return null;
    return _buildEntry(rows.first);
  }

  /// Fetch all non-deleted entries for a given month ('YYYY-MM')
  Future<List<EntryModel>> getEntriesForMonth(String yearMonth) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT e.*, p.*, pm.*,
             e.id AS e_id, p.id AS p_id
      FROM entries e
      JOIN photos p ON p.id = e.photo_id
      LEFT JOIN photo_metadata pm ON pm.photo_id = p.id
      WHERE e.entry_date LIKE ? AND e.deleted_at IS NULL
      ORDER BY e.entry_date ASC
    ''', ['$yearMonth-%']);

    return rows.map(_buildEntry).toList();
  }

  /// Fetch all non-deleted entries for a given year ('YYYY')
  Future<List<EntryModel>> getEntriesForYear(String year) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT e.*, p.*, pm.*,
             e.id AS e_id, p.id AS p_id
      FROM entries e
      JOIN photos p ON p.id = e.photo_id
      LEFT JOIN photo_metadata pm ON pm.photo_id = p.id
      WHERE e.entry_date LIKE ? AND e.deleted_at IS NULL
      ORDER BY e.entry_date ASC
    ''', ['$year-%']);

    return rows.map(_buildEntry).toList();
  }

  /// Get all dates that have a non-deleted entry (thumbnails for calendar)
  Future<Map<String, String>> getDateToThumbMap() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT e.entry_date, p.thumb_path
      FROM entries e
      JOIN photos p ON p.id = e.photo_id
      WHERE e.deleted_at IS NULL
    ''');
    return {for (final r in rows) r['entry_date'] as String: r['thumb_path'] as String};
  }

  /// Insert a new entry (photo already inserted)
  Future<void> insertEntry(EntryModel entry) async {
    final db = await _database;
    await db.insert('entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  /// Insert a photo row
  Future<void> insertPhoto(PhotoModel photo) async {
    final db = await _database;
    await db.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert photo metadata row
  Future<void> insertPhotoMetadata(PhotoMetadataModel meta) async {
    final db = await _database;
    await db.insert('photo_metadata', meta.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Replace the photo for an existing entry (old photo goes to trash)
  Future<void> replaceEntryPhoto({
    required String entryId,
    required String newPhotoId,
    required String oldPhotoId,
  }) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update(
        'entries',
        {'photo_id': newPhotoId, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [entryId],
      );
      await txn.update(
        'photos',
        {'trashed_at': now},
        where: 'id = ?',
        whereArgs: [oldPhotoId],
      );
    });
  }

  /// Update title and/or description
  Future<void> updateEntryText({
    required String entryId,
    String? title,
    String? description,
  }) async {
    final db = await _database;
    await db.update(
      'entries',
      {
        'title': title,
        'description': description,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Soft delete entry
  Future<void> softDeleteEntry(String entryId) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'entries',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Hard-purge photos trashed more than 30 days ago
  Future<void> purgeTrashedPhotos() async {
    final db = await _database;
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    await db.delete('photos', where: 'trashed_at IS NOT NULL AND trashed_at < ?', whereArgs: [cutoff]);
  }

  /// Toggle location visibility per entry
  Future<void> setHideLocation({required String entryId, required bool hide}) async {
    final db = await _database;
    await db.update(
      'entries',
      {'hide_location': hide ? 1 : 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Navigate to previous/next entry date from a given date
  Future<String?> getPreviousEntryDate(String isoDate) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      columns: ['entry_date'],
      where: 'entry_date < ? AND deleted_at IS NULL',
      whereArgs: [isoDate],
      orderBy: 'entry_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['entry_date'] as String;
  }

  Future<String?> getNextEntryDate(String isoDate) async {
    final db = await _database;
    final rows = await db.query(
      'entries',
      columns: ['entry_date'],
      where: 'entry_date > ? AND deleted_at IS NULL',
      whereArgs: [isoDate],
      orderBy: 'entry_date ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['entry_date'] as String;
  }

  EntryModel _buildEntry(Map<String, dynamic> row) {
    // Rename aliased columns from join
    final eId = row['e_id'] as String? ?? row['id'] as String;
    final pId = row['p_id'] as String? ?? row['photo_id'] as String;

    final photo = PhotoModel(
      id: pId,
      originalPath: row['original_path'] as String,
      thumbPath: row['thumb_path'] as String,
      mediumPath: row['medium_path'] as String,
      largePath: row['large_path'] as String,
      width: row['width'] as int,
      height: row['height'] as int,
      fileSize: row['file_size'] as int?,
      mimeType: row['mime_type'] as String?,
      contentHash: row['content_hash'] as String,
      sourceAssetId: row['source_asset_id'] as String?,
      createdAt: row['created_at'] as int,
      trashedAt: row['trashed_at'] as int?,
    );

    PhotoMetadataModel? meta;
    if (row['photo_id'] != null) {
      try {
        meta = PhotoMetadataModel.fromMap({...row, 'photo_id': pId});
      } catch (_) {}
    }

    return EntryModel(
      id: eId,
      entryDate: row['entry_date'] as String,
      title: row['title'] as String?,
      description: row['description'] as String?,
      photoId: pId,
      hideLocation: (row['hide_location'] as int? ?? 0) == 1,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
      deletedAt: row['deleted_at'] as int?,
      syncState: SyncState.values.firstWhere(
        (s) => s.name == (row['sync_state'] as String? ?? 'local'),
        orElse: () => SyncState.local,
      ),
      photo: photo,
      metadata: meta,
    );
  }
}
