import 'package:apploook/services/scheduled_maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tashkent wall-clock time (UTC+5) as a UTC instant.
DateTime tashkent(int y, int m, int d, int h, int min, [int s = 0]) =>
    DateTime.utc(y, m, d, h, min, s).subtract(const Duration(hours: 5));

void main() {
  // 2026-11-20 is a Friday.
  setUpAll(() => expect(DateTime.utc(2026, 11, 20).weekday, DateTime.friday));

  group('isActive', () {
    test('Friday window edges (start inclusive, end exclusive)', () {
      expect(ScheduledMaintenance.isActive(tashkent(2026, 11, 20, 12, 54, 59)),
          isFalse);
      expect(ScheduledMaintenance.isActive(tashkent(2026, 11, 20, 12, 55)),
          isTrue);
      expect(ScheduledMaintenance.isActive(tashkent(2026, 11, 20, 13, 10)),
          isTrue);
      expect(ScheduledMaintenance.isActive(tashkent(2026, 11, 20, 13, 24, 59)),
          isTrue);
      expect(ScheduledMaintenance.isActive(tashkent(2026, 11, 20, 13, 25)),
          isFalse);
    });

    test('same time on other days is not blocked', () {
      for (var d = 14; d <= 19; d++) {
        expect(ScheduledMaintenance.isActive(tashkent(2026, 11, d, 13, 0)),
            isFalse,
            reason: 'Nov $d');
      }
    });

    test('uses Tashkent time regardless of device zone', () {
      // 13:00 Tashkent == 08:00 UTC; an instant is an instant whatever the
      // DateTime's zone, so a device in another zone gives the same answer.
      final instant = DateTime.utc(2026, 11, 20, 8, 0);
      expect(ScheduledMaintenance.isActive(instant), isTrue);
      expect(ScheduledMaintenance.isActive(instant.toLocal()), isTrue);
      // 13:00 UTC on Friday is 18:00 in Tashkent: open.
      expect(ScheduledMaintenance.isActive(DateTime.utc(2026, 11, 20, 13, 0)),
          isFalse);
    });
  });

  group('untilNextChange', () {
    test('before the window -> until it opens', () {
      expect(
          ScheduledMaintenance.untilNextChange(tashkent(2026, 11, 20, 12, 0)),
          const Duration(minutes: 55));
    });

    test('inside the window -> until it closes', () {
      expect(
          ScheduledMaintenance.untilNextChange(tashkent(2026, 11, 20, 13, 0)),
          const Duration(minutes: 25));
    });

    test('after the window -> next Friday', () {
      expect(
          ScheduledMaintenance.untilNextChange(tashkent(2026, 11, 20, 13, 25)),
          const Duration(days: 7) - const Duration(minutes: 30));
    });

    test('midweek -> coming Friday 12:55', () {
      expect(
          ScheduledMaintenance.untilNextChange(tashkent(2026, 11, 18, 12, 55)),
          const Duration(days: 2));
    });
  });

  test('endsAtLabel', () {
    expect(ScheduledMaintenance.endsAtLabel, '13:25');
  });
}
