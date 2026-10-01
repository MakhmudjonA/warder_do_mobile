import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/error/failures.dart';
import 'package:warder_do_mobile/features/groups/domain/entities/group.dart';
import 'package:warder_do_mobile/features/groups/domain/repositories/groups_repository.dart';
import 'package:warder_do_mobile/features/groups/domain/usecases/group_usecases.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/achievement.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/daily_habit.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit_log.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit_template.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/repeat_rule.dart';
import 'package:warder_do_mobile/features/habits/domain/repositories/habits_repository.dart';
import 'package:warder_do_mobile/features/habits/domain/usecases/habit_usecases.dart';
import 'package:warder_do_mobile/features/habits/presentation/bloc/organizer_bloc.dart';

Habit habit(String id, {String? groupId, int order = 0}) => Habit(
  id: id,
  groupId: groupId,
  title: 'Привычка $id',
  icon: 'check',
  color: '#6C7BF5',
  type: HabitType.good,
  repeatRule: const DailyRepeat(),
  order: order,
  isArchived: false,
  createdAt: DateTime(2026, 1, 1),
);

Group group(String id, {int order = 0}) => Group(
  id: id,
  name: 'Группа $id',
  icon: 'folder',
  color: '#F5A64F',
  order: order,
);

class FakeHabitsRepository implements HabitsRepository {
  List<Habit> habits = [];

  /// Что реально ушло на сервер.
  List<String>? reorderedIds;
  final List<(String habitId, String? groupId)> moves = [];
  final List<String> deleted = [];
  final List<String> archived = [];

  @override
  Future<Either<Failure, List<DailyHabit>>> getDailyHabits({
    DateTime? date,
    bool all = false,
    bool includeArchived = false,
  }) async => Right([
    for (final h in habits) DailyHabit(habit: h, date: DateTime(2026, 9, 3)),
  ]);

  @override
  Future<Either<Failure, List<Habit>>> reorderHabits(
    List<String> orderedIds,
  ) async {
    reorderedIds = orderedIds;
    return Right(habits);
  }

  @override
  Future<Either<Failure, Habit>> updateHabit(
    String id,
    Map<String, dynamic> changes,
  ) async {
    moves.add((id, changes['group_id'] as String?));
    return Right(habit(id));
  }

  @override
  Future<Either<Failure, Habit>> parseHabit(String text) async =>
      Right(habit(''));

  @override
  Future<Either<Failure, Habit>> editHabit(
    Habit original,
    Habit edited,
  ) async => Right(edited);

  @override
  Future<Either<Failure, Unit>> deleteHabit(String id) async {
    deleted.add(id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Habit>> archiveHabit(String id) async {
    archived.add(id);
    return Right(habit(id));
  }

  // --- В этих тестах не используется ---
  @override
  Future<Either<Failure, Habit>> createHabit(Habit h) async => Right(h);
  @override
  Future<Either<Failure, Habit>> getHabit(String id) async => Right(habit(id));
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
  Future<Either<Failure, LogResult>> logHabit(
    String habitId, {
    required DateTime date,
    double? value,
    int? durationSeconds,
    bool? completed,
  }) async => throw UnimplementedError();
  @override
  Future<Either<Failure, Unit>> unlogHabit(
    String habitId,
    DateTime date,
  ) async => const Right(unit);
  @override
  Future<Either<Failure, Habit>> unarchiveHabit(String id) async =>
      Right(habit(id));
}

class FakeGroupsRepository implements GroupsRepository {
  List<Group> groups = [];
  List<String>? reorderedIds;
  final List<String> deleted = [];

  @override
  Future<Either<Failure, List<Group>>> getGroups() async => Right(groups);

  @override
  Future<Either<Failure, List<Group>>> reorderGroups(
    List<String> orderedIds,
  ) async {
    reorderedIds = orderedIds;
    return Right(groups);
  }

  @override
  Future<Either<Failure, Unit>> deleteGroup(String id) async {
    deleted.add(id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Group>> createGroup({
    required String name,
    required String icon,
    required String color,
  }) async => Right(group('new'));

  @override
  Future<Either<Failure, Group>> updateGroup(
    String id, {
    String? name,
    String? icon,
    String? color,
    int? order,
  }) async => Right(group(id));
}

void main() {
  late FakeHabitsRepository habitsRepo;
  late FakeGroupsRepository groupsRepo;
  late OrganizerBloc bloc;

  setUp(() {
    habitsRepo = FakeHabitsRepository()
      ..habits = [
        habit('h1', groupId: 'g1'),
        habit('h2', groupId: 'g1', order: 1),
        habit('h3', order: 2),
      ];
    groupsRepo = FakeGroupsRepository()..groups = [group('g1'), group('g2')];

    bloc = OrganizerBloc(
      getDailyHabits: GetDailyHabits(habitsRepo),
      getGroups: GetGroups(groupsRepo),
      reorderHabits: ReorderHabits(habitsRepo),
      reorderGroups: ReorderGroups(groupsRepo),
      moveHabitToGroup: MoveHabitToGroup(habitsRepo),
      deleteHabit: DeleteHabit(habitsRepo),
      archiveHabit: ArchiveHabit(habitsRepo),
      deleteGroup: DeleteGroup(groupsRepo),
    );
  });

  tearDown(() => bloc.close());

  Future<OrganizerState> loaded() async {
    bloc.add(const OrganizerRequested());
    return bloc.stream.firstWhere((s) => s.status == OrganizerStatus.ready);
  }

  test('загружает все привычки и группы', () async {
    final state = await loaded();

    expect(state.habits.length, 3);
    expect(state.groups.length, 2);
    expect(state.habitsOf('g1').length, 2);
    expect(state.ungrouped.length, 1);
    expect(state.isDirty, isFalse);
  });

  test('перестановка помечает состояние как изменённое', () async {
    final state = await loaded();

    bloc.add(
      OrganizerArrangementChanged(
        habits: state.habits.reversed.toList(),
        groups: state.groups,
      ),
    );

    final next = await bloc.stream.firstWhere((s) => s.isDirty);
    expect(next.habits.first.id, 'h3');
  });

  test('сохранение шлёт смену группы и новый порядок', () async {
    final state = await loaded();

    // h3 переносим в g1 и ставим первым.
    final moved = state.habits[2].copyWith(groupId: 'g1');
    bloc.add(
      OrganizerArrangementChanged(
        habits: [moved, state.habits[0], state.habits[1]],
        groups: state.groups,
      ),
    );
    await bloc.stream.firstWhere((s) => s.isDirty);

    bloc.add(const OrganizerSaved());
    await bloc.stream.firstWhere((s) => s.isSaved);

    // Группа поменялась только у h3 — лишних PATCH быть не должно.
    expect(habitsRepo.moves, [('h3', 'g1')]);
    expect(habitsRepo.reorderedIds, ['h3', 'h1', 'h2']);
    // Порядок групп не трогали — запроса нет.
    expect(groupsRepo.reorderedIds, isNull);
  });

  test('порядок групп сохраняется отдельно', () async {
    final state = await loaded();

    bloc.add(
      OrganizerArrangementChanged(
        habits: state.habits,
        groups: state.groups.reversed.toList(),
      ),
    );
    await bloc.stream.firstWhere((s) => s.isDirty);

    bloc.add(const OrganizerSaved());
    await bloc.stream.firstWhere((s) => s.isSaved);

    expect(groupsRepo.reorderedIds, ['g2', 'g1']);
    expect(habitsRepo.moves, isEmpty);
  });

  test('удаление группы оставляет привычки без группы', () async {
    await loaded();

    bloc.add(const OrganizerGroupDeleted('g1'));
    final next = await bloc.stream.firstWhere((s) => !s.isSubmitting);

    expect(groupsRepo.deleted, ['g1']);
    expect(next.groups.map((g) => g.id), ['g2']);
    // Сервер привычки не удаляет — они просто теряют группу.
    expect(next.habits.length, 3);
    expect(next.ungrouped.length, 3);
  });

  test('архивирование убирает привычку из списка', () async {
    await loaded();

    bloc.add(const OrganizerHabitArchived('h1'));
    final next = await bloc.stream.firstWhere((s) => !s.isSubmitting);

    expect(habitsRepo.archived, ['h1']);
    expect(next.habits.map((h) => h.id), ['h2', 'h3']);
  });

  test('ошибка сохранения показывает сообщение и не закрывает экран', () async {
    final failingGroups = _FailingGroupsRepository();
    final failingBloc = OrganizerBloc(
      getDailyHabits: GetDailyHabits(habitsRepo),
      getGroups: GetGroups(failingGroups),
      reorderHabits: ReorderHabits(habitsRepo),
      reorderGroups: ReorderGroups(failingGroups),
      moveHabitToGroup: MoveHabitToGroup(habitsRepo),
      deleteHabit: DeleteHabit(habitsRepo),
      archiveHabit: ArchiveHabit(habitsRepo),
      deleteGroup: DeleteGroup(failingGroups),
    );
    addTearDown(failingBloc.close);

    failingBloc.add(const OrganizerRequested());

    final state = await failingBloc.stream.firstWhere(
      (s) => s.status == OrganizerStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
  });
}

class _FailingGroupsRepository extends FakeGroupsRepository {
  @override
  Future<Either<Failure, List<Group>>> getGroups() async =>
      const Left(NetworkFailure());
}
