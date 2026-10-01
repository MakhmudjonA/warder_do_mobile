import 'package:equatable/equatable.dart';

import 'repeat_rule.dart';

/// Odat turi.
enum HabitType {
  /// Bajarilishi kerak bo'lgan foydali odat.
  good,

  /// Tark etilishi kerak bo'lgan odat.
  bad,

  /// Bir martalik vazifa.
  task;

  static HabitType fromJson(String? value) => switch (value) {
    'bad' => HabitType.bad,
    'task' => HabitType.task,
    _ => HabitType.good,
  };

  String get json => name;
}

/// Maqsad qanday hisoblanishi.
enum GoalType {
  /// Kamida shuncha (suv, sahifa, daqiqa).
  atLeast,

  /// Ko'pi bilan shuncha (sigaret, kofe).
  atMost,

  /// Aynan shuncha.
  exact;

  static GoalType? fromJson(String? value) => switch (value) {
    'at_least' => GoalType.atLeast,
    'at_most' => GoalType.atMost,
    'exact' => GoalType.exact,
    _ => null,
  };

  String get json => switch (this) {
    GoalType.atLeast => 'at_least',
    GoalType.atMost => 'at_most',
    GoalType.exact => 'exact',
  };
}

/// Bitta eslatma vaqti. Server faqat vaqtni saqlaydi —
/// bildirishnomani ilova o'zi rejalashtiradi.
class Reminder extends Equatable {
  const Reminder({required this.hour, required this.minute});

  factory Reminder.parse(String value) {
    final parts = value.split(':');
    return Reminder(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  final int hour;
  final int minute;

  /// Backend faqat `"HH:MM"` qabul qiladi.
  String get json =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [hour, minute];
}

/// Odat — domain qatlamining asosiy obyekti.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    required this.repeatRule,
    required this.order,
    required this.isArchived,
    required this.createdAt,
    this.groupId,
    this.description,
    this.goalValue,
    this.goalUnit,
    this.goalType,
    this.reminders = const [],
    this.remindBeforeMinutes,
  });

  final String id;

  /// `null` — guruhsiz. Bosh ekranda bunday odatlar alohida ajratilmaydi.
  final String? groupId;

  final String title;

  /// Icon kaliti (`"water_drop"`). Ma'nosini faqat ilova biladi.
  final String icon;

  /// Hex rang (`"#4FC3F7"`).
  final String color;

  final HabitType type;
  final String? description;

  /// `null` bo'lsa — oddiy checkbox odat, miqdor yo'q.
  final double? goalValue;

  /// Erkin matn: `"liter"`, `"minute"`, `"page"`.
  final String? goalUnit;

  final GoalType? goalType;
  final RepeatRule repeatRule;
  final List<Reminder> reminders;

  /// Eslatmadan shuncha daqiqa oldin qo'shimcha ogohlantirish (Telegram).
  /// `null` — standart: vazifalar uchun 10 daqiqa, odatlar uchun yo'q;
  /// `0` — umuman yo'q.
  final int? remindBeforeMinutes;
  final int order;

  /// Arxivlangan odat kunlik ro'yxatda ko'rinmaydi, lekin tarixi saqlanadi.
  final bool isArchived;

  final DateTime createdAt;

  /// Bir martalik ish ("к врачу"), odat emas.
  bool get isTask => type == HabitType.task;

  /// Eng erta eslatma — vazifaning "vaqti".
  Reminder? get firstReminder {
    if (reminders.isEmpty) return null;
    return ([...reminders]..sort((a, b) => a.json.compareTo(b.json))).first;
  }

  /// Miqdorli odatmi (progress ring kerakmi) yoki oddiy checkboxmi.
  bool get hasGoal => goalValue != null && goalValue! > 0;

  /// Vaqt birligidagi maqsad — sekundlar bilan ishlanadi (timer odati).
  ///
  /// Server `duration_seconds` ni shu birlikka o'zi o'giradi.
  bool get isTimed => const {
    'minute',
    'minutes',
    'hour',
    'hours',
    'second',
    'seconds',
  }.contains(goalUnit?.toLowerCase());

  Habit copyWith({
    String? id,
    String? groupId,
    String? title,
    String? icon,
    String? color,
    HabitType? type,
    String? description,
    double? goalValue,
    String? goalUnit,
    GoalType? goalType,
    RepeatRule? repeatRule,
    List<Reminder>? reminders,
    int? remindBeforeMinutes,
    int? order,
    bool? isArchived,
    DateTime? createdAt,
    bool clearGroup = false,
    bool clearGoal = false,
  }) {
    return Habit(
      id: id ?? this.id,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      description: description ?? this.description,
      // `goal_value` tozalansa, backend `unit` va `type` ni ham tozalaydi —
      // shu xatti-harakatni bu yerda ham takrorlaymiz.
      goalValue: clearGoal ? null : (goalValue ?? this.goalValue),
      goalUnit: clearGoal ? null : (goalUnit ?? this.goalUnit),
      goalType: clearGoal ? null : (goalType ?? this.goalType),
      repeatRule: repeatRule ?? this.repeatRule,
      reminders: reminders ?? this.reminders,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
      order: order ?? this.order,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    icon,
    color,
    type,
    description,
    goalValue,
    goalUnit,
    goalType,
    repeatRule,
    reminders,
    remindBeforeMinutes,
    order,
    isArchived,
    createdAt,
  ];
}
