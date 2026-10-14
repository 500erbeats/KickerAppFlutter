import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/match_record.dart';

/// SQLite-Persistenz (Pendant zu SwiftData auf iOS bzw. Room auf Android).
class AppDatabase {
  AppDatabase._(this._db);
  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'kicker_flutter.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE players (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, sortOrder INTEGER NOT NULL)');
        await db.execute('''
          CREATE TABLE matches (
            remoteId TEXT PRIMARY KEY,
            dateMillis INTEGER NOT NULL,
            mode TEXT NOT NULL,
            assignmentsJson TEXT NOT NULL,
            benchJson TEXT NOT NULL,
            scoreWand INTEGER NOT NULL,
            scoreTreppe INTEGER NOT NULL,
            ownGoalsJson TEXT NOT NULL,
            isReported INTEGER NOT NULL
          )
        ''');
      },
    );
    return AppDatabase._(db);
  }

  Future<List<PlayerRecord>> getPlayers() async =>
      (await _db.query('players', orderBy: 'sortOrder ASC')).map(PlayerRecord.fromDbMap).toList();

  Future<void> insertPlayer(PlayerRecord player) async => _db.insert('players', player.toDbMap());

  Future<void> deletePlayer(int id) async => _db.delete('players', where: 'id = ?', whereArgs: [id]);

  Future<List<MatchRecord>> getMatches() async =>
      (await _db.query('matches', orderBy: 'dateMillis DESC')).map(MatchRecord.fromDbMap).toList();

  Future<void> upsertMatch(MatchRecord m) async =>
      _db.insert('matches', m.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteMatch(String remoteId) async =>
      _db.delete('matches', where: 'remoteId = ?', whereArgs: [remoteId]);
}
