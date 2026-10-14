import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/match_record.dart';
import '../models/position.dart';
import '../widgets/adaptive.dart';
import 'manual_entry_screen.dart';
import 'result_entry_screen.dart';

/// Verlauf: antippen = bearbeiten, nach links wischen = löschen, "+" = manuell nachtragen.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final reported = s.reportedMatches;

    return AdaptiveScaffold(
      title: 'Verlauf',
      padding: const EdgeInsets.symmetric(vertical: 8),
      trailing: BarIconButton(
        icon: isIOS ? CupertinoIcons.add : Icons.add,
        tooltip: 'Hinzufügen',
        onPressed: () => pushModal<bool>(context, (_) => const ManualEntryScreen()),
      ),
      children: [
        if (reported.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(child: Text('Noch keine gemeldeten Ergebnisse', style: footnoteStyle(context))),
          )
        else
          for (final m in reported) _Row(match: m),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.match});
  final MatchRecord match;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Dismissible(
      key: ValueKey(match.remoteId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: errorColor(),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Text('Löschen', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17)),
      ),
      onDismissed: (_) => s.deleteMatch(match),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => pushModal<bool>(context, (_) => ResultEntryScreen(match: match)),
        child: Container(
          color: isIOS ? CupertinoColors.systemBackground.resolveFrom(context) : Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(match.mode == MatchMode.oneVOne ? '1 vs 1' : '2 vs 2',
                      style: bodyStyle(context).copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Text(DateFormat('dd.MM.yy, HH:mm').format(match.date), style: footnoteStyle(context)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Text(match.wandPlayers.join(' & '), style: bodyStyle(context).copyWith(fontSize: 16))),
                Text('${match.scoreWand} : ${match.scoreTreppe}',
                    style: bodyStyle(context).copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(match.treppePlayers.join(' & '),
                      textAlign: TextAlign.end, style: bodyStyle(context).copyWith(fontSize: 16)),
                ),
              ]),
              if (match.ownGoals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Eigentore: ${match.ownGoals.map((o) => '${o.playerName} (${o.count})').join(', ')}',
                    style: captionStyle(context),
                  ),
                ),
              const SizedBox(height: 8),
              Container(height: 0.5, color: separatorColor(context)),
            ],
          ),
        ),
      ),
    );
  }
}
