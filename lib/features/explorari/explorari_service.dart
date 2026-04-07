import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:nabour_app/features/explorari/explorari_firestore_sync.dart';
import 'package:nabour_app/utils/logger.dart';

/// Zone (~500 m) marcate pe măsură ce te miști (local sqflite + sync Explorări).
class ExplorariService {
  ExplorariService._();
  static final ExplorariService instance = ExplorariService._();

  Database? _db;

  /// ~500 m la latitudine medie RO — grid determinist.
  static String tileId(double lat, double lng) {
    const step = 0.0045;
    final gx = (lat / step).floor();
    final gy = (lng / step).floor();
    return '${gx}_$gy';
  }

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'nabour_scratch_map.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE scratch_tiles (
            tile_id TEXT PRIMARY KEY,
            discovered_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Returnează `true` dacă celula e nouă (pentru sync în Firestore).
  Future<bool> recordVisit(double lat, double lng) async {
    try {
      final db = await _open();
      final id = tileId(lat, lng);
      final existing = await db.query(
        'scratch_tiles',
        where: 'tile_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;
      await db.insert('scratch_tiles', {
        'tile_id': id,
        'discovered_at': DateTime.now().millisecondsSinceEpoch,
      });
      ExplorariFirestoreSync.instance.enqueue(id, lat, lng);
      return true;
    } catch (e) {
      Logger.warning('Explorari: recordVisit $e', tag: 'EXPLORARI');
      return false;
    }
  }

  /// Pentru merge din nor: inserează doar ID-ul (fără lat/lng precise).
  Future<bool> insertTileIdIfMissing(String tileId) async {
    try {
      final db = await _open();
      final existing = await db.query(
        'scratch_tiles',
        where: 'tile_id = ?',
        whereArgs: [tileId],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;
      await db.insert('scratch_tiles', {
        'tile_id': tileId,
        'discovered_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> discoveredTileCount() async {
    try {
      final db = await _open();
      final r = await db.rawQuery('SELECT COUNT(*) as c FROM scratch_tiles');
      return (r.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Procent simbolic (față de un țintă soft ~800 zone ≈ explorare bogată urban).
  Future<double> explorationPercent({int targetTiles = 800}) async {
    final n = await discoveredTileCount();
    if (targetTiles <= 0) return 0;
    return (n / targetTiles * 100).clamp(0, 100);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
