import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/constants/habit_icons.dart';
import 'package:warder_do_mobile/core/constants/habit_visuals.dart';

void main() {
  test('har bir ikonka kaliti uchun glif bor', () {
    final missing = HabitEmoji.catalog.keys
        .where((key) => !HabitIcons.glyphs.containsKey(key))
        .toList();
    expect(missing, isEmpty);
  });

  test('noma’lum kalit — fallback, ilova qulamaydi', () {
    expect(HabitIcons.resolve('no-such-key'), HabitIcons.fallback);
    expect(HabitIcons.resolve(null), HabitIcons.fallback);
  });
}
