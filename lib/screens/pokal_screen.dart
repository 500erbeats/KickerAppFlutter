import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/position.dart';
import '../models/stats_calculator.dart';
import '../models/stats_period.dart';
import '../widgets/adaptive.dart';
import '../widgets/share_cards.dart';

class PokalScreen extends StatefulWidget {
  const PokalScreen({super.key});

  @override
  State<PokalScreen> createState() => _PokalScreenState();
}

class _PokalScreenState extends State<PokalScreen> {
  int _offset = 0;

  String _wr(PlayerWinLossStat s) =>
      'Winrate ${s.winrate.toStringAsFixed(2).replaceAll('.', ',')} (${s.wins}/${s.losses})';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final range = currentRange(s.settings.statsPeriod, offset: _offset);
    final active = s.reportedMatches.where((m) => range.contains(m.date)).toList();

    final best1 = StatsCalculator.winLossStats(active, MatchMode.oneVOne).firstOrNull;
    final best2 = StatsCalculator.winLossStats(active, MatchMode.twoVTwo).firstOrNull;
    final ownGoals = StatsCalculator.ownGoalStats(active).firstOrNull;

    return AdaptiveScaffold(
      title: 'Pokal-Export',
      inlineTitle: true,
      grouped: true,
      trailing: BarIconButton(
        icon: isIOS ? CupertinoIcons.share : Icons.share,
        tooltip: 'Teilen',
        onPressed: () => shareWidgetAsImage(
          context,
          PokalShareCard(periodLabel: range.label, bestOneVOne: best1, bestTwoVTwo: best2, mostOwnGoals: ownGoals),
          filename: 'kicker-pokale.png',
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cardColor(context), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            BarIconButton(
              icon: isIOS ? CupertinoIcons.chevron_left : Icons.chevron_left,
              onPressed: () => setState(() => _offset -= 1),
            ),
            Expanded(
              child: Column(children: [
                Text(range.label, style: headlineStyle(context)),
                if (_offset != 0) Text('vergangener Zeitraum', style: captionStyle(context)),
              ]),
            ),
            BarIconButton(
              icon: isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
              onPressed: _offset >= 0 ? null : () => setState(() => _offset += 1),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AdaptiveSection(
          header: '🏆 Pokale',
          children: [
            _trophy(context, isIOS ? CupertinoIcons.person_fill : Icons.person, 'Bester 1vs1', best1?.name,
                best1 == null ? null : _wr(best1)),
            _trophy(context, isIOS ? CupertinoIcons.person_2_fill : Icons.people, 'Bester 2vs2', best2?.name,
                best2 == null ? null : _wr(best2)),
            _trophy(context, Icons.sports_soccer, 'Meiste Eigentore', ownGoals?.key,
                ownGoals == null ? null : '${ownGoals.value} Eigentore'),
          ],
        ),
      ],
    );
  }

  Widget _trophy(BuildContext context, IconData icon, String title, String? winner, String? detail) {
    return Row(children: [
      SizedBox(width: 32, child: Icon(icon, size: 24, color: const Color(0xFFFFCC00))),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: headlineStyle(context)),
          if (winner != null) ...[
            Text(winner, style: bodyStyle(context).copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            if (detail != null) Text(detail, style: footnoteStyle(context)),
          ] else
            Text('Noch keine Daten', style: footnoteStyle(context).copyWith(fontSize: 15)),
        ]),
      ),
    ]);
  }
}
