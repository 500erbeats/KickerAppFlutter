enum StatsPeriod {
  month('Monat'),
  quarter('Quartal'),
  halfYear('Halbjahr'),
  year('Jahr');

  final String label;
  const StatsPeriod(this.label);

  static StatsPeriod fromName(String name) =>
      StatsPeriod.values.firstWhere((p) => p.name == name, orElse: () => StatsPeriod.quarter);
}

class PeriodRange {
  final DateTime start;
  final DateTime end;
  final String label;
  const PeriodRange({required this.start, required this.end, required this.label});

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}

const _monthNames = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
];

/// Zeitraum relativ zu "jetzt", verschoben um [offset] ganze Perioden
/// (0 = aktuell, -1 = vorherige, ...) — feste Kalenderabschnitte, nicht rollierend.
PeriodRange currentRange(StatsPeriod period, {int offset = 0, DateTime? now}) {
  final base = now ?? DateTime.now();
  DateTime shifted;
  switch (period) {
    case StatsPeriod.month:
      shifted = DateTime(base.year, base.month + offset, 1);
      break;
    case StatsPeriod.quarter:
      shifted = DateTime(base.year, base.month + offset * 3, 1);
      break;
    case StatsPeriod.halfYear:
      shifted = DateTime(base.year, base.month + offset * 6, 1);
      break;
    case StatsPeriod.year:
      shifted = DateTime(base.year + offset, base.month, 1);
      break;
  }
  final year = shifted.year;
  final month = shifted.month;

  switch (period) {
    case StatsPeriod.month:
      return PeriodRange(
        start: DateTime(year, month, 1),
        end: DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1)),
        label: '${_monthNames[month - 1]} $year',
      );
    case StatsPeriod.quarter:
      final q = ((month - 1) ~/ 3) * 3 + 1;
      return PeriodRange(
        start: DateTime(year, q, 1),
        end: DateTime(year, q + 3, 1).subtract(const Duration(seconds: 1)),
        label: 'Q${((month - 1) ~/ 3) + 1} $year',
      );
    case StatsPeriod.halfYear:
      final h = month <= 6 ? 1 : 7;
      return PeriodRange(
        start: DateTime(year, h, 1),
        end: DateTime(year, h + 6, 1).subtract(const Duration(seconds: 1)),
        label: 'H${month <= 6 ? 1 : 2} $year',
      );
    case StatsPeriod.year:
      return PeriodRange(
        start: DateTime(year, 1, 1),
        end: DateTime(year + 1, 1, 1).subtract(const Duration(seconds: 1)),
        label: '$year',
      );
  }
}
