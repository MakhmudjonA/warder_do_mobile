import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../entities/daily_habit.dart';
import '../entities/habit.dart';
import '../entities/habit_template.dart';
import '../repositories/habits_repository.dart';

/// Odatlar bo'yicha use case'lar.
///
/// Ular bitta faylda turibdi, chunki har biri bir necha qatordan iborat va
/// hammasi bitta repository ustida ishlaydi — alohida fayllarga bo'lish
/// navigatsiyani osonlashtirmasdi.

/// Bosh ekranning yagona so'rovi: kunga tegishli odatlar + o'sha kungi loglar.
class GetDailyHabits implements UseCase<List<DailyHabit>, DailyHabitsParams> {
  const GetDailyHabits(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, List<DailyHabit>>> call(DailyHabitsParams params) {
    return _repository.getDailyHabits(
      date: params.date,
      all: params.all,
      includeArchived: params.includeArchived,
    );
  }
}

class DailyHabitsParams extends Equatable {
  const DailyHabitsParams({
    this.date,
    this.all = false,
    this.includeArchived = false,
  });

  /// `null` — server "bugun" ni foydalanuvchi timezone'ida o'zi hisoblaydi.
  final DateTime? date;

  /// Jadvalga qaramay barcha odatlar (boshqaruv ekrani uchun).
  final bool all;

  final bool includeArchived;

  @override
  List<Object?> get props => [date, all, includeArchived];
}

/// Kunlik progress qo'shish.
///
/// Diqqat: [LogHabitParams.value] — **qo'shiladigan** miqdor, jami emas.
class LogHabit implements UseCase<LogResult, LogHabitParams> {
  const LogHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, LogResult>> call(LogHabitParams params) {
    return _repository.logHabit(
      params.habitId,
      date: params.date,
      value: params.value,
      durationSeconds: params.durationSeconds,
      completed: params.completed,
    );
  }
}

class LogHabitParams extends Equatable {
  const LogHabitParams({
    required this.habitId,
    required this.date,
    this.value,
    this.durationSeconds,
    this.completed,
  });

  /// Checkbox odatni belgilash.
  factory LogHabitParams.complete({
    required String habitId,
    required DateTime date,
  }) => LogHabitParams(habitId: habitId, date: date, completed: true);

  /// Miqdor qo'shish ("+0,5 litr").
  factory LogHabitParams.addValue({
    required String habitId,
    required DateTime date,
    required double amount,
  }) => LogHabitParams(habitId: habitId, date: date, value: amount);

  /// Timer sessiyasini yozish.
  factory LogHabitParams.addDuration({
    required String habitId,
    required DateTime date,
    required int seconds,
  }) => LogHabitParams(habitId: habitId, date: date, durationSeconds: seconds);

  final String habitId;
  final DateTime date;
  final double? value;
  final int? durationSeconds;
  final bool? completed;

  @override
  List<Object?> get props => [habitId, date, value, durationSeconds, completed];
}

/// Belgini olib tashlash. Idempotent — bo'sh kunda ham xato bermaydi.
class UnlogHabit implements UseCase<Unit, UnlogHabitParams> {
  const UnlogHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UnlogHabitParams params) =>
      _repository.unlogHabit(params.habitId, params.date);
}

class UnlogHabitParams extends Equatable {
  const UnlogHabitParams({required this.habitId, required this.date});

  final String habitId;
  final DateTime date;

  @override
  List<Object?> get props => [habitId, date];
}

/// Yangi odat yaratish. Shablondan kelgan ma'lumot ham shu yerdan o'tadi.
class CreateHabit implements UseCase<Habit, Habit> {
  const CreateHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Habit>> call(Habit params) =>
      _repository.createHabit(params);
}

/// Mavjud odatni tahrirlash formasidan saqlash.
class UpdateHabit implements UseCase<Habit, UpdateHabitParams> {
  const UpdateHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Habit>> call(UpdateHabitParams params) =>
      _repository.editHabit(params.original, params.edited);
}

class UpdateHabitParams extends Equatable {
  const UpdateHabitParams({required this.original, required this.edited});

  /// Forma ochilgandagi holat — farqni hisoblash uchun.
  final Habit original;
  final Habit edited;

  @override
  List<Object?> get props => [original, edited];
}

/// AI tezkor qo'shish: matn → saqlanmagan odat qoralamasi.
class ParseHabitText implements UseCase<Habit, String> {
  const ParseHabitText(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Habit>> call(String params) =>
      _repository.parseHabit(params);
}

/// Tayyor odat shablonlari. Auth talab qilmaydi.
class GetHabitTemplates
    implements UseCase<List<HabitTemplate>, TemplateParams> {
  const GetHabitTemplates(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, List<HabitTemplate>>> call(TemplateParams params) =>
      _repository.getTemplates(category: params.category);
}

class TemplateParams extends Equatable {
  const TemplateParams([this.category]);

  /// `"good"`, `"health"`, `"bad"`, `"task"` yoki `null` (hammasi).
  final String? category;

  @override
  List<Object?> get props => [category];
}

/// Yangi tartibni saqlash. Body — massiv, `[{id, order}, ...]`.
class ReorderHabits implements UseCase<List<Habit>, List<String>> {
  const ReorderHabits(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, List<Habit>>> call(List<String> params) =>
      _repository.reorderHabits(params);
}

/// Odatni boshqa guruhga ko'chirish (yoki guruhdan chiqarish).
class MoveHabitToGroup implements UseCase<Habit, MoveHabitParams> {
  const MoveHabitToGroup(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Habit>> call(MoveHabitParams params) {
    // Faqat bitta maydon, `null` ham ma'noli ("guruhsiz") — shuning uchun
    // `editHabit` emas, to'g'ridan-to'g'ri map.
    return _repository.updateHabit(params.habitId, {
      'group_id': params.groupId,
    });
  }
}

class MoveHabitParams extends Equatable {
  const MoveHabitParams({required this.habitId, required this.groupId});

  final String habitId;

  /// `null` — guruhdan chiqariladi.
  final String? groupId;

  @override
  List<Object?> get props => [habitId, groupId];
}

/// **Butunlay** o'chiradi — odat va uning tarixi. Qaytarib bo'lmaydi.
class DeleteHabit implements UseCase<Unit, String> {
  const DeleteHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteHabit(params);
}

/// O'chirishga muqobil: ro'yxatdan yo'qoladi, tarix saqlanadi.
class ArchiveHabit implements UseCase<Habit, String> {
  const ArchiveHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Habit>> call(String params) =>
      _repository.archiveHabit(params);
}
