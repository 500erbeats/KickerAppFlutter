import 'match_record.dart';
import 'position.dart';

class PlayerWinLossStat {
  final String name;
  final int wins;
  final int losses;
  const PlayerWinLossStat(this.name, {this.wins = 0, this.losses = 0});

  /// Wins/Losses statt Punkte pro Sieg. Bei 0 Niederlagen zählen die Siege selbst.
  double get winrate => losses == 0 ? wins.toDouble() : wins / losses;

  PlayerWinLossStat copyWith({int? wins, int? losses}) =>
      PlayerWinLossStat(name, wins: wins ?? this.wins, losses: losses ?? this.losses);
}

class StatsCalculator {
  static List<PlayerWinLossStat> winLossStats(List<MatchRecord> matches, MatchMode mode) {
    final table = <String, PlayerWinLossStat>{};
    for (final match in matches.where((m) => m.mode == mode)) {
      if (match.scoreWand == match.scoreTreppe) continue; // Unentschieden zählt nicht
      final wandWon = match.scoreWand > match.scoreTreppe;
      final winners = wandWon ? match.wandPlayers : match.treppePlayers;
      final losers = wandWon ? match.treppePlayers : match.wandPlayers;
      for (final name in winners) {
        final c = table[name] ?? PlayerWinLossStat(name);
        table[name] = c.copyWith(wins: c.wins + 1);
      }
      for (final name in losers) {
        final c = table[name] ?? PlayerWinLossStat(name);
        table[name] = c.copyWith(losses: c.losses + 1);
      }
    }
    final list = table.values.toList();
    list.sort((a, b) => b.winrate.compareTo(a.winrate));
    return list;
  }

  static List<MapEntry<String, int>> ownGoalStats(List<MatchRecord> matches) {
    final table = <String, int>{};
    for (final match in matches) {
      for (final e in match.ownGoals) {
        table[e.playerName] = (table[e.playerName] ?? 0) + e.count;
      }
    }
    final list = table.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}
