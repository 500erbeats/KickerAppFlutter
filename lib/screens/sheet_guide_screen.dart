import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/apps_script_code.dart';
import '../widgets/adaptive.dart';

class SheetGuideScreen extends StatefulWidget {
  const SheetGuideScreen({super.key});

  @override
  State<SheetGuideScreen> createState() => _SheetGuideScreenState();
}

class _SheetGuideScreenState extends State<SheetGuideScreen> {
  bool _copied = false;

  static const _steps = [
    ('Google Sheet anlegen',
        'Erstelle eine neue (oder nutze eine bestehende) Tabelle unter sheets.google.com. Der Name der Tabelle ist egal.'),
    ('Apps Script öffnen',
        'Im Sheet: Menü „Erweiterungen“ → „Apps Script“. Es öffnet sich ein neuer Tab mit einem leeren Code-Editor.'),
    ('Code einfügen',
        'Platzhaltercode komplett löschen, stattdessen den Code weiter unten einfügen (Button „Code kopieren“ nutzen). Danach speichern (Cmd/Strg+S).'),
    ('Als Web App deployen',
        'Oben rechts „Deploy“ → „Neuer Deployment“ → Zahnrad-Symbol → „Web App“. Bei „Execute as“ auf „Ich“ lassen. Bei „Who has access“ unbedingt „Jeder“ (Anyone) wählen — nicht „Jeder mit Google-Konto“, sonst kann die App nicht zugreifen. Dann „Deploy“ klicken, ggf. Berechtigung bestätigen.'),
    ('Web-App-URL kopieren',
        'Nach dem Deploy zeigt Google eine lange URL, die auf „/exec“ endet. Komplett kopieren.'),
    ('URL hier eintragen',
        'Zurück in den Einstellungen: URL ins Feld „Apps-Script Web-App-URL“ einfügen und den Schalter „Sheet-Übertragung aktiv“ einschalten.'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = accentColor(context);
    return AdaptiveScaffold(
      title: 'Google Sheet verbinden',
      inlineTitle: true,
      grouped: true,
      children: [
        AdaptiveSection(children: [
          Text(
            'Damit Ergebnisse zusätzlich in eine Google-Tabelle geschrieben werden — und Kollegen ohne die App per Link Ergebnisse eintragen können — brauchst du ein kleines, kostenloses Google Apps Script. Einmal einrichten, danach läuft alles automatisch im Hintergrund.',
            style: footnoteStyle(context),
          ),
        ]),
        AdaptiveSection(
          header: 'Schritt für Schritt',
          children: [
            for (var i = 0; i < _steps.length; i++)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_steps[i].$1, style: headlineStyle(context)),
                    const SizedBox(height: 4),
                    Text(_steps[i].$2, style: footnoteStyle(context)),
                  ]),
                ),
              ]),
          ],
        ),
        AdaptiveSection(
          header: 'Apps-Script-Code',
          footer:
              'Falls der Code später aktualisiert wird: im Apps-Script-Editor wieder „Deploy“ → „Manage deployments“ → Stift-Symbol → „New version“ → Deploy — sonst wird die Änderung nicht übernommen, obwohl die URL gleich bleibt.',
          children: [
            SizedBox(
              height: 260,
              child: SingleChildScrollView(
                child: SelectableText(
                  appsScriptSource,
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: labelColor(context)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: BarTextButton(
                label: _copied ? '✓ Kopiert!' : 'Code kopieren',
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: appsScriptSource));
                  if (mounted) setState(() => _copied = true);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
