import 'dart:convert';
import 'position.dart';

/// Ein Match. remoteId ist die stabile ID für den Google-Sheet-Abgleich.
class MatchRecord {
  final String remoteId;
  final DateTime date;
  final MatchMode mode;
  final List<PositionAssignment> assignments;
  final List<String> bench;
  final int scoreWand;
  final int scoreTreppe;
  final List<OwnGoalEntry> ownGoals;
  final bool isReported;

  const MatchRecord({
    required this.remoteId,
    required this.date,
    required this.mode,
    required this.assignments,
    this.bench = const [],
    this.scoreWand = 0,
    this.scoreTreppe = 0,
    this.ownGoals = const [],
    this.isReported = false,
  });

  List<String> get wandPlayers => assignments
      .where((a) =>
          a.position == Position.wandseite || a.position == Position.wandHinten || a.position == Position.wandVorne)
      .map((a) => a.playerName)
      .toList();

  List<String> get treppePlayers => assignments
      .where((a) =>
          a.position == Position.treppenseite ||
          a.position == Position.treppeHinten ||
          a.position == Position.treppeVorne)
      .map((a) => a.playerName)
      .toList();

  MatchRecord copyWith({int? scoreWand, int? scoreTreppe, List<OwnGoalEntry>? ownGoals, bool? isReported}) {
    return MatchRecord(
      remoteId: remoteId,
      date: date,
      mode: mode,
      assignments: assignments,
      bench: bench,
      scoreWand: scoreWand ?? this.scoreWand,
      scoreTreppe: scoreTreppe ?? this.scoreTreppe,
      ownGoals: ownGoals ?? this.ownGoals,
      isReported: isReported ?? this.isReported,
    );
  }

  Map<String, Object?> toDbMap() => {
        'remoteId': remoteId,
        'dateMillis': date.millisecondsSinceEpoch,
        'mode': mode.name,
        'assignmentsJson': jsonEncode(assignments.map((a) => a.toJson()).toList()),
        'benchJson': jsonEncode(bench),
        'scoreWand': scoreWand,
        'scoreTreppe': scoreTreppe,
        'ownGoalsJson': jsonEncode(ownGoals.map((o) => o.toJson()).toList()),
        'isReported': isReported ? 1 : 0,
      };

  factory MatchRecord.fromDbMap(Map<String, Object?> map) => MatchRecord(
        remoteId: map['remoteId'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['dateMillis'] as int),
        mode: MatchMode.values.firstWhere((m) => m.name == map['mode']),
        assignments: (jsonDecode(map['assignmentsJson'] as String) as List)
            .map((e) => PositionAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
        bench: (jsonDecode(map['benchJson'] as String) as List).map((e) => e as String).toList(),
        scoreWand: map['scoreWand'] as int,
        scoreTreppe: map['scoreTreppe'] as int,
        ownGoals: (jsonDecode(map['ownGoalsJson'] as String) as List)
            .map((e) => OwnGoalEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        isReported: (map['isReported'] as int) == 1,
      );
}

class PlayerRecord {
  final int? id;
  final String name;
  final int sortOrder;
  const PlayerRecord({this.id, required this.name, this.sortOrder = 0});

  Map<String, Object?> toDbMap() => {if (id != null) 'id': id, 'name': name, 'sortOrder': sortOrder};

  factory PlayerRecord.fromDbMap(Map<String, Object?> map) =>
      PlayerRecord(id: map['id'] as int, name: map['name'] as String, sortOrder: map['sortOrder'] as int);
}
