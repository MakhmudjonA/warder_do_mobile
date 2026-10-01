import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/daily_habit.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/entities/habit_template.dart';
import '../../domain/repositories/habits_repository.dart';
import '../datasources/habits_remote_data_source.dart';
import '../models/habit_model.dart';

/// Offline rejim yo'q — har bir amal to'g'ridan-to'g'ri serverga boradi.
/// Repository'ning yagona vazifasi: exception'ni [Failure] ga aylantirish.
class HabitsRepositoryImpl implements HabitsRepository {
  const HabitsRepositoryImpl(this._remote);

  final HabitsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<DailyHabit>>> getDailyHabits({
    DateTime? date,
    bool all = false,
    bool includeArchived = false,
  }) {
    return guardApi(
      () => _remote.getHabits(
        date: date,
        all: all,
        includeArchived: includeArchived,
      ),
    );
  }

  @override
  Future<Either<Failure, Habit>> getHabit(String id) =>
      guardApi(() => _remote.getHabit(id));

  @override
  Future<Either<Failure, Habit>> createHabit(Habit habit) =>
      guardApi(() => _remote.createHabit(habit));

  @override
  Future<Either<Failure, Habit>> updateHabit(
    String id,
    Map<String, dynamic> changes,
  ) => guardApi(() => _remote.updateHabit(id, changes));

  @override
  Future<Either<Failure, Habit>> parseHabit(String text) =>
      guardApi(() => _remote.parseHabit(text));

  @override
  Future<Either<Failure, Habit>> editHabit(Habit original, Habit edited) {
    final changes = HabitModel.toChangesJson(original, edited);
    if (changes.isEmpty) return Future.value(Right(original));
    return updateHabit(original.id, changes);
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String id) => guardApi(() async {
    await _remote.deleteHabit(id);
    return unit;
  });

  @override
  Future<Either<Failure, Habit>> archiveHabit(String id) =>
      guardApi(() => _remote.archiveHabit(id));

  @override
  Future<Either<Failure, Habit>> unarchiveHabit(String id) =>
      guardApi(() => _remote.unarchiveHabit(id));

  @override
  Future<Either<Failure, List<Habit>>> reorderHabits(List<String> orderedIds) =>
      guardApi(() => _remote.reorderHabits(orderedIds));

  @override
  Future<Either<Failure, LogResult>> logHabit(
    String habitId, {
    required DateTime date,
    double? value,
    int? durationSeconds,
    bool? completed,
  }) {
    return guardApi(
      () => _remote.logHabit(
        habitId,
        date: date,
        value: value,
        durationSeconds: durationSeconds,
        completed: completed,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> unlogHabit(String habitId, DateTime date) =>
      guardApi(() async {
        await _remote.unlogHabit(habitId, date);
        return unit;
      });

  @override
  Future<Either<Failure, List<HabitLog>>> getLogs(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) => guardApi(() => _remote.getLogs(habitId, from: from, to: to));

  @override
  Future<Either<Failure, StreakInfo>> getStreak(String habitId) =>
      guardApi(() => _remote.getStreak(habitId));

  @override
  Future<Either<Failure, List<HabitTemplate>>> getTemplates({
    String? category,
  }) => guardApi(() => _remote.getTemplates(category: category));
}
