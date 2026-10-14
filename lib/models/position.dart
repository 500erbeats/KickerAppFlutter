enum MatchMode { oneVOne, twoVTwo }

String matchModeToSheetString(MatchMode mode) => mode == MatchMode.twoVTwo ? '2vs2' : '1vs1';

MatchMode? matchModeFromSheetString(String s) {
  if (s == '2vs2') return MatchMode.twoVTwo;
  if (s == '1vs1') return MatchMode.oneVOne;
  return null;
}

enum Position {
  wandseite,
  treppenseite,
  wandHinten,
  wandVorne,
  treppeHinten,
  treppeVorne;

  /// Anzeigename unter Berücksichtigung der in den Settings vergebenen Seitennamen
  /// (Standard: "Wandseite" / "Treppenseite").
  String displayName(String wandLabel, String treppeLabel) {
    switch (this) {
      case Position.wandseite:
        return wandLabel;
      case Position.treppenseite:
        return treppeLabel;
      case Position.wandHinten:
        return '$wandLabel hinten';
      case Position.wandVorne:
        return '$wandLabel vorne';
      case Position.treppeHinten:
        return '$treppeLabel hinten';
      case Position.treppeVorne:
        return '$treppeLabel vorne';
    }
  }

  static Position fromName(String name) =>
      Position.values.firstWhere((p) => p.name == name, orElse: () => Position.wandseite);
}

class PositionAssignment {
  final Position position;
  final String playerName;
  const PositionAssignment({required this.position, required this.playerName});

  Map<String, dynamic> toJson() => {'position': position.name, 'playerName': playerName};

  factory PositionAssignment.fromJson(Map<String, dynamic> json) => PositionAssignment(
        position: Position.fromName(json['position'] as String),
        playerName: json['playerName'] as String,
      );
}

class OwnGoalEntry {
  final String playerName;
  final int count;
  const OwnGoalEntry({required this.playerName, required this.count});

  Map<String, dynamic> toJson() => {'playerName': playerName, 'count': count};

  factory OwnGoalEntry.fromJson(Map<String, dynamic> json) =>
      OwnGoalEntry(playerName: json['playerName'] as String, count: json['count'] as int);
}
