import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/position.dart';
import '../models/stats_calculator.dart';
import '../models/stats_period.dart';
import '../widgets/adaptive.dart';
import 'history_screen.dart';
import 'pokal_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _table = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final range = currentRange(s.settings.statsPeriod);
    final active = s.reportedMatches.where((m) => range.contains(m.date)).toList();

    Widget table;
    switch (_table) {
      case 0:
        table = _winLoss(context, StatsCalculator.winLossStats(active, MatchMode.oneVOne));
        break;
      case 1:
        table = _winLoss(context, StatsCalculator.winLossStats(active, MatchMode.twoVTwo));
        break;
      default:
        table = _ownGoals(context, StatsCalculator.ownGoalStats(active));
    }

    return AdaptiveScaffold(
      title: 'Tabellen',
      inlineTitle: true,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        BarIconButton(
          icon: isIOS ? CupertinoIcons.star_circle : Icons.emoji_events_outlined,
          tooltip: 'Pokal-Export',
          onPressed: () => pushPage<void>(context, (_) => const PokalScreen()),
        ),
        BarIconButton(
          icon: isIOS ? CupertinoIcons.clock : Icons.history,
          tooltip: 'Verlauf',
          onPressed: () => pushPage<void>(context, (_) => const HistoryScreen()),
        ),
      ]),
      bottom: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(child: Text('Zeitraum: ${range.label}', style: footnoteStyle(context))),
      ),
      children: [
        AdaptiveSegmented<int>(
          value: _table,
          options: const {0: '1 vs 1', 1: '2 vs 2', 2: 'Eigentore'},
          onChanged: (v) => setState(() => _table = v),
        ),
        const SizedBox(height: 12),
        table,
      ],
    );
  }

  Widget _cell(BuildContext context, String text, {bool bold = false, bool right = false, bool header = false}) {
    final style = header
        ? footnoteStyle(context).copyWith(fontWeight: FontWeight.w600)
        : bodyStyle(context).copyWith(fontSize: 16, fontWeight: bold ? FontWeight.w600 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _empty(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(child: Text(text, style: footnoteStyle(context))),
      );

  Widget _winLoss(BuildContext context, List<PlayerWinLossStat> rows) {
    if (rows.isEmpty) return _empty(context, 'Noch keine Ergebnisse');
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth()},
      border: TableBorder(horizontalInside: BorderSide(color: separatorColor(context), width: 0.5)),
      children: [
        TableRow(children: [
          _cell(context, 'Spieler', header: true),
          _cell(context, 'S/N', header: true, right: true),
          _cell(context, 'Winrate', header: true, right: true),
        ]),
        for (var i = 0; i < rows.length; i++)
          TableRow(children: [
            _cell(context, '${i + 1}. ${rows[i].name}'),
            _cell(context, '${rows[i].wins}/${rows[i].losses}', right: true),
            _cell(context, rows[i].winrate.toStringAsFixed(2).replaceAll('.', ','), bold: true, right: true),
          ]),
      ],
    );
  }

  Widget _ownGoals(BuildContext context, List<MapEntry<String, int>> rows) {
    if (rows.isEmpty) return _empty(context, 'Noch keine Eigentore');
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      border: TableBorder(horizontalInside: BorderSide(color: separatorColor(context), width: 0.5)),
      children: [
        TableRow(children: [
          _cell(context, 'Spieler', header: true),
          _cell(context, 'Eigentore', header: true, right: true),
        ]),
        for (var i = 0; i < rows.length; i++)
          TableRow(children: [
            _cell(context, '${i + 1}. ${rows[i].key}'),
            _cell(context, '${rows[i].value}', bold: true, right: true),
          ]),
      ],
    );
  }
}
