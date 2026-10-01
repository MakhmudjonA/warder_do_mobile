import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/constants/app_strings.dart';
import 'package:warder_do_mobile/core/utils/date_labels.dart';

void main() {
  final now = DateTime(2026, 9, 30, 14);

  test('bugun, ertaga, kecha', () {
    expect(dayLabel(DateTime(2026, 9, 30), now: now), AppStrings.today);
    expect(dayLabel(DateTime(2026, 10, 1), now: now), AppStrings.tomorrow);
    expect(dayLabel(DateTime(2026, 9, 29), now: now), AppStrings.yesterday);
  });

  test('boshqa kun — "5 октября", boshqa yil — yil bilan', () {
    expect(dayLabel(DateTime(2026, 10, 5), now: now), '5 октября');
    expect(dayLabel(DateTime(2027, 1, 2), now: now), '2 января 2027');
  });
}
