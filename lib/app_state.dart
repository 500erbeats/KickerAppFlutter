import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_database.dart';
import 'data/settings_store.dart';
import 'models/draw_engine.dart';
import 'models/match_record.dart';
import 'models/position.dart';
import 'network/sheet_sync_service.dart';

/// Eine laufende Auslosung inkl. Meldestatus — wird gespeichert, damit ein
/// versehentliches Schließen der App zwischen Auslosen und Rückmelden nichts kostet.
class DrawState {
  final DrawOutcome game1;
  final DrawOutcome game2;
  final bool game1Reported;
  final bool game2Reported;

  const DrawState({
    required this.game1,
    required this.game2,
    this.game1Reported = false,
    this.game2Reported = false,
  });

  DrawState copyWith({bool? game1Reported, bool? game2Reported}) => DrawState(
        game1: game1,
        game2: game2,
        game1Reported: game1Reported ?? this.game1Reported,
        game2Reported: game2Reported ?? this.game2Reported,
      );

  Map<String, dynamic> toJson() => {
        'game1': game1.toJson(),
        'game2': game2.toJson(),
        'game1Reported': game1Reported,
        'game2Reported': game2Reported,
      };

  factory DrawState.fromJson(Map<String, dynamic> j) => DrawState(
        game1: DrawOutcome.fromJson(j['game1'] as Map<String, dynamic>),
        game2: DrawOutcome.fromJson(j['game2'] as Map<String, dynamic>),
        game1Reported: j['game1Reported'] as bool? ?? false,
        game2Reported: j['game2Reported'] as bool? ?? false,
      );
}

/// Zentraler App-Zustand (Pendant zu @Query/@AppStorage auf iOS bzw. AppViewModel auf Android).
class AppState extends ChangeNotifier {
  AppState._(this._db, this._store) : settings = _store.load();

  final AppDatabase _db;
  final SettingsStore _store;

  AppSettings settings;
  List<PlayerRecord> players = [];
  List<MatchRecord> matches = [];
  DrawState? currentDraw;

  static Future<AppState> create() async {
    final db = await AppDatabase.open();
    final prefs = await SharedPreferences.getInstance();
    final state = AppState._(db, SettingsStore(prefs));
    state.players = await db.getPlayers();
    state.matches = await db.getMatches();
    state._restoreDraw();
    state.pullOnLaunch(); // nicht blockierend: neue Sheet-Zeilen übernehmen (rein additiv)
    return state;
  }

  bool get _syncOn => settings.sheetSyncEnabled && settings.sheetUrl.trim().isNotEmpty;

  // ---------------------------------------------------------------- Spieler

  Future<void> addPlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || players.any((p) => p.name == trimmed)) return;
    await _db.insertPlayer(PlayerRecord(name: trimmed, sortOrder: players.length));
    players = await _db.getPlayers();
    notifyListeners();
    _pushRoster();
  }

  Future<void> deletePlayer(PlayerRecord player) async {
    if (player.id == null) return;
    await _db.deletePlayer(player.id!);
    players = await _db.getPlayers();
    notifyListeners();
    _pushRoster();
  }

  void _pushRoster() {
    if (!_syncOn) return;
    SheetSyncService.pushPlayers(players.map((p) => p.name).toList(), settings.sheetUrl);
  }

  // -------------------------------------------------------------- Auslosung

  bool startDraw(List<String> names) {
    final result = DrawEngine.draw(names);
    if (result == null) return false;
    currentDraw = DrawState(game1: result.$1, game2: result.$2);
    _persistDraw();
    notifyListeners();
    return true;
  }

  void markDrawReported(int slot) {
    final draw = currentDraw;
    if (draw == null) return;
    currentDraw = slot == 0 ? draw.copyWith(game1Reported: true) : draw.copyWith(game2Reported: true);
    _persistDraw();
    notifyListeners();
  }

  void _persistDraw() {
    final draw = currentDraw;
    if (draw == null || (draw.game1Reported && draw.game2Reported)) {
      _store.saveLastDrawJson(null);
      return;
    }
    _store.saveLastDrawJson(jsonEncode(draw.toJson()));
  }

  void _restoreDraw() {
    final raw = _store.loadLastDrawJson();
    if (raw == null || raw.isEmpty) return;
    try {
      currentDraw = DrawState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      currentDraw = null;
    }
  }

  /// Neuer, noch nicht gespeicherter Entwurf. Wird erst beim Speichern des Ergebnisses in
  /// die Datenbank geschrieben (keine verwaisten Entwürfe bei "Abbrechen").
  MatchRecord newDraft(DrawOutcome outcome) => MatchRecord(
        remoteId: SheetSyncService.newId(),
        date: DateTime.now(),
        mode: outcome.mode,
        assignments: outcome.assignments,
        bench: outcome.bench,
      );

  // --------------------------------------------------------------- Ergebnisse

  Future<void> saveResult(MatchRecord match, int scoreWand, int scoreTreppe, List<OwnGoalEntry> ownGoals) async {
    final updated = match.copyWith(
      scoreWand: scoreWand,
      scoreTreppe: scoreTreppe,
      ownGoals: ownGoals.where((o) => o.count > 0).toList(),
      isReported: true,
    );
    await _db.upsertMatch(updated);
    await _reloadMatches();
    if (_syncOn) SheetSyncService.push(updated, settings.sheetUrl);
  }

  Future<void> saveManualMatch({
    required DateTime date,
    required MatchMode mode,
    required List<PositionAssignment> assignments,
    required int scoreWand,
    required int scoreTreppe,
    required List<OwnGoalEntry> ownGoals,
  }) async {
    final record = MatchRecord(
      remoteId: SheetSyncService.newId(),
      date: date,
      mode: mode,
      assignments: assignments,
      scoreWand: scoreWand,
      scoreTreppe: scoreTreppe,
      ownGoals: ownGoals.where((o) => o.count > 0).toList(),
      isReported: true,
    );
    await _db.upsertMatch(record);
    await _reloadMatches();
    if (_syncOn) SheetSyncService.push(record, settings.sheetUrl);
  }

  Future<void> deleteMatch(MatchRecord match) async {
    await _db.deleteMatch(match.remoteId);
    await _reloadMatches();
    if (_syncOn) SheetSyncService.pushDeletion(match.remoteId, settings.sheetUrl);
  }

  Future<void> _reloadMatches() async {
    matches = await _db.getMatches();
    notifyListeners();
  }

  List<MatchRecord> get reportedMatches => matches.where((m) => m.isReported).toList();

  // ---------------------------------------------------------------- Settings

  Future<void> updateSettings(AppSettings newSettings) async {
    final wasEnabled = settings.sheetSyncEnabled;
    settings = newSettings;
    await _store.save(newSettings);
    notifyListeners();
    if (!wasEnabled && newSettings.sheetSyncEnabled) _pushRoster();
  }

  // -------------------------------------------------------------- Sheet-Sync

  Future<String> checkSync() async {
    final localIds = reportedMatches.map((m) => m.remoteId).toSet();
    final inSync = await SheetSyncService.checkInSync(localIds, settings.sheetUrl);
    if (inSync == null) return '⚠️ Tabelle nicht erreichbar oder URL ungültig.';
    return inSync
        ? '✅ Synchron (${localIds.length} Ergebnisse)'
        : '⚠️ Abweichung erkannt — evtl. hilft „Neue Ergebnisse abrufen“.';
  }

  Future<String> pullFromSheet() async {
    final rows = await SheetSyncService.fetchRemoteRows(settings.sheetUrl);
    if (rows == null) return '⚠️ Tabelle nicht erreichbar oder URL ungültig.';
    final known = matches.map((m) => m.remoteId).toSet();
    var imported = 0;
    for (final row in rows) {
      if (known.contains(row.id)) continue;
      final record = SheetSyncService.makeMatchRecord(row);
      if (record != null) {
        await _db.upsertMatch(record);
        imported++;
      }
    }
    await _reloadMatches();
    return imported > 0 ? '✅ $imported neue Ergebnisse importiert.' : 'Keine neuen Ergebnisse gefunden.';
  }

  Future<void> pullOnLaunch() async {
    if (!_syncOn) return;
    await pullFromSheet();
  }
}
