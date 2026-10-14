import 'package:flutter_test/flutter_test.dart';
import 'package:kicker_app/network/sheet_sync_service.dart';

void main() {
  group('SheetSyncService.parseSheetDate', () {
    test('ISO ohne Millisekunden', () {
      final d = SheetSyncService.parseSheetDate('2026-10-05T21:30:00Z')!;
      expect(d.toUtc(), DateTime.utc(2026, 10, 5, 21, 30));
    });

    test('ISO mit Millisekunden (Web-Formular, Android, von Sheets umgewandelte Zellen)', () {
      final d = SheetSyncService.parseSheetDate('2026-10-05T21:30:00.000Z')!;
      expect(d.toUtc(), DateTime.utc(2026, 10, 5, 21, 30));
    });

    test('von Hand getipptes deutsches Datum', () {
      expect(SheetSyncService.parseSheetDate('05.10.2026'), DateTime(2026, 10, 5, 12));
      expect(SheetSyncService.parseSheetDate('5.10.2026 18:45'), DateTime(2026, 10, 5, 18, 45));
    });

    test('Unbrauchbares ergibt null', () {
      expect(SheetSyncService.parseSheetDate(''), isNull);
      expect(SheetSyncService.parseSheetDate('quatsch'), isNull);
    });
  });
}
