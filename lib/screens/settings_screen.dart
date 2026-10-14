import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/stats_period.dart';
import '../widgets/adaptive.dart';
import 'sheet_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _newName = TextEditingController();
  late final TextEditingController _url;
  late final TextEditingController _wand;
  late final TextEditingController _treppe;
  String _status = '';
  bool _checking = false;
  bool _pulling = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _url = TextEditingController(text: s.sheetUrl);
    _wand = TextEditingController(text: s.wandLabel);
    _treppe = TextEditingController(text: s.treppeLabel);
  }

  @override
  void dispose() {
    _newName.dispose();
    _url.dispose();
    _wand.dispose();
    _treppe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;
    final syncReady = settings.sheetSyncEnabled && settings.sheetUrl.trim().isNotEmpty;

    return AdaptiveScaffold(
      title: 'Einstellungen',
      grouped: true,
      children: [
        AdaptiveSection(
          header: 'Feste Namen',
          children: [
            if (state.players.isEmpty) Text('Noch keine Namen', style: footnoteStyle(context)),
            for (final p in state.players)
              Dismissible(
                key: ValueKey('player-${p.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: errorColor(),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Color(0xFFFFFFFF)),
                ),
                onDismissed: (_) => state.deletePlayer(p),
                child: SizedBox(width: double.infinity, child: Text(p.name, style: bodyStyle(context))),
              ),
          ],
        ),
        AdaptiveSection(children: [
          Row(children: [
            Expanded(
              child: AdaptiveTextField(
                controller: _newName,
                placeholder: 'Neuer Name',
                borderless: true,
                onSubmitted: (_) => _addPlayer(state),
              ),
            ),
            BarTextButton(label: 'Hinzufügen', onPressed: () => _addPlayer(state)),
          ]),
        ]),
        AdaptiveSection(children: [
          Text('„Reserve“ steht immer zusätzlich zur Auswahl, unabhängig von dieser Liste.', style: footnoteStyle(context)),
        ]),
        AdaptiveSection(
          header: 'Auswertungszeitraum',
          children: [
            AdaptiveSegmented<StatsPeriod>(
              value: settings.statsPeriod,
              options: {for (final p in StatsPeriod.values) p: p.label},
              onChanged: (p) => state.updateSettings(settings.copyWith(statsPeriod: p)),
            ),
            Text(
              'Legt fest, welcher laufende Zeitraum in den Tabellen und beim Pokal-Export ausgewertet wird.',
              style: footnoteStyle(context),
            ),
          ],
        ),
        AdaptiveSection(
          header: 'Google Sheet Sync',
          footer:
              'Der Schalter lässt sich jederzeit umlegen, ohne die hinterlegte URL zu verlieren. Solange er aus ist, passiert nichts Richtung Sheet — weder Push noch automatischer Abruf beim Start.',
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => pushPage<void>(context, (_) => const SheetGuideScreen()),
              child: Row(children: [
                Icon(isIOS ? CupertinoIcons.question_circle : Icons.help_outline, color: accentColor(context), size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Anleitung & Code anzeigen', style: bodyStyle(context))),
                Icon(isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right, size: 16, color: secondaryLabelColor(context)),
              ]),
            ),
            Row(children: [
              Expanded(child: Text('Sheet-Übertragung aktiv', style: bodyStyle(context))),
              AdaptiveSwitch(
                value: settings.sheetSyncEnabled,
                onChanged: (v) => state.updateSettings(settings.copyWith(sheetSyncEnabled: v)),
              ),
            ]),
            AdaptiveTextField(
              controller: _url,
              placeholder: 'Apps-Script Web-App-URL',
              borderless: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (v) => state.updateSettings(settings.copyWith(sheetUrl: v)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: BarTextButton(
                label: _checking ? 'Prüfe…' : 'Jetzt prüfen',
                onPressed: syncReady && !_checking
                    ? () async {
                        setState(() => _checking = true);
                        final r = await state.checkSync();
                        if (mounted) setState(() { _status = r; _checking = false; });
                      }
                    : null,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: BarTextButton(
                label: _pulling ? 'Rufe ab…' : 'Neue Ergebnisse abrufen',
                onPressed: syncReady && !_pulling
                    ? () async {
                        setState(() => _pulling = true);
                        final r = await state.pullFromSheet();
                        if (mounted) setState(() { _status = r; _pulling = false; });
                      }
                    : null,
              ),
            ),
            if (_status.isNotEmpty) Text(_status, style: footnoteStyle(context)),
          ],
        ),
        AdaptiveSection(
          header: 'Seiten benennen',
          footer:
              'Leer lassen für die Standardnamen „Wandseite“ / „Treppenseite“. Wirkt sich auf Auslosung, Ergebnismeldung und manuelles Nachtragen aus.',
          children: [
            AdaptiveTextField(
              controller: _wand,
              placeholder: 'Wandseite',
              borderless: true,
              onChanged: (v) => state.updateSettings(settings.copyWith(wandLabel: v)),
            ),
            AdaptiveTextField(
              controller: _treppe,
              placeholder: 'Treppenseite',
              borderless: true,
              onChanged: (v) => state.updateSettings(settings.copyWith(treppeLabel: v)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addPlayer(AppState state) async {
    final name = _newName.text;
    if (name.trim().isEmpty) return;
    await state.addPlayer(name);
    _newName.clear();
  }
}
