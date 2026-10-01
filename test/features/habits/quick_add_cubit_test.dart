import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/error/failures.dart';
import 'package:warder_do_mobile/features/habits/domain/entities/habit.dart';
import 'package:warder_do_mobile/features/habits/domain/usecases/habit_usecases.dart';
import 'package:warder_do_mobile/features/habits/presentation/bloc/quick_add_cubit.dart';

import 'habits_bloc_test.dart' show FakeHabitsRepository, habit;

class _Repo extends FakeHabitsRepository {
  Either<Failure, Habit> result = Right(habit(id: ''));
  String? lastText;

  @override
  Future<Either<Failure, Habit>> parseHabit(String text) async {
    lastText = text;
    return result;
  }
}

void main() {
  late _Repo repository;
  late QuickAddCubit cubit;

  setUp(() {
    repository = _Repo();
    cubit = QuickAddCubit(ParseHabitText(repository));
  });

  tearDown(() => cubit.close());

  test('matn qoralamaga aylanadi', () async {
    await cubit.submit('  завтра в 15:00 к врачу  ');

    expect(cubit.state.status, QuickAddStatus.success);
    expect(cubit.state.draft, isNotNull);
    expect(repository.lastText, 'завтра в 15:00 к врачу');
  });

  test('xato — failure bilan', () async {
    repository.result = const Left(ServerFailure());
    await cubit.submit('к врачу');

    expect(cubit.state.status, QuickAddStatus.failure);
    expect(cubit.state.failure, isA<ServerFailure>());
  });

  test('bo‘sh matn serverga ketmaydi', () async {
    await cubit.submit(' ');

    expect(cubit.state.status, QuickAddStatus.idle);
    expect(repository.lastText, isNull);
  });
}
