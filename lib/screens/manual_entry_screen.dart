import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/position.dart';
import '../widgets/adaptive.dart';

/// Ergebnis ohne vorherige Auslosung nachtragen (entspricht ManualMatchEntryView).
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  MatchMode _mode = MatchMode.oneVOne;
  DateTime _date = DateTime.now();
  final _wand1 = TextEditingController();
  final _wand2 = TextEditingController();
  final _treppe1 = TextEditingController();
  final _treppe2 = TextEditingController();
  int _scoreWand = 0;
  int _scoreTreppe = 0;
  final Map<String, int> _ownGoals = {};
  String? _error;

  @override
  void dispose() {
    for (final c in [_wand1, _wand2, _treppe1, _treppe2]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _participants {
    final names = [_wand1.text, _treppe1.text];
    if (_mode == MatchMode.twoVTwo) names.addAll([_wand2.text, _treppe2.text]);
    return names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
  }

  Future<void> _pickDate() async {
    if (isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fertig')),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _date,
                onDateTimeChanged: (d) => setState(() => _date = d),
              ),
            ),
          ]),
        ),
      );
    } else {
      final d = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (d != null) setState(() => _date = d);
    }
  }

  Future<void> _save() async {
    final w1 = _wand1.text.trim();
    final t1 = _treppe1.text.trim();
    if (w1.isEmpty || t1.isEmpty) {
      setState(() => _error = 'Bitte mindestens je einen Spieler pro Seite eintragen.');
      return;
    }

    final List<PositionAssignment> assignments;
    if (_mode == MatchMode.oneVOne) {
      assignments = [
        PositionAssignment(position: Position.wandseite, playerName: w1),
        PositionAssignment(position: Position.treppenseite, playerName: t1),
      ];
    } else {
      final w2 = _wand2.text.trim();
      final t2 = _treppe2.text.trim();
      if (w2.isEmpty || t2.isEmpty) {
        setState(() => _error = 'Bitte bei 2vs2 alle 4 Spieler eintragen.');
        return;
      }
      assignments = [
        PositionAssignment(position: Position.wandHinten, playerName: w1),
        PositionAssignment(position: Position.wandVorne, playerName: w2),
        PositionAssignment(position: Position.treppeHinten, playerName: t1),
        PositionAssignment(position: Position.treppeVorne, playerName: t2),
      ];
    }
    setState(() => _error = null);

    final now = DateTime.now();
    final date = DateTime(_date.year, _date.month, _date.day, now.hour, now.minute);

    await context.read<AppState>().saveManualMatch(
          date: date,
          mode: _mode,
          assignments: assignments,
          scoreWand: _scoreWand,
          scoreTreppe: _scoreTreppe,
          ownGoals: _ownGoals.entries.map((e) => OwnGoalEntry(playerName: e.key, count: e.value)).toList(),
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
    final two = _mode == MatchMode.twoVTwo;

    return AdaptiveScaffold(
      title: 'Ergebnis nachtragen',
      grouped: true,
      leading: BarTextButton(label: 'Abbrechen', onPressed: () => Navigator.of(context).pop(false)),
      trailing: BarTextButton(label: 'Speichern', bold: true, onPressed: _save),
      children: [
        AdaptiveSection(
          header: 'Art',
          children: [
            AdaptiveSegmented<MatchMode>(
              value: _mode,
              options: const {MatchMode.oneVOne: '1 vs 1', MatchMode.twoVTwo: '2 vs 2'},
              onChanged: (m) => setState(() => _mode = m),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pickDate,
              child: Row(children: [
                Expanded(child: Text('Datum', style: bodyStyle(context))),
                Text(DateFormat('dd.MM.yyyy').format(_date), style: TextStyle(fontSize: 17, color: accentColor(context))),
              ]),
            ),
          ],
        ),
        AdaptiveSection(
          header: settings.effectiveWandLabel,
          children: [
            AdaptiveTextField(controller: _wand1, placeholder: 'Spieler 1', borderless: true, onChanged: (_) => setState(() {})),
            if (two) AdaptiveTextField(controller: _wand2, placeholder: 'Spieler 2', borderless: true, onChanged: (_) => setState(() {})),
            AdaptiveStepper(label: 'Tore', value: _scoreWand, onChanged: (v) => setState(() => _scoreWand = v)),
          ],
        ),
        AdaptiveSection(
          header: settings.effectiveTreppeLabel,
          children: [
            AdaptiveTextField(controller: _treppe1, placeholder: 'Spieler 1', borderless: true, onChanged: (_) => setState(() {})),
            if (two) AdaptiveTextField(controller: _treppe2, placeholder: 'Spieler 2', borderless: true, onChanged: (_) => setState(() {})),
            AdaptiveStepper(label: 'Tore', value: _scoreTreppe, onChanged: (v) => setState(() => _scoreTreppe = v)),
          ],
        ),
        if (_participants.isNotEmpty)
          AdaptiveSection(
            header: 'Eigentore',
            children: [
              for (final name in _participants)
                AdaptiveStepper(
                  label: name,
                  value: _ownGoals[name] ?? 0,
                  max: 20,
                  onChanged: (v) => setState(() => _ownGoals[name] = v),
                ),
            ],
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(fontSize: 13, color: errorColor())),
          ),
        AdaptiveSection(
          children: [
            Text(
              'Tipp: Namen genauso schreiben wie sonst in der App, sonst tauchen sie in den Tabellen als eigener Spieler auf.',
              style: footnoteStyle(context),
            ),
          ],
        ),
      ],
    );
  }
}
