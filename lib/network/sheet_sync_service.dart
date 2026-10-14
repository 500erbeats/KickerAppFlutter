import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/match_record.dart';
import '../models/position.dart';

class RemoteRow {
  final String id;
  final String date;
  final String mode;
  final String wandPlayers;
  final String treppePlayers;
  final int scoreWand;
  final int scoreTreppe;
  final String ownGoals;

  const RemoteRow({
    required this.id,
    required this.date,
    required this.mode,
    required this.wandPlayers,
    required this.treppePlayers,
    required this.scoreWand,
    required this.scoreTreppe,
    required this.ownGoals,
  });

  factory RemoteRow.fromJson(Map<String, dynamic> j) => RemoteRow(
        id: '${j['id']}',
        date: '${j['date'] ?? ''}',
        mode: '${j['mode'] ?? ''}',
        wandPlayers: '${j['wandPlayers'] ?? ''}',
        treppePlayers: '${j['treppePlayers'] ?? ''}',
        scoreWand: int.tryParse('${j['scoreWand']}') ?? 0,
        scoreTreppe: int.tryParse('${j['scoreTreppe']}') ?? 0,
        ownGoals: '${j['ownGoals'] ?? ''}',
      );
}

/// Spricht denselben Google-Apps-Script-Endpoint an wie die nativen Apps
/// (gleiche JSON-Verträge, gleiche Query-Parameter).
class SheetSyncService {
  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  static String? _validUrl(String raw) {
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  static Uri? _plain(String raw) {
    final b = _validUrl(raw);
    return b == null ? null : Uri.tryParse(b);
  }

  static Uri? _withAction(String action, String raw) {
    final b = _validUrl(raw);
    if (b == null) return null;
    return Uri.tryParse('$b${b.contains('?') ? '&' : '?'}action=$action');
  }

  static Future<void> push(MatchRecord match, String urlString) async {
    final uri = _plain(urlString);
    if (uri == null) return;
    await _post(uri, {
      'id': match.remoteId,
      'date': match.date.toUtc().toIso8601String(),
      'mode': matchModeToSheetString(match.mode),
      'wandPlayers': match.wandPlayers.join(' & '),
      'treppePlayers': match.treppePlayers.join(' & '),
      'scoreWand': match.scoreWand,
      'scoreTreppe': match.scoreTreppe,
      'ownGoals': match.ownGoals.map((o) => '${o.playerName}:${o.count}').join(', '),
      'deleted': false,
    });
  }

  static Future<void> pushDeletion(String remoteId, String urlString) async {
    final uri = _plain(urlString);
    if (uri == null) return;
    await _post(uri, {
      'id': remoteId,
      'date': '',
      'mode': '',
      'wandPlayers': '',
      'treppePlayers': '',
      'scoreWand': 0,
      'scoreTreppe': 0,
      'ownGoals': '',
      'deleted': true,
    });
  }

  static Future<void> pushPlayers(List<String> names, String urlString) async {
    final uri = _withAction('players', urlString);
    if (uri == null) return;
    await _post(uri, {'players': names});
  }

  static Future<bool?> checkInSync(Set<String> localIds, String urlString) async {
    final uri = _withAction('status', urlString);
    if (uri == null) return null;
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ids = (data['ids'] as List).map((e) => '$e').toSet();
      return ids.length == localIds.length && ids.containsAll(localIds);
    } catch (_) {
      return null;
    }
  }

  static Future<List<RemoteRow>?> fetchRemoteRows(String urlString) async {
    final uri = _withAction('rows', urlString);
    if (uri == null) return null;
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['rows'] as List).map((e) => RemoteRow.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Liest Datumswerte aus dem Sheet robust:
  /// - ISO-8601 mit UND ohne Millisekunden ("...:00Z" / "...:00.000Z") — Ursache des alten
  ///   "alles zeigt heute"-Bugs: der native iOS-Parser kannte nur die Variante ohne Millisekunden.
  /// - "dd.MM.yyyy" bzw. "dd.MM.yyyy HH:mm" (von Hand ins Sheet getippt; ohne Uhrzeit 12:00,
  ///   damit nichts an der Tagesgrenze kippt).
  /// Gibt null zurück, wenn nichts erkannt wird.
  static DateTime? parseSheetDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso.toLocal();

    final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})(?:[ ,T]+(\d{1,2}):(\d{2}))?').firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
        int.tryParse(m.group(4) ?? '') ?? 12,
        int.tryParse(m.group(5) ?? '') ?? 0,
      );
    }
    return null;
  }

  static MatchRecord? makeMatchRecord(RemoteRow row) {
    final mode = matchModeFromSheetString(row.mode);
    if (mode == null) return null;

    List<String> split(String s) => s.split(' & ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final wandNames = split(row.wandPlayers);
    final treppeNames = split(row.treppePlayers);
    if (wandNames.isEmpty || treppeNames.isEmpty) return null;

    final assignments = <PositionAssignment>[];
    if (mode == MatchMode.oneVOne) {
      assignments.add(PositionAssignment(position: Position.wandseite, playerName: wandNames[0]));
      assignments.add(PositionAssignment(position: Position.treppenseite, playerName: treppeNames[0]));
    } else {
      const wandPositions = [Position.wandHinten, Position.wandVorne];
      const treppePositions = [Position.treppeHinten, Position.treppeVorne];
      for (var i = 0; i < wandNames.length && i < 2; i++) {
        assignments.add(PositionAssignment(position: wandPositions[i], playerName: wandNames[i]));
      }
      for (var i = 0; i < treppeNames.length && i < 2; i++) {
        assignments.add(PositionAssignment(position: treppePositions[i], playerName: treppeNames[i]));
      }
    }

    final ownGoals = <OwnGoalEntry>[];
    for (final entry in row.ownGoals.split(',')) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final name = parts[0].trim();
      final count = int.tryParse(parts[1].trim());
      if (name.isEmpty || count == null) continue;
      ownGoals.add(OwnGoalEntry(playerName: name, count: count));
    }

    final date = parseSheetDate(row.date) ?? DateTime.now();

    return MatchRecord(
      remoteId: row.id,
      date: date,
      mode: mode,
      assignments: assignments,
      scoreWand: row.scoreWand,
      scoreTreppe: row.scoreTreppe,
      ownGoals: ownGoals,
      isReported: true,
    );
  }

  static Future<void> _post(Uri uri, Map<String, dynamic> payload) async {
    try {
      await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    } catch (_) {
      // Sync ist "best effort" — Netzwerkfehler bewusst ignoriert.
    }
  }
}
