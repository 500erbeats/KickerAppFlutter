import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/match_record.dart';
import '../models/position.dart';
import '../widgets/adaptive.dart';

/// Ergebnis melden bzw. bearbeiten (entspricht ResultEntryView / ResultEntryDialog).
/// Gibt `true` zurück, wenn gespeichert wurde.
class ResultEntryScreen extends StatefulWidget {
  const ResultEntryScreen({super.key, required this.match});
  final MatchRecord match;

  @override
  State<ResultEntryScreen> createState() => _ResultEntryScreenState();
}

class _ResultEntryScreenState extends State<ResultEntryScreen> {
  late int _scoreWand = widget.match.scoreWand;
  late int _scoreTreppe = widget.match.scoreTreppe;
  late final Map<String, int> _ownGoals = {for (final e in widget.match.ownGoals) e.playerName: e.count};

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.saveResult(
      widget.match,
      _scoreWand,
      _scoreTreppe,
      _ownGoals.entries.map((e) => OwnGoalEntry(playerName: e.key, count: e.value)).toList(),
    );

    final diff = (_scoreWand - _scoreTreppe).abs();
    final ultra = (_scoreWand == 10 && _scoreTreppe == 0) || (_scoreWand == 0 && _scoreTreppe == 10);
    if ((ultra || diff > 5) && mounted) {
      await showInfoAlert(
        context,
        title: ultra ? 'ULTRAKISCHDE' : 'KISCHDE',
        message: ultra ? "10:0 – sauberer geht's nicht! 🔥" : 'Klare Kiste mit $diff Toren Differenz! 💪',
        okLabel: 'Nice!',
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppState>().settings;
    final match = widget.match;
    final participants = [...match.wandPlayers, ...match.treppePlayers];

    return AdaptiveScaffold(
      title: match.mode == MatchMode.oneVOne ? '1 vs 1 melden' : '2 vs 2 melden',
      grouped: true,
      leading: BarTextButton(label: 'Abbrechen', onPressed: () => Navigator.of(context).pop(false)),
      trailing: BarTextButton(label: 'Speichern', bold: true, onPressed: _save),
      children: [
        AdaptiveSection(
          header: 'Ergebnis',
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(match.wandPlayers.join(' & '), style: footnoteStyle(context).copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              AdaptiveStepper(
                label: settings.effectiveWandLabel,
                value: _scoreWand,
                onChanged: (v) => setState(() => _scoreWand = v),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(match.treppePlayers.join(' & '), style: footnoteStyle(context).copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              AdaptiveStepper(
                label: settings.effectiveTreppeLabel,
                value: _scoreTreppe,
                onChanged: (v) => setState(() => _scoreTreppe = v),
              ),
            ]),
          ],
        ),
        AdaptiveSection(
          header: 'Eigentore',
          footer:
              'Falls jemand ins eigene Tor geschossen hat, hier eintragen. Der Spielstand oben bleibt davon unberührt — bitte trag dort einfach den finalen Spielstand ein.',
          children: [
            for (final name in participants)
              AdaptiveStepper(
                label: name,
                value: _ownGoals[name] ?? 0,
                max: 20,
                onChanged: (v) => setState(() => _ownGoals[name] = v),
              ),
          ],
        ),
      ],
    );
  }
}
