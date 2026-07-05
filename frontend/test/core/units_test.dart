import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/core/units.dart';

void main() {
  test('kg↔lbs round-trips', () {
    expect(Units.kgToLbs(78.2), closeTo(172.4, 0.05));
    expect(Units.lbsToKg(Units.kgToLbs(78.2)), closeTo(78.2, 0.0001));
  });

  test('formatLbs keeps one decimal only when needed', () {
    expect(formatLbs(172.42), '172.4');
    expect(formatLbs(172.0), '172');
    expect(formatLbs(171.96), '172');
  });

  test('formatKcal groups thousands', () {
    expect(formatKcal(1284), '1,284');
    expect(formatKcal(486), '486');
  });

  test('capsDate matches the design (TUESDAY · JULY 7)', () {
    expect(capsDate(DateTime(2026, 7, 7)), 'TUESDAY · JULY 7');
  });

  test('apiDate is YYYY-MM-DD', () {
    expect(apiDate(DateTime(2026, 7, 6)), '2026-07-06');
  });
}
