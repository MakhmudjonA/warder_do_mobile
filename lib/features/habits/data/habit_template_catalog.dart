import '../domain/entities/habit.dart';
import '../domain/entities/habit_template.dart';
import '../domain/entities/repeat_rule.dart';

/// Каталог готовых привычек — **целиком на стороне приложения**.
///
/// Так же, как каталог групп: экран выбора не делает ни одного запроса,
/// открывается мгновенно и работает без интернета. На сервере
/// (`GET /templates`) шаблонов всего 14 и все на английском, поэтому список
/// для пользователя живёт здесь.
///
/// Чтобы добавить привычку в список, достаточно одной записи в нужной секции.
class HabitTemplateCatalog {
  const HabitTemplateCatalog._();

  // Цвета из палитры приложения.
  static const String _blue = '#4FA8E8';
  static const String _teal = '#4FE8C9';
  static const String _green = '#4FE87A';
  static const String _yellow = '#E8C94F';
  static const String _orange = '#F5A64F';
  static const String _red = '#F54F6C';
  static const String _purple = '#B84FF5';
  static const String _indigo = '#6C7BF5';

  static HabitTemplate _t({
    required String key,
    required String title,
    required String icon,
    required String color,
    String category = 'good',
    double? goalValue,
    String? goalUnit,
    GoalType? goalType,
    HabitType type = HabitType.good,
    RepeatRule repeat = const DailyRepeat(),
  }) {
    return HabitTemplate(
      key: key,
      category: category,
      title: title,
      icon: icon,
      color: color,
      type: type,
      goalValue: goalValue,
      // Значение без единицы и типа сервер не принимает (422), поэтому
      // заполняем их вместе.
      goalUnit: goalValue == null ? null : goalUnit,
      goalType: goalValue == null ? null : (goalType ?? GoalType.atLeast),
      repeatRule: repeat,
    );
  }

  static final List<HabitTemplateSection> sections = [
    HabitTemplateSection(
      title: 'Утро',
      templates: [
        _t(
          key: 'wake_up_on_time',
          title: 'Проснуться вовремя',
          icon: 'sun',
          color: _yellow,
        ),
        _t(
          key: 'get_out_of_bed',
          title: 'Встать с кровати',
          icon: 'morning',
          color: _orange,
        ),
        _t(
          key: 'make_bed',
          title: 'Заправить кровать',
          icon: 'bed',
          color: _purple,
        ),
        _t(key: 'wash_face', title: 'Умыться', icon: 'wash_face', color: _teal),
        _t(
          key: 'brush_teeth',
          title: 'Почистить зубы',
          icon: 'toothbrush',
          color: _blue,
        ),
        _t(key: 'shower', title: 'Принять душ', icon: 'shower', color: _blue),
        _t(
          key: 'stretching',
          title: 'Растяжка',
          icon: 'stretching',
          color: _orange,
          category: 'health',
          goalValue: 5,
          goalUnit: 'minute',
        ),
        _t(
          key: 'vitamins',
          title: 'Принять витамины',
          icon: 'vitamins',
          color: _teal,
          category: 'health',
        ),
        _t(
          key: 'drink_water',
          title: 'Попить воды',
          icon: 'water_drop',
          color: _blue,
          category: 'health',
          goalValue: 2,
          goalUnit: 'liter',
        ),
      ],
    ),
    HabitTemplateSection(
      title: 'День',
      templates: [
        _t(
          key: 'walk',
          title: 'Сходить на прогулку',
          icon: 'walk',
          color: _green,
          category: 'health',
          goalValue: 20,
          goalUnit: 'minute',
        ),
        _t(
          key: 'exercise',
          title: 'Упражнения',
          icon: 'exercise',
          color: _green,
          category: 'health',
          goalValue: 30,
          goalUnit: 'minute',
        ),
        _t(
          key: 'deep_work',
          title: 'Глубокая работа',
          icon: 'deep_work',
          color: _teal,
          goalValue: 90,
          goalUnit: 'minute',
        ),
        _t(
          key: 'meditate',
          title: 'Помедитировать',
          icon: 'meditation',
          color: _purple,
          goalValue: 10,
          goalUnit: 'minute',
        ),
        _t(
          key: 'read_book',
          title: 'Почитать книгу',
          icon: 'book',
          color: _indigo,
          goalValue: 20,
          goalUnit: 'page',
        ),
        _t(
          key: 'learn_language',
          title: 'Учить язык',
          icon: 'language',
          color: _blue,
          goalValue: 15,
          goalUnit: 'minute',
        ),
        _t(
          key: 'code',
          title: 'Программировать',
          icon: 'code',
          color: _teal,
          goalValue: 60,
          goalUnit: 'minute',
        ),
        _t(
          key: 'play_instrument',
          title: 'Играть на инструменте',
          icon: 'instrument',
          color: _red,
          goalValue: 30,
          goalUnit: 'minute',
        ),
      ],
    ),
    HabitTemplateSection(
      title: 'Вечер',
      templates: [
        _t(
          key: 'plan_tomorrow',
          title: 'Спланировать завтра',
          icon: 'plan_tomorrow',
          color: _teal,
          category: 'task',
          type: HabitType.task,
        ),
        _t(
          key: 'journal',
          title: 'Вести дневник',
          icon: 'journal',
          color: _yellow,
        ),
        _t(
          key: 'gratitude',
          title: 'Записать благодарности',
          icon: 'gratitude',
          color: _yellow,
        ),
        _t(
          key: 'something_nice',
          title: 'Сделать что-то приятное',
          icon: 'music',
          color: _purple,
        ),
        _t(
          key: 'call_family',
          title: 'Позвонить близким',
          icon: 'phone_call',
          color: _green,
          repeat: const WeeklyRepeat([7]),
        ),
        _t(
          key: 'sleep_8h',
          title: 'Спать 8 часов',
          icon: 'sleep',
          color: _indigo,
          category: 'health',
          goalValue: 8,
          goalUnit: 'hour',
        ),
      ],
    ),
    HabitTemplateSection(
      title: 'Здоровье и спорт',
      templates: [
        _t(
          key: 'morning_exercise',
          title: 'Утренняя зарядка',
          icon: 'fitness',
          color: _red,
          category: 'health',
          goalValue: 10,
          goalUnit: 'minute',
        ),
        _t(
          key: 'gym',
          title: 'Сходить в спортзал',
          icon: 'gym',
          color: _red,
          category: 'health',
          repeat: const WeeklyRepeat([1, 3, 5]),
        ),
        _t(
          key: 'run',
          title: 'Пробежка',
          icon: 'run',
          color: _red,
          category: 'health',
          goalValue: 3,
          goalUnit: 'km',
        ),
        _t(
          key: 'swim',
          title: 'Плавание',
          icon: 'swim',
          color: _blue,
          category: 'health',
          goalValue: 30,
          goalUnit: 'minute',
          repeat: const WeeklyRepeat([2, 5]),
        ),
        _t(
          key: 'walk_steps',
          title: '10 000 шагов',
          icon: 'walk',
          color: _teal,
          category: 'health',
          goalValue: 10000,
          goalUnit: 'step',
        ),
        _t(
          key: 'healthy_food',
          title: 'Здоровое питание',
          icon: 'healthy_food',
          color: _green,
          category: 'health',
        ),
        _t(
          key: 'eat_fruit',
          title: 'Съесть фрукт',
          icon: 'fruit',
          color: _orange,
          category: 'health',
        ),
        _t(
          key: 'weigh_in',
          title: 'Взвеситься',
          icon: 'weight',
          color: _teal,
          category: 'health',
          repeat: const WeeklyRepeat([1]),
        ),
      ],
    ),
    HabitTemplateSection(
      title: 'Продуктивность',
      templates: [
        _t(
          key: 'plan_day',
          title: 'Спланировать день',
          icon: 'checklist',
          color: _blue,
          category: 'task',
          type: HabitType.task,
          repeat: const WeeklyRepeat([1, 2, 3, 4, 5]),
        ),
        _t(
          key: 'inbox_zero',
          title: 'Разобрать почту',
          icon: 'mail',
          color: _indigo,
          category: 'task',
          type: HabitType.task,
          repeat: const WeeklyRepeat([1, 2, 3, 4, 5]),
        ),
        _t(
          key: 'weekly_review',
          title: 'Итоги недели',
          icon: 'calendar',
          color: _purple,
          category: 'task',
          type: HabitType.task,
          repeat: const WeeklyRepeat([7]),
        ),
        _t(
          key: 'study',
          title: 'Учёба',
          icon: 'study',
          color: _indigo,
          goalValue: 30,
          goalUnit: 'minute',
        ),
        _t(key: 'tidy_up', title: 'Убраться', icon: 'clean', color: _blue),
        _t(
          key: 'water_plants',
          title: 'Полить цветы',
          icon: 'plant',
          color: _green,
          repeat: const IntervalRepeat(3),
        ),
        _t(
          key: 'save_money',
          title: 'Отложить деньги',
          icon: 'money',
          color: _green,
          repeat: const WeeklyRepeat([5]),
        ),
        _t(
          key: 'shopping_list',
          title: 'Составить список покупок',
          icon: 'shopping',
          color: _orange,
          category: 'task',
          type: HabitType.task,
          repeat: const WeeklyRepeat([6]),
        ),
      ],
    ),
    HabitTemplateSection(
      title: 'Плохие привычки',
      templates: [
        _t(
          key: 'no_smoking',
          title: 'Не курить',
          icon: 'smoke_free',
          color: _red,
          category: 'bad',
          type: HabitType.bad,
        ),
        _t(
          key: 'less_social_media',
          title: 'Меньше соцсетей',
          icon: 'phone_off',
          color: _orange,
          category: 'bad',
          type: HabitType.bad,
          goalValue: 30,
          goalUnit: 'minute',
          goalType: GoalType.atMost,
        ),
        _t(
          key: 'no_sugar',
          title: 'Без сахара',
          icon: 'no_sweets',
          color: _purple,
          category: 'bad',
          type: HabitType.bad,
        ),
        _t(
          key: 'no_alcohol',
          title: 'Без алкоголя',
          icon: 'no_alcohol',
          color: _red,
          category: 'bad',
          type: HabitType.bad,
        ),
        _t(
          key: 'less_coffee',
          title: 'Меньше кофе',
          icon: 'coffee',
          color: _orange,
          category: 'bad',
          type: HabitType.bad,
          goalValue: 2,
          goalUnit: 'time',
          goalType: GoalType.atMost,
        ),
        _t(
          key: 'no_fast_food',
          title: 'Без фастфуда',
          icon: 'nutrition',
          color: _yellow,
          category: 'bad',
          type: HabitType.bad,
        ),
        _t(
          key: 'no_phone_in_bed',
          title: 'Без телефона в кровати',
          icon: 'no_phone',
          color: _indigo,
          category: 'bad',
          type: HabitType.bad,
        ),
      ],
    ),
  ];

  /// Плоский список — удобно для тестов и поиска.
  static List<HabitTemplate> get all => [
    for (final section in sections) ...section.templates,
  ];

  /// Фильтр для поля поиска: секции без совпадений просто не показываем.
  static List<HabitTemplateSection> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sections;

    final result = <HabitTemplateSection>[];
    for (final section in sections) {
      final matches = section.templates
          .where((t) => t.title.toLowerCase().contains(q))
          .toList();
      if (matches.isNotEmpty) {
        result.add(
          HabitTemplateSection(title: section.title, templates: matches),
        );
      }
    }
    return result;
  }
}
