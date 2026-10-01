import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/error/failures.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/achievement.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/daily_habit.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit_log.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit_template.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/repeat_rule.dart';
import 'package:warder_do_mobile/features/habits/domain/repositories/habits_repository.dart';
import 'package:warder_do_mobile/features/habits/domain/usecases/habit_usecases.dart';
import 'package:warder_do_mobile/features/habits/presentation/bloc/habits_bloc.dart';

final tDate = DateTime(2026, 9, 3);

Habit habit({
  String id = 'h1',
  double? goalValue,
  String? goalUnit,
  GoalType? goalType,
}) {
  return Habit(
    id: id,
    title: 'Suv ichish',
    icon: 'water_drop',
    color: '#4FA8E8',
    type: HabitType.good,
    repeatRule: const DailyRepeat(),
    order: 0,
    isArchived: false,
    createdAt: DateTime(2026, 1, 1),
    goalValue: goalValue,
    goalUnit: goalUnit,
    goalType: goalType,
  );
}

DailyHabit daily({Habit? h, HabitLog? log}) =>
    DailyHabit(habit: h ?? habit(), date: tDate, log: log);

HabitLog serverLog({double? value, bool completed = true}) => HabitLog(
  id: 'log-1',
  habitId: 'h1',
  date: tDate,
  value: value,
  completed: completed,
);

/// Sozlanadigan soxta repository — mocktail o'rniga qo'lda yozilgan.
class FakeHabitsRepository implements HabitsRepository {
  List<DailyHabit> habits = [daily()];
  Either<Failure, List<DailyHabit>>? listOverride;

  Either<Failure, LogResult>? logResult;
  Either<Failure, Unit> unlogResult = const Right(unit);

  /// Oxirgi `logHabit` chaqiruvining argumentlari.
  double? lastValue;
  bool? lastCompleted;
  int logCalls = 0;
  int listCalls = 0;
  int unlogCalls = 0;

  /// Oxirgi `editHabit` chaqiruvi.
  Habit? lastEdited;
  Either<Failure, Habit>? editResult;

  @override
  Future<Either<Failure, List<DailyHabit>>> getDailyHabits({
    DateTime? date,
    bool all = false,
    bool includeArchived = false,
  }) async {
    listCalls++;
    return listOverride ?? Right(habits);
  }

  @override
  Future<Either<Failure, LogResult>> logHabit(
    String habitId, {
    required DateTime date,
    double? value,
    int? durationSeconds,
    bool? completed,
  }) async {
    logCalls++;
    lastValue = value;
    lastCompleted = completed;
    return logResult ??
        Right(
          LogResult(
            log: serverLog(value: value),
            newlyUnlocked: const [],
          ),
        );
  }

  @override
  Future<Either<Failure, Habit>> parseHabit(String text) async =>
      Right(habit(id: ''));

  @override
  Future<Either<Failure, Habit>> editHabit(Habit original, Habit edited) async {
    lastEdited = edited;
    return editResult ?? Right(edited);
  }

  @override
  Future<Either<Failure, Unit>> unlogHabit(
    String habitId,
    DateTime date,
  ) async {
    unlogCalls++;
    return unlogResult;
  }

  // --- Bu testlarda ishlatilmaydigan metodlar ---
  @override
  Future<Either<Failure, Habit>> archiveHabit(String id) async =>
      Right(habit());
  @override
  Future<Either<Failure, Habit>> createHabit(Habit h) async => Right(h);
  @override
  Future<Either<Failure, Unit>> deleteHabit(String id) async =>
      const Right(unit);
  @override
  Future<Either<Failure, Habit>> getHabit(String id) async => Right(habit());
  @override
  Future<Either<Failure, List<HabitLog>>> getLogs(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) async => const Right([]);
  @override
  Future<Either<Failure, StreakInfo>> getStreak(String habitId) async =>
      const Right(StreakInfo.empty);
  @override
  Future<Either<Failure, List<HabitTemplate>>> getTemplates({
    String? category,
  }) async => const Right([]);
  @override
  Future<Either<Failure, List<Habit>>> reorderHabits(
    List<String> orderedIds,
  ) async => const Right([]);
  @override
  Future<Either<Failure, Habit>> unarchiveHabit(String id) async =>
      Right(habit());
  @override
  Future<Either<Failure, Habit>> updateHabit(
    String id,
    Map<String, dynamic> changes,
  ) async => Right(habit());
}

void main() {
  late FakeHabitsRepository repository;
  late HabitsBloc bloc;

  setUp(() {
    repository = FakeHabitsRepository();
    bloc = HabitsBloc(
      getDailyHabits: GetDailyHabits(repository),
      logHabit: LogHabit(repository),
      unlogHabit: UnlogHabit(repository),
      createHabit: CreateHabit(repository),
      updateHabit: UpdateHabit(repository),
    );
  });

  tearDown(() => bloc.close());

  group('HabitsRequested', () {
    test('muvaffaqiyatli yuklash ready holatga o‘tadi', () async {
      bloc.add(const HabitsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) => s.status == HabitsStatus.ready && s.habits.length == 1,
          ),
        ),
      );
    });

    test('xatolikda failure holati va xabar', () async {
      repository.listOverride = const Left(NetworkFailure());
      bloc.add(const HabitsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) =>
                s.status == HabitsStatus.failure && s.failure is NetworkFailure,
          ),
        ),
      );
    });

    test('silent yangilashda eski ro‘yxat saqlanadi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      repository.listOverride = const Left(NetworkFailure());
      bloc.add(const HabitsRequested(silent: true));

      await expectLater(
        bloc.stream,
        emitsThrough(
          // Ro'yxat joyida qoladi, faqat snackbar uchun xabar chiqadi.
          predicate<HabitsState>(
            (s) => s.habits.length == 1 && s.notice != null,
          ),
        ),
      );
    });
  });

  group('HabitToggled — optimistik yangilash', () {
    test('UI serverdan oldin belgilanadi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitToggled('h1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          // 1-emit: hali so'rov ketmagan, lekin UI allaqachon bajarilgan.
          predicate<HabitsState>(
            (s) => s.habits.first.isCompleted && s.isPending('h1'),
          ),
          // 2-emit: server javobi keldi, pending tugadi.
          predicate<HabitsState>(
            (s) => s.habits.first.isCompleted && !s.isPending('h1'),
          ),
        ]),
      );
    });

    test('xatolikda avvalgi holat qaytariladi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      repository.logResult = const Left(NetworkFailure());
      bloc.add(const HabitToggled('h1'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) =>
                !s.habits.first.isCompleted &&
                !s.isPending('h1') &&
                s.notice != null,
          ),
        ),
      );
    });

    test('bajarilgan odat bosilsa unlog chaqiriladi', () async {
      repository.habits = [daily(log: serverLog(completed: true))];
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitToggled('h1'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>((s) => !s.habits.first.isCompleted),
        ),
      );
      expect(repository.unlogCalls, 1);
      expect(repository.logCalls, 0);
    });

    test('maqsadli odatda qolgan miqdor yuboriladi', () async {
      repository.habits = [
        daily(
          h: habit(goalValue: 2, goalUnit: 'liter', goalType: GoalType.atLeast),
          log: serverLog(value: 1.2, completed: false),
        ),
      ];
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitToggled('h1'));
      await bloc.stream.firstWhere((s) => !s.isPending('h1'));

      // 2 - 1.2 = 0.8 — jami emas, **qo'shiladigan** miqdor.
      expect(repository.lastValue, closeTo(0.8, 0.0001));
      expect(repository.lastCompleted, isTrue);
    });
  });

  group('HabitValueAdded', () {
    test('qo‘shiladigan miqdor yuboriladi, jami emas', () async {
      repository.habits = [
        daily(
          h: habit(goalValue: 2, goalUnit: 'liter', goalType: GoalType.atLeast),
          log: serverLog(value: 1, completed: false),
        ),
      ];
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitValueAdded(habitId: 'h1', amount: 0.5));
      await bloc.stream.firstWhere((s) => !s.isPending('h1'));

      expect(repository.lastValue, 0.5);
    });

    test('maqsadga yetganda optimistik ravishda completed bo‘ladi', () async {
      repository.habits = [
        daily(
          h: habit(goalValue: 2, goalUnit: 'liter', goalType: GoalType.atLeast),
          log: serverLog(value: 1.8, completed: false),
        ),
      ];
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitValueAdded(habitId: 'h1', amount: 0.5));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) => s.habits.first.isCompleted && s.isPending('h1'),
          ),
        ),
      );
    });
  });

  group('yutuqlar', () {
    test('newly_unlocked bo‘sh bo‘lmasa unlockId oshadi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      repository.logResult = Right(
        LogResult(
          log: serverLog(),
          newlyUnlocked: const [
            Achievement(
              type: 'streak_7',
              title: 'One week',
              description: '7 day streak',
              category: 'streak',
              threshold: 7,
              progress: 7,
              progressPercent: 100,
              unlocked: true,
            ),
          ],
        ),
      );

      bloc.add(const HabitToggled('h1'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) => s.unlockId == 1 && s.newlyUnlocked.length == 1,
          ),
        ),
      );
    });
  });

  group('takroriy bosish', () {
    test('so‘rov ketayotganda ikkinchi bosish e’tiborga olinmaydi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(const HabitToggled('h1'));
      bloc.add(const HabitToggled('h1'));

      await bloc.stream.firstWhere((s) => !s.isPending('h1'));
      await Future<void>.delayed(Duration.zero);

      // Ikkinchi bosish pending tufayli tashlab yuborilgan.
      expect(repository.logCalls, 1);
    });
  });

  group('HabitCreateSubmitted', () {
    test('yaratilgandan keyin ro‘yxat qayta so‘raladi', () async {
      bloc.add(const HabitsRequested());
      await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

      bloc.add(HabitCreateSubmitted(habit(id: '')));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) => !s.isSubmitting && s.createdHabit != null,
          ),
        ),
      );
      // Yangi odat bugungi jadvalga tushishi mumkin — ro'yxat yangilanadi.
      expect(repository.listCalls, greaterThanOrEqualTo(2));
    });
  });

  group('HabitUpdateSubmitted', () {
    test(
      'saqlangandan keyin updatedHabit qo‘yiladi va ro‘yxat yangilanadi',
      () async {
        bloc.add(const HabitsRequested());
        await bloc.stream.firstWhere((s) => s.status == HabitsStatus.ready);

        final original = habit();
        final edited = original.copyWith(title: 'Ko‘proq suv');
        bloc.add(HabitUpdateSubmitted(original: original, edited: edited));

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<HabitsState>(
              (s) => !s.isSubmitting && s.updatedHabit?.title == 'Ko‘proq suv',
            ),
          ),
        );
        expect(repository.lastEdited, edited);
        expect(repository.listCalls, greaterThanOrEqualTo(2));
      },
    );

    test('xatolikda forma uchun failure qo‘yiladi', () async {
      repository.editResult = const Left(ValidationFailure());

      bloc.add(HabitUpdateSubmitted(original: habit(), edited: habit()));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<HabitsState>(
            (s) =>
                !s.isSubmitting &&
                s.failure is ValidationFailure &&
                s.updatedHabit == null,
          ),
        ),
      );
    });
  });
}
