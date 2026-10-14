import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/draw_engine.dart';
import '../widgets/adaptive.dart';
import '../widgets/share_cards.dart';
import 'result_entry_screen.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final Set<String> _selected = {};
  final List<String> _oneTime = [];
  final TextEditingController _nameCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<String> _allNames(AppState s) {
    final names = s.players.map((p) => p.name).toList();
    if (!names.contains('Reserve')) names.add('Reserve');
    return names;
  }

  void _toggle(String name, bool wasSelected) =>
      setState(() => wasSelected ? _selected.remove(name) : _selected.add(name));

  void _addOneTime(AppState s) {
    final t = _nameCtrl.text.trim();
    if (t.isEmpty || _oneTime.contains(t) || _allNames(s).contains(t)) return;
    setState(() {
      _oneTime.add(t);
      _selected.add(t);
      _nameCtrl.clear();
    });
  }

  void _start(AppState s) {
    if (_selected.length < 2 || _selected.length > 8) {
      setState(() => _error = 'Bitte wähle zwischen 2 und 8 Spieler aus.');
      return;
    }
    setState(() => _error = null);
    s.startDraw(_selected.toList());
  }

  Future<void> _report(int slot, DrawOutcome outcome) async {
    final s = context.read<AppState>();
    final saved = await pushModal<bool>(context, (_) => ResultEntryScreen(match: s.newDraft(outcome)));
    if (saved == true) s.markDrawReported(slot);
  }

  Future<void> _share(AppState s) async {
    final d = s.currentDraw;
    if (d == null) return;
    await shareWidgetAsImage(
      context,
      DrawShareCard(
        game1: d.game1,
        game2: d.game2,
        wandLabel: s.settings.effectiveWandLabel,
        treppeLabel: s.settings.effectiveTreppeLabel,
      ),
      filename: 'kicker-auslosung.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final draw = s.currentDraw;

    return AdaptiveScaffold(
      title: '⚽ Kicker-Auslosung',
      trailing: draw == null
          ? null
          : BarIconButton(icon: isIOS ? CupertinoIcons.share : Icons.share, onPressed: () => _share(s), tooltip: 'Teilen'),
      children: [
        Text('Spieler auswählen', style: headlineStyle(context)),
        const SizedBox(height: 8),
        NameChips(names: _allNames(s), selected: _selected, onToggle: _toggle),
        const SizedBox(height: 20),
        Text('Einmalig Namen hinzufügen', style: headlineStyle(context)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: AdaptiveTextField(controller: _nameCtrl, placeholder: 'Name', onSubmitted: (_) => _addOneTime(s)),
          ),
          const SizedBox(width: 8),
          BarTextButton(label: 'Hinzufügen', onPressed: () => _addOneTime(s)),
        ]),
        if (_oneTime.isNotEmpty) ...[
          const SizedBox(height: 8),
          NameChips(names: _oneTime, selected: _selected, onToggle: _toggle),
        ],
        const SizedBox(height: 20),
        AdaptiveButton(
          label: 'Auslosung starten',
          icon: isIOS ? CupertinoIcons.shuffle : Icons.shuffle,
          prominent: true,
          onPressed: () => _start(s),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(fontSize: 13, color: errorColor())),
          ),
        if (draw != null) ...[
          const SizedBox(height: 20),
          _matchBlock(context, s, 'Match 1', draw.game1, draw.game1Reported, () => _report(0, draw.game1)),
          const SizedBox(height: 16),
          _matchBlock(context, s, 'Match 2', draw.game2, draw.game2Reported, () => _report(1, draw.game2)),
        ],
      ],
    );
  }

  Widget _matchBlock(BuildContext context, AppState s, String title, DrawOutcome o, bool reported, VoidCallback onReport) {
    final wand = s.settings.effectiveWandLabel;
    final treppe = s.settings.effectiveTreppeLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: headlineStyle(context)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor(context), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (final a in o.assignments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(a.position.displayName(wand, treppe), style: bodyStyle(context).copyWith(color: secondaryLabelColor(context)))),
                    Text(a.playerName, style: bodyStyle(context).copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ),
              if (o.bench.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text('Bank', style: bodyStyle(context).copyWith(color: secondaryLabelColor(context)))),
                    Text(o.bench.join(', '), style: bodyStyle(context)),
                  ]),
                ),
              const SizedBox(height: 8),
              if (reported)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(isIOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle, color: successColor(), size: 20),
                  const SizedBox(width: 6),
                  Text('Ergebnis gemeldet', style: TextStyle(fontSize: 17, color: successColor())),
                ])
              else
                AdaptiveButton(label: 'Ergebnis melden', onPressed: onReport),
            ],
          ),
        ),
      ],
    );
  }
}
