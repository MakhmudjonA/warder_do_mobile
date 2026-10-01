import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/api_date.dart';
import '../../../habits/domain/usecases/habit_usecases.dart';
import '../../domain/entities/stats_entities.dart';
import '../../domain/usecases/stats_usecases.dart';

part 'stats_event.dart';
part 'stats_state.dart';

/// Statistika ekrani: kalendar, rekordlar va haftalik jadval.
///
/// Har blok mustaqil yangilanadi — oy surilganda faqat kalendar, davr
/// o'zgarganda faqat rekordlar so'raladi. Shuning uchun har biriga alohida
/// `...Loading` bayrog'i.
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({
    required GetStatsCalendar getCalendar,
    required GetStatsRecords getRecords,
    required GetStatsWeekly getWeekly,
    required GetDailyHabits getDailyHabits,
  }) : _getCalendar = getCalendar,
       _getRecords = getRecords,
       _getWeekly = getWeekly,
       _getDailyHabits = getDailyHabits,
       super(StatsState()) {
    on<StatsStarted>(_onStarted);
    on<StatsRefreshed>(_onStarted);
    on<StatsHabitFilterChanged>(_onHabitChanged);
    on<StatsMonthStepped>(_onMonthStepped);
    on<StatsPeriodChanged>(_onPeriodChanged);
    on<StatsWeekStepped>(_onWeekStepped);
  }

  final GetStatsCalendar _getCalendar;
  final GetStatsRecords _getRecords;
  final GetStatsWeekly _getWeekly;
  final GetDailyHabits _getDailyHabits;

  Future<void> _onStarted(StatsEvent event, Emitter<StatsState> emit) async {
    emit(state.copyWith(status: StatsStatus.loading, clearFailure: true));

    // Tanlagich uchun barcha odatlar (jadvalga qaramay).
    final habitsRes = await _getDailyHabits(const DailyHabitsParams(all: true));
    final habits = habitsRes.fold(
      (_) => const <HabitOption>[],
      (list) => list
          .map(
            (d) => HabitOption(
              id: d.habit.id,
              title: d.habit.title,
              icon: d.habit.icon,
              color: d.habit.color,
            ),
          )
          .toList(),
    );

    // Uchala so'rov parallel ketadi, emit esa ketma-ket (poyga bo'lmasligi uchun).
    final grid = _monthGridRange(state.month);
    final period = _periodRange(state.period);
    final week = _weekRange(state.weekStart);

    final calFut = _getCalendar(
      StatsRangeParams(
        from: grid.$1,
        to: grid.$2,
        habitId: state.selectedHabitId,
      ),
    );
    final recFut = _getRecords(
      StatsRangeParams(
        from: period.$1,
        to: period.$2,
        habitId: state.selectedHabitId,
      ),
    );
    final weekFut = _getWeekly(StatsRangeParams(from: week.$1, to: week.$2));

    final calRes = await calFut;
    final recRes = await recFut;
    final weekRes = await weekFut;

    // Kalendar — asosiy blok: u yiqilsa butun ekranni xato deb ko'rsatamiz.
    final failure = calRes.fold((f) => f, (_) => null);

    emit(
      state.copyWith(
        status: failure != null ? StatsStatus.failure : StatsStatus.ready,
        habits: habits,
        calendar: calRes.fold((_) => const <CalendarDay>[], (v) => v),
        records: recRes.fold((_) => state.records, (v) => v),
        weekly: weekRes.fold((_) => state.weekly, (v) => v),
        failure: failure,
        calendarLoading: false,
        recordsLoading: false,
        weeklyLoading: false,
      ),
    );
  }

  Future<void> _onHabitChanged(
    StatsHabitFilterChanged event,
    Emitter<StatsState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedHabitId: event.habitId,
        clearHabit: event.habitId == null,
        calendarLoading: true,
        recordsLoading: true,
      ),
    );

    final grid = _monthGridRange(state.month);
    final period = _periodRange(state.period);

    final calFut = _getCalendar(
      StatsRangeParams(from: grid.$1, to: grid.$2, habitId: event.habitId),
    );
    final recFut = _getRecords(
      StatsRangeParams(from: period.$1, to: period.$2, habitId: event.habitId),
    );

    final calRes = await calFut;
    final recRes = await recFut;

    emit(
      state.copyWith(
        calendar: calRes.fold((_) => state.calendar, (v) => v),
        records: recRes.fold((_) => state.records, (v) => v),
        calendarLoading: false,
        recordsLoading: false,
      ),
    );
  }

  Future<void> _onMonthStepped(
    StatsMonthStepped event,
    Emitter<StatsState> emit,
  ) async {
    final month = DateTime(
      state.month.year,
      state.month.month + event.delta,
      1,
    );
    emit(state.copyWith(month: month, calendarLoading: true));

    final grid = _monthGridRange(month);
    final res = await _getCalendar(
      StatsRangeParams(
        from: grid.$1,
        to: grid.$2,
        habitId: state.selectedHabitId,
      ),
    );

    emit(
      state.copyWith(
        calendar: res.fold((_) => state.calendar, (v) => v),
        calendarLoading: false,
      ),
    );
  }

  Future<void> _onPeriodChanged(
    StatsPeriodChanged event,
    Emitter<StatsState> emit,
  ) async {
    emit(state.copyWith(period: event.period, recordsLoading: true));

    final period = _periodRange(event.period);
    final res = await _getRecords(
      StatsRangeParams(
        from: period.$1,
        to: period.$2,
        habitId: state.selectedHabitId,
      ),
    );

    emit(
      state.copyWith(
        records: res.fold((_) => state.records, (v) => v),
        recordsLoading: false,
      ),
    );
  }

  Future<void> _onWeekStepped(
    StatsWeekStepped event,
    Emitter<StatsState> emit,
  ) async {
    final weekStart = state.weekStart.add(Duration(days: 7 * event.delta));
    emit(state.copyWith(weekStart: weekStart, weeklyLoading: true));

    final week = _weekRange(weekStart);
    final res = await _getWeekly(StatsRangeParams(from: week.$1, to: week.$2));

    emit(
      state.copyWith(
        weekly: res.fold((_) => state.weekly, (v) => v),
        weeklyLoading: false,
      ),
    );
  }

  // --- Sana oraliqlari ---

  /// Oyning butun 6 haftalik gridi: 1-kun joylashgan haftaning dushanbasidan
  /// 42 kun.
  (DateTime, DateTime) _monthGridRange(DateTime month) {
    final start = month.subtract(Duration(days: month.weekday - 1));
    return (start, start.add(const Duration(days: 41)));
  }

  /// Rekordlar davri: bugundan orqaga `days` kun.
  (DateTime, DateTime) _periodRange(RecordsPeriod period) {
    final today = ApiDate.dayOnly(DateTime.now());
    return (today.subtract(Duration(days: period.days - 1)), today);
  }

  (DateTime, DateTime) _weekRange(DateTime weekStart) =>
      (weekStart, weekStart.add(const Duration(days: 6)));
}
