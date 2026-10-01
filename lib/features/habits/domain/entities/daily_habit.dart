import 'package:equatable/equatable.dart';

import '../../../programs/domain/entities/program.dart';
import 'habit.dart';
import 'habit_log.dart';
import '../../../../core/constants/goal_units.dart';

/// `GET /habits?date=...` javobining bitta elementi: odat + **o'sha kungi** log.
///
/// Bosh ekran uchun bitta so'rov yetarli bo'lishining sababi shu — server
/// jadval bo'yicha filtrlab, har biriga kunlik holatni qo'shib beradi.
class DailyHabit extends Equatable {
  const DailyHabit({
    required this.habit,
    required this.date,
    this.log,
    this.programDay,
  });

  final Habit habit;
  final DateTime date;

  /// `null` — bu kuni hali hech nima qilinmagan.
  final HabitLog? log;

  /// Dastur (mashq) odati bo'lsa — shu kunga tegishli yuklama va izoh.
  /// `repeat_rule.type == "program"` odatlarida server qo'shib yuboradi;
  /// oddiy odatlarda `null`.
  final ProgramDay? programDay;

  bool get isCompleted => log?.completed ?? false;

  /// To'plangan miqdor. Timer odatlarida server sekundlarni `goal_unit` ga
  /// o'girib `value` ga yozadi, shuning uchun avval `value` ga qaraymiz.
  double get currentValue =>
      log?.value ?? (log?.durationSeconds?.toDouble() ?? 0);

  /// 0.0 – 1.0 oralig'ida. Progress ring uchun.
  double get progress {
    if (isCompleted) return 1;
    final goal = habit.goalValue;
    if (goal == null || goal <= 0) return 0;
    return (currentValue / goal).clamp(0.0, 1.0);
  }

  /// Kartada ko'rinadigan pastki satr: "Har kuni, 1,2/2 litr".
  String get progressLabel {
    final goal = habit.goalValue;
    if (goal == null) return '';

    final unit = GoalUnits.label(habit.goalUnit);
    final current = _formatNumber(currentValue);
    final target = _formatNumber(goal);
    return '$current/$target $unit'.trim();
  }

  /// Optimistik yangilash uchun: serverga bormasdan lokal holatni o'zgartirish.
  DailyHabit copyWithLog(HabitLog? newLog) =>
      DailyHabit(habit: habit, date: date, log: newLog, programDay: programDay);

  static String _formatNumber(double value) {
    // Butun son bo'lsa kasr qismini ko'rsatmaymiz: "2" — "2.0" emas.
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  List<Object?> get props => [habit, date, log, programDay];
}
