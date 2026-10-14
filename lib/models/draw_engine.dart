import 'dart:math';
import 'position.dart';

class DrawOutcome {
  final MatchMode mode;
  final List<PositionAssignment> assignments;
  final List<String> bench;
  const DrawOutcome({required this.mode, required this.assignments, required this.bench});

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

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'assignments': assignments.map((a) => a.toJson()).toList(),
        'bench': bench,
      };

  factory DrawOutcome.fromJson(Map<String, dynamic> json) => DrawOutcome(
        mode: MatchMode.values.firstWhere((m) => m.name == json['mode']),
        assignments: (json['assignments'] as List)
            .map((e) => PositionAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
        bench: (json['bench'] as List).map((e) => e as String).toList(),
      );
}

/// 1:1-Port der Auslosungsregeln aus der iOS/Android-Version:
/// - 2 Spieler: nur Seiten auslosen
/// - 3 Spieler: 2 Partien, je 1 Spieler pausiert pro Match
/// - 4 Spieler: Seite + Position (vorn/hinten) auslosen
/// - 5–8 Spieler: 4 spielen, Rest pausiert; wer in Spiel 1 pausiert, spielt in Spiel 2 sicher
class DrawEngine {
  static final Random _random = Random();

  static List<T> _shuffled<T>(List<T> list) {
    final copy = List<T>.from(list);
    copy.shuffle(_random);
    return copy;
  }

  static (DrawOutcome, DrawOutcome)? draw(List<String> players) {
    final count = players.length;
    if (count < 2 || count > 8) return null;

    final shuffled = _shuffled(players);
    List<String> game1Players;
    List<String> game1Bench;

    if (count == 2 || count == 4) {
      game1Players = shuffled;
      game1Bench = [];
    } else if (count == 3) {
      game1Players = shuffled.sublist(0, 2);
      game1Bench = shuffled.sublist(2);
    } else {
      game1Players = shuffled.sublist(0, 4);
      game1Bench = shuffled.sublist(4);
    }

    final game1 = _buildOutcome(count, game1Players, game1Bench);

    final mustPlay = List<String>.from(game1Bench);
    final available = _shuffled(game1Players.where((p) => !mustPlay.contains(p)).toList());

    List<String> game2Players;
    List<String> game2Bench;

    if (count == 2) {
      game2Players = players;
      game2Bench = [];
    } else if (count == 3) {
      game2Players = [mustPlay[0], available[0]];
      game2Bench = [available[1]];
    } else {
      while (mustPlay.length < 4 && available.isNotEmpty) {
        mustPlay.add(available.removeLast());
      }
      game2Players = _shuffled(mustPlay);
      game2Bench = available;
    }

    final game2 = _buildOutcome(count, game2Players, game2Bench);
    return (game1, game2);
  }

  static DrawOutcome _buildOutcome(int count, List<String> players, List<String> bench) {
    if (count == 2 || count == 3) {
      final assignments = <PositionAssignment>[];
      if (players.isNotEmpty) {
        assignments.add(PositionAssignment(position: Position.wandseite, playerName: players[0]));
      }
      if (players.length > 1) {
        assignments.add(PositionAssignment(position: Position.treppenseite, playerName: players[1]));
      }
      return DrawOutcome(mode: MatchMode.oneVOne, assignments: assignments, bench: bench);
    }
    const positions = [Position.wandHinten, Position.wandVorne, Position.treppeHinten, Position.treppeVorne];
    final assignments = <PositionAssignment>[];
    for (var i = 0; i < players.length && i < 4; i++) {
      assignments.add(PositionAssignment(position: positions[i], playerName: players[i]));
    }
    return DrawOutcome(mode: MatchMode.twoVTwo, assignments: assignments, bench: bench);
  }
}
