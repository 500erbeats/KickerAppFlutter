# Kicker-App – Flutter

Ein Code-Projekt für iOS **und** Android, bearbeitbar in VS Code.

- **iOS** nutzt Cupertino-Widgets (Large Titles, Inset-Grouped-Listen, Segmented Control,
  Stepper, Systemblau als Akzent) → soll aussehen wie die bisherige SwiftUI-App.
- **Android** nutzt normales Material 3 (darf anders aussehen).
- Gleiche Logik wie bisher: Auslosung (identische Regeln), Ergebnisse inkl. KISCHDE/ULTRAKISCHDE,
  manuelles Nachtragen, Verlauf (antippen = bearbeiten, wischen = löschen), Tabellen mit
  Zeitraum, Pokal-Export (Zeitraum blättern + als Bild teilen), Auslosung als Bild teilen,
  letzte Auslosung bleibt nach App-Neustart erhalten, Google-Sheet-Sync (**dasselbe Apps Script**),
  eingebaute Anleitung inkl. kopierbarem Script-Code.

## Einrichten (einmalig)

1. Flutter SDK installieren (flutter.dev), in VS Code die Extensions „Flutter“ + „Dart“.
   `flutter doctor` muss für iOS (Xcode) und Android (Android Studio SDK) grün sein.
2. Plattform-Ordner erzeugen – am sichersten so:
   ```
   flutter create --org com.DEINPRAEFIX --project-name kicker_app kicker_app_neu
   ```
   Danach aus diesem Zip in `kicker_app_neu/` **kopieren/ersetzen**: `lib/`, `test/`, `AppsScript/`, `pubspec.yaml`.
   Die Datei `kicker_app_neu/test/widget_test.dart` löschen (bezieht sich auf die Standard-Vorlage). Mit `flutter test` lässt sich danach der Datums-Parser prüfen.
3. `flutter pub get` und `flutter run` (iOS-Simulator bzw. Android-Emulator/Gerät).

## Wichtig für den Wechsel von den nativen Apps

- **Bundle-ID / Application-ID gleich lassen** wie in den bestehenden Apps, sonst ist es für den
  App Store / Play Store eine *neue* App. iOS: in Xcode (`ios/Runner.xcworkspace`) Bundle Identifier,
  Team (Jonas' Account) und Signing setzen; Versionsnummer höher als die aktuelle (`pubspec.yaml: version`).
- **Lokale Daten werden NICHT automatisch übernommen** (SwiftData/Room → SQLite). Wer Sheet-Sync
  aktiv hat, bekommt alles über „Neue Ergebnisse abrufen“ zurück. Vor dem Umstieg also sicherstellen,
  dass alle Nutzer synchronisiert haben.
- iOS `Info.plist`: `NSPhotoLibraryAddUsageDescription` eintragen (damit „Bild sichern“ im Teilen-Menü erscheint).

## Bekannte Abweichungen zum SwiftUI-Look (zum Feintunen)

- Icons: Cupertino-Icons statt SF Symbols (Trophäe/Verlauf sehen leicht anders aus).
- Kein „Edit“-Button in den Einstellungen – Löschen per Wischgeste (Namen und Verlauf).
- Pixel-genaue Abstände/Schriftgrößen sind nachgebaut, aber ungetestet: bitte Screenshots alt/neu
  nebeneinanderlegen und Abstände in `lib/widgets/adaptive.dart` nachziehen.
