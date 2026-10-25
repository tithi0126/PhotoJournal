import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'frame.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos (
        id              TEXT PRIMARY KEY,
        original_path   TEXT NOT NULL,
        thumb_path      TEXT NOT NULL,
        medium_path     TEXT NOT NULL,
        large_path      TEXT NOT NULL,
        width           INTEGER NOT NULL,
        height          INTEGER NOT NULL,
        file_size       INTEGER,
        mime_type       TEXT,
        content_hash    TEXT NOT NULL,
        source_asset_id TEXT,
        created_at      INTEGER NOT NULL,
        trashed_at      INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE photo_metadata (
        photo_id        TEXT PRIMARY KEY REFERENCES photos(id) ON DELETE CASCADE,
        camera_make     TEXT,
        camera_model    TEXT,
        lens_model      TEXT,
        iso             INTEGER,
        aperture        REAL,
        shutter_num     INTEGER,
        shutter_den     INTEGER,
        focal_length_mm REAL,
        focal_35mm      REAL,
        captured_at     INTEGER,
        captured_offset INTEGER,
        tz_assumed      INTEGER DEFAULT 0,
        latitude        REAL,
        longitude       REAL,
        altitude_m      REAL,
        place_name      TEXT,
        orientation     INTEGER,
        raw_exif_json   TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_meta_captured ON photo_metadata(captured_at)
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id            TEXT PRIMARY KEY,
        entry_date    TEXT NOT NULL,
        title         TEXT CHECK (length(title) <= 60),
        description   TEXT CHECK (length(description) <= 280),
        photo_id      TEXT NOT NULL REFERENCES photos(id),
        hide_location INTEGER NOT NULL DEFAULT 0,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL,
        deleted_at    INTEGER,
        sync_state    TEXT NOT NULL DEFAULT 'local'
      )
    ''');

    // Partial unique index: one entry per date among non-deleted rows
    await db.execute('''
      CREATE UNIQUE INDEX idx_entries_date
        ON entries(entry_date)
        WHERE deleted_at IS NULL
    ''');

    await db.execute('''
      CREATE TABLE collages (
        id           TEXT PRIMARY KEY,
        type         TEXT NOT NULL CHECK (type IN ('month','year')),
        period       TEXT NOT NULL,
        style        TEXT NOT NULL DEFAULT 'contact_sheet',
        layout_json  TEXT NOT NULL,
        image_path   TEXT,
        content_hash TEXT NOT NULL,
        is_final     INTEGER NOT NULL DEFAULT 0,
        generated_at INTEGER NOT NULL,
        UNIQUE(type, period, style)
      )
    ''');

    await db.execute('''
      CREATE TABLE postcard_sets (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        format     TEXT NOT NULL,
        style      TEXT NOT NULL,
        status     TEXT NOT NULL DEFAULT 'draft',
        pdf_path   TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE postcard_items (
        id           TEXT PRIMARY KEY,
        set_id       TEXT NOT NULL REFERENCES postcard_sets(id) ON DELETE CASCADE,
        entry_id     TEXT NOT NULL REFERENCES entries(id),
        position     INTEGER NOT NULL,
        crop_x REAL, crop_y REAL, crop_w REAL, crop_h REAL,
        caption_text TEXT,
        back_message TEXT,
        UNIQUE(set_id, position)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
