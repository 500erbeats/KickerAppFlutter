import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../models/draw_engine.dart';
import '../models/stats_calculator.dart';

const _ink = Color(0xFF111111);
const _grey = Color(0xFF6B6B6B);

/// Rendert ein Widget unsichtbar (außerhalb des Bildschirms) zu einem PNG und öffnet das
/// native Teilen-Menü — entspricht ImageRenderer + UIActivityViewController auf iOS.
Future<void> shareWidgetAsImage(BuildContext context, Widget card, {String filename = 'kicker.png'}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -5000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: key, child: card),
      ),
    ),
  );
  overlay.insert(entry);

  try {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await Share.shareXFiles(
      [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: filename)],
      sharePositionOrigin: origin,
    );
  } finally {
    entry.remove();
  }
}

TextStyle _s(double size, {FontWeight w = FontWeight.normal, Color c = _ink}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, decoration: TextDecoration.none);

class DrawShareCard extends StatelessWidget {
  const DrawShareCard({
    super.key,
    required this.game1,
    required this.game2,
    required this.wandLabel,
    required this.treppeLabel,
  });
  final DrawOutcome game1;
  final DrawOutcome game2;
  final String wandLabel;
  final String treppeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚽ Kicker-Auslosung', style: _s(22, w: FontWeight.bold)),
          const SizedBox(height: 20),
          _block('Match 1', game1),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFE0E0E0)),
          const SizedBox(height: 14),
          _block('Match 2', game2),
        ],
      ),
    );
  }

  Widget _block(String title, DrawOutcome o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _s(17, w: FontWeight.w600, c: _grey)),
        const SizedBox(height: 6),
        for (final a in o.assignments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(a.position.displayName(wandLabel, treppeLabel), style: _s(17, c: _grey))),
              Text(a.playerName, style: _s(17, w: FontWeight.bold)),
            ]),
          ),
        if (o.bench.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text('Bank', style: _s(17, c: _grey))),
              Text(o.bench.join(', '), style: _s(17)),
            ]),
          ),
      ],
    );
  }
}

class PokalShareCard extends StatelessWidget {
  const PokalShareCard({
    super.key,
    required this.periodLabel,
    required this.bestOneVOne,
    required this.bestTwoVTwo,
    required this.mostOwnGoals,
  });
  final String periodLabel;
  final PlayerWinLossStat? bestOneVOne;
  final PlayerWinLossStat? bestTwoVTwo;
  final MapEntry<String, int>? mostOwnGoals;

  String _wr(PlayerWinLossStat s) =>
      'Winrate ${s.winrate.toStringAsFixed(2).replaceAll('.', ',')} (${s.wins}/${s.losses})';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5EC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚽ Kicker-Pokale', style: _s(28, w: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(periodLabel, style: _s(17, w: FontWeight.w600, c: _grey)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFD0D0D0)),
          const SizedBox(height: 20),
          _row(Icons.person, 'Bester 1vs1', bestOneVOne?.name, bestOneVOne == null ? null : _wr(bestOneVOne!)),
          const SizedBox(height: 20),
          _row(Icons.people, 'Bester 2vs2', bestTwoVTwo?.name, bestTwoVTwo == null ? null : _wr(bestTwoVTwo!)),
          const SizedBox(height: 20),
          _row(Icons.sports_soccer, 'Meiste Eigentore', mostOwnGoals?.key,
              mostOwnGoals == null ? null : '${mostOwnGoals!.value} Eigentore'),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String? winner, String? detail) {
    return Row(
      children: [
        SizedBox(width: 36, child: Icon(icon, size: 26, color: const Color(0xFFFFCC00))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _s(12, c: _grey)),
              Text(winner ?? '–', style: _s(20, w: FontWeight.bold)),
              if (detail != null) Text(detail, style: _s(11, c: _grey)),
            ],
          ),
        ),
      ],
    );
  }
}
