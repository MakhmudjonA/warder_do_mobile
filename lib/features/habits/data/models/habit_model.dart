import '../../../../core/utils/api_date.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/repeat_rule.dart';

/// `repeat_rule` JSON ↔ [RepeatRule] o'girish.
///
/// Alohida ajratilgan, chunki u habit, shablon va yaratish so'rovida —
/// uch joyda ishlatiladi.
class RepeatRuleMapper {
  const RepeatRuleMapper._();

  static RepeatRule fromJson(Map<String, dynamic>? json) {
    switch (json?['type']) {
      case 'weekly':
        final days =
            (json?['days'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            const <int>[];
        return WeeklyRepeat(days);
      case 'interval':
        return IntervalRepeat((json?['every_n_days'] as num?)?.toInt() ?? 1);
      case 'program':
        return const ProgramRepeat();
      case 'once':
        final date = ApiDate.tryParse(json?['date']);
        // Buzuq sana — ilova qulamasin, "har kuni" deb o'qiymiz.
        return date == null ? const DailyRepeat() : OnceRepeat(date);
      default:
        // Noma'lum tur kelsa ilova qulamasligi uchun — har kuni.
        return const DailyRepeat();
    }
  }

  static Map<String, dynamic> toJson(RepeatRule rule) => switch (rule) {
    DailyRepeat() => {'type': 'daily'},
    WeeklyRepeat(:final days) => {'type': 'weekly', 'days': days},
    IntervalRepeat(:final everyNDays) => {
      'type': 'interval',
      'every_n_days': everyNDays,
    },
    ProgramRepeat() => {'type': 'program'},
    OnceRepeat(:final date) => {'type': 'once', 'date': ApiDate.format(date)},
  };
}

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.title,
    required super.icon,
    required super.color,
    required super.type,
    required super.repeatRule,
    required super.order,
    required super.isArchived,
    required super.createdAt,
    super.groupId,
    super.description,
    super.goalValue,
    super.goalUnit,
    super.goalType,
    super.reminders,
    super.remindBeforeMinutes,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      title: json['title'] as String,
      icon: json['icon'] as String? ?? 'check',
      color: json['color'] as String? ?? '#6C7BF5',
      type: HabitType.fromJson(json['type'] as String?),
      description: json['description'] as String?,
      goalValue: (json['goal_value'] as num?)?.toDouble(),
      goalUnit: json['goal_unit'] as String?,
      goalType: GoalType.fromJson(json['goal_type'] as String?),
      repeatRule: RepeatRuleMapper.fromJson(
        json['repeat_rule'] as Map<String, dynamic>?,
      ),
      reminders:
          (json['reminders'] as List?)
              ?.map((e) => Reminder.parse((e as Map)['time'] as String))
              .toList() ??
          const [],
      remindBeforeMinutes: (json['remind_before_minutes'] as num?)?.toInt(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  /// `POST /habits` uchun. Server generatsiya qiladigan maydonlar yuborilmaydi.
  ///
  /// `goal_value` bo'lmasa `goal_unit`/`goal_type` ham yuborilmaydi — aks
  /// holda server `422` qaytaradi.
  static Map<String, dynamic> toCreateJson(Habit habit) {
    final hasGoal = habit.goalValue != null;

    return {
      'group_id': habit.groupId,
      'title': habit.title,
      'icon': habit.icon,
      'color': habit.color,
      'type': habit.type.json,
      'description': habit.description,
      'goal_value': habit.goalValue,
      if (hasGoal) 'goal_unit': habit.goalUnit,
      if (hasGoal) 'goal_type': (habit.goalType ?? GoalType.atLeast).json,
      'repeat_rule': RepeatRuleMapper.toJson(habit.repeatRule),
      'reminders': habit.reminders.map((r) => {'time': r.json}).toList(),
      'remind_before_minutes': ?habit.remindBeforeMinutes,
    };
  }

  /// `PATCH /habits/{id}` uchun — [original] va [edited] orasidagi farq.
  ///
  /// Faqat o'zgargan maydonlar yuboriladi: server `exclude_unset` bilan
  /// ishlaydi, shuning uchun yuborilmagan kalit "o'zgarmasin" degani, `null`
  /// esa "tozalansin" degani (`description`, `group_id`, `goal_value`).
  /// Maqsad tozalansa server `goal_unit` va `goal_type` ni ham o'zi tozalaydi.
  ///
  /// Dastur odatining `repeat_rule` i hech qachon yuborilmaydi — uni faqat
  /// server boshqaradi.
  static Map<String, dynamic> toChangesJson(Habit original, Habit edited) {
    final goalChanged =
        original.goalValue != edited.goalValue ||
        original.goalUnit != edited.goalUnit ||
        original.goalType != edited.goalType;
    final repeatChanged =
        original.repeatRule != edited.repeatRule &&
        edited.repeatRule is! ProgramRepeat &&
        original.repeatRule is! ProgramRepeat;

    return {
      if (original.title != edited.title) 'title': edited.title,
      if (original.icon != edited.icon) 'icon': edited.icon,
      if (original.color != edited.color) 'color': edited.color,
      if (original.type != edited.type) 'type': edited.type.json,
      if (original.description != edited.description)
        'description': edited.description,
      if (original.groupId != edited.groupId) 'group_id': edited.groupId,
      if (goalChanged) ...{
        'goal_value': edited.goalValue,
        if (edited.goalValue != null) ...{
          'goal_unit': edited.goalUnit,
          'goal_type': (edited.goalType ?? GoalType.atLeast).json,
        },
      },
      if (repeatChanged)
        'repeat_rule': RepeatRuleMapper.toJson(edited.repeatRule),
      if (!_sameReminders(original.reminders, edited.reminders))
        'reminders': edited.reminders.map((r) => {'time': r.json}).toList(),
      // `null` — standartga qaytarish, shuning uchun yuborilaveradi.
      if (original.remindBeforeMinutes != edited.remindBeforeMinutes)
        'remind_before_minutes': edited.remindBeforeMinutes,
    };
  }

  static bool _sameReminders(List<Reminder> a, List<Reminder> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Reorder so'rovi — body **massiv**, obyekt emas.
  static List<Map<String, dynamic>> toReorderJson(List<String> orderedIds) => [
    for (var i = 0; i < orderedIds.length; i++)
      {'id': orderedIds[i], 'order': i},
  ];

  static String formatDate(DateTime date) => ApiDate.format(date);

  /// `POST /habits/parse` javobi — saqlanmagan qoralama: `id` yo'q, qolgani
  /// `HabitCreate` bilan bir xil.
  factory HabitModel.fromDraftJson(Map<String, dynamic> json) =>
      HabitModel.fromJson({...json, 'id': ''});
}
