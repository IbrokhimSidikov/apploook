/// Recurring maintenance window: every Friday 12:55-13:25 Tashkent time.
///
/// Evaluated in Tashkent time (UTC+5, no DST) from the UTC clock rather than
/// the device time zone, so a phone set to another zone (or a traveller)
/// still closes at the same moment the restaurants do.
class ScheduledMaintenance {
  const ScheduledMaintenance._();

  static const Duration _tashkentOffset = Duration(hours: 5);
  static const int _weekday = DateTime.friday;
  static const int _startMinute = 12 * 60 + 55; // 12:55, inclusive
  static const int _endMinute = 13 * 60 + 25; // 13:25, exclusive

  /// "13:25" - when the app opens again, for the dialog text.
  static String get endsAtLabel =>
      '${_endMinute ~/ 60}:${(_endMinute % 60).toString().padLeft(2, '0')}';

  /// Wall-clock Tashkent time as a UTC-flagged DateTime (fields are local).
  static DateTime _tashkent(DateTime now) => now.toUtc().add(_tashkentOffset);

  static bool isActive([DateTime? now]) {
    final t = _tashkent(now ?? DateTime.now());
    final minute = t.hour * 60 + t.minute;
    return t.weekday == _weekday &&
        minute >= _startMinute &&
        minute < _endMinute;
  }

  /// Time until the window next opens or closes, for scheduling a re-check.
  static Duration untilNextChange([DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final t = _tashkent(current);
    final midnight = DateTime.utc(t.year, t.month, t.day);
    final candidates = <DateTime>[];
    for (var day = 0; day <= 7; day++) {
      final date = midnight.add(Duration(days: day));
      if (date.weekday != _weekday) continue;
      candidates
        ..add(date.add(const Duration(minutes: _startMinute)))
        ..add(date.add(const Duration(minutes: _endMinute)));
    }
    final next = candidates.firstWhere((c) => c.isAfter(t));
    return next.difference(t);
  }
}
