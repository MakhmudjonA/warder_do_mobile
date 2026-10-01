import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/constants/goal_units.dart';
import 'package:warder_do_mobile/core/constants/habit_visuals.dart';
import 'package:warder_do_mobile/features/habits/data/habit_template_catalog.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/repeat_rule.dart';

void main() {
  final catalog = HabitTemplateCatalog.all;

  test('каталог не пустой и ключи уникальные', () {
    expect(catalog.length, greaterThan(30));

    final keys = catalog.map((t) => t.key).toList();
    expect(keys.toSet().length, keys.length, reason: 'есть дубли ключей');
  });

  test('у каждого шаблона есть эмодзи — «❓» в списке быть не должно', () {
    for (final template in catalog) {
      expect(
        HabitEmoji.catalog.containsKey(template.icon),
        isTrue,
        reason: 'нет эмодзи для "${template.icon}" (${template.title})',
      );
    }
  });

  test('категории соответствуют вкладкам и типам привычки', () {
    const allowed = {'good', 'health', 'bad', 'task'};

    for (final template in catalog) {
      expect(allowed, contains(template.category));

      // Вкладка «Плохие» должна давать привычку типа bad, «Задачи» — task.
      if (template.category == 'bad') {
        expect(template.type, HabitType.bad, reason: template.key);
      }
      if (template.category == 'task') {
        expect(template.type, HabitType.task, reason: template.key);
      }
    }

    // Каждая вкладка чем-то заполнена.
    for (final category in allowed) {
      expect(
        catalog.where((t) => t.category == category),
        isNotEmpty,
        reason: 'пустая вкладка $category',
      );
    }
  });

  test('цель задана целиком или её нет вовсе', () {
    for (final template in catalog) {
      if (template.goalValue == null) {
        // Без значения сервер вернёт 422 на unit/type.
        expect(template.goalUnit, isNull, reason: template.key);
        expect(template.goalType, isNull, reason: template.key);
      } else {
        expect(template.goalUnit, isNotNull, reason: template.key);
        expect(template.goalType, isNotNull, reason: template.key);
        expect(template.goalValue, greaterThan(0), reason: template.key);
      }
    }
  });

  test('дни недели в диапазоне 1..7', () {
    for (final template in catalog) {
      final rule = template.repeatRule;
      if (rule is WeeklyRepeat) {
        expect(rule.days, isNotEmpty, reason: template.key);
        for (final day in rule.days) {
          expect(day, inInclusiveRange(1, 7), reason: template.key);
        }
      }
    }
  });

  group('секции', () {
    test('секции не пустые и заголовки уникальные', () {
      final sections = HabitTemplateCatalog.sections;
      expect(sections.length, greaterThanOrEqualTo(5));

      for (final section in sections) {
        expect(section.templates, isNotEmpty, reason: section.title);
      }

      final titles = sections.map((s) => s.title).toList();
      expect(titles.toSet().length, titles.length);
    });

    test('поиск фильтрует по названию и убирает пустые секции', () {
      final found = HabitTemplateCatalog.search('воды');
      final titles = found
          .expand((s) => s.templates)
          .map((t) => t.title)
          .toList();

      expect(titles, contains('Попить воды'));
      expect(titles.length, 1);
      for (final section in found) {
        expect(section.templates, isNotEmpty);
      }
    });

    test('пустой запрос возвращает весь каталог', () {
      expect(
        HabitTemplateCatalog.search('   ').length,
        HabitTemplateCatalog.sections.length,
      );
    });

    test('несуществующий запрос — пустой результат', () {
      expect(HabitTemplateCatalog.search('zzzzz'), isEmpty);
    });
  });

  test('birliklar — backend biladigan inglizcha kalitlar', () {
    for (final template in HabitTemplateCatalog.all) {
      final unit = template.goalUnit;
      if (unit == null) continue;
      expect(GoalUnits.labels.containsKey(unit), isTrue, reason: template.key);
    }
  });
}
