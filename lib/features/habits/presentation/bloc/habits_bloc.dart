import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/api_date.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/daily_habit.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/usecases/habit_usecases.dart';

part 'habits_event.dart';
part 'habits_state.dart';

/// Bosh ekran ("Bugun") holati.
///
/// **Optimistik yangilash** shu blocning asosiy g'oyasi: checkbox bosilganda
/// UI darhol o'zgaradi, so'rov fonda ketadi. Xato bo'lsa avvalgi holat
/// qaytariladi va snackbar ko'rsatiladi. Offline rejim yo'q, shuning uchun
/// UX ning tezligi butunlay shunga bog'liq.
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc({
    required GetDailyHabits getDailyHabits,
    required LogHabit logHabit,
    required UnlogHabit unlogHabit,
    required CreateHabit createHabit,
    required UpdateHabit updateHabit,
  }) : _getDailyHabits = getDailyHabits,
       _logHabit = logHabit,
       _unlogHabit = unlogHabit,
       _createHabit = createHabit,
       _updateHabit = updateHabit,
       super(HabitsState()) {
    on<HabitsRequested>(_onRequested);
    on<HabitsDateSelected>(_onDateSelected);
    on<HabitToggled>(_onToggled);
    on<HabitValueAdded>(_onValueAdded);
    on<HabitDurationAdded>(_onDurationAdded);
    on<HabitLogCleared>(_onLogCleared);
    on<HabitCreateSubmitted>(_onCreateSubmitted);
    on<HabitUpdateSubmitted>(_onUpdateSubmitted);
    on<HabitsNoticeCleared>(
      (event, emit) => emit(state.copyWith(clearNotice: true)),
    );
    on<HabitsUnlockDismissed>(
      (event, emit) => emit(state.copyWith(clearUnlocked: true)),
    );
  }

  final GetDailyHabits _getDailyHabits;
  final LogHabit _logHabit;
  final UnlogHabit _unlogHabit;
  final CreateHabit _createHabit;
  final UpdateHabit _updateHabit;

  Future<void> _onRequested(
    HabitsRequested event,
    Emitter<HabitsState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(status: HabitsStatus.loading, clearFailure: true));
    }

    final result = await _getDailyHabits(
      DailyHabitsParams(date: state.selectedDate),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          // Sokin yangilashda eski ro'yxatni buzmaymiz — faqat xabar beramiz.
          status: event.silent ? HabitsStatus.ready : HabitsStatus.failure,
          failure: event.silent ? null : failure,
          notice: event.silent ? failure.message : null,
          noticeId: event.silent ? state.noticeId + 1 : state.noticeId,
        ),
      ),
      (habits) => emit(
        state.copyWith(
          status: HabitsStatus.ready,
          habits: habits,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onDateSelected(
    HabitsDateSelected event,
    Emitter<HabitsState> emit,
  ) async {
    final date = ApiDate.dayOnly(event.date);
    if (ApiDate.isSameDay(date, state.selectedDate)) return;

    emit(
      state.copyWith(
        selectedDate: date,
        // Eski kunning ro'yxatini darhol tozalaymiz, aks holda bir lahza
        // boshqa kunning odatlari ko'rinib qoladi.
        habits: const [],
        status: HabitsStatus.loading,
        clearFailure: true,
      ),
    );

    add(const HabitsRequested(silent: true));
  }

  Future<void> _onToggled(HabitToggled event, Emitter<HabitsState> emit) async {
    final item = _find(event.habitId);
    if (item == null || state.isPending(item.habit.id)) return;

    // Bajarilgan bo'lsa — belgini olib tashlaymiz.
    if (item.isCompleted) {
      await _optimistic(
        emit,
        item: item,
        optimisticLog: null,
        request: () => _unlogHabit(
          UnlogHabitParams(habitId: item.habit.id, date: state.selectedDate),
        ),
      );
      return;
    }

    // Bajarilmagan: checkbox odat uchun `completed: true`, miqdorli odat
    // uchun esa qolgan miqdorni to'ldiramiz.
    final goal = item.habit.goalValue;
    final remaining = goal == null ? null : goal - item.currentValue;

    await _optimistic(
      emit,
      item: item,
      optimisticLog: _localLog(item, value: goal, completed: true),
      request: () => _logHabit(
        remaining != null && remaining > 0
            ? LogHabitParams(
                habitId: item.habit.id,
                date: state.selectedDate,
                value: remaining,
                completed: true,
              )
            : LogHabitParams.complete(
                habitId: item.habit.id,
                date: state.selectedDate,
              ),
      ),
    );
  }

  Future<void> _onValueAdded(
    HabitValueAdded event,
    Emitter<HabitsState> emit,
  ) async {
    final item = _find(event.habitId);
    if (item == null || state.isPending(item.habit.id)) return;

    final newValue = item.currentValue + event.amount;

    await _optimistic(
      emit,
      item: item,
      optimisticLog: _localLog(
        item,
        value: newValue,
        completed: _reachesGoal(item.habit, newValue),
      ),
      request: () => _logHabit(
        LogHabitParams.addValue(
          habitId: item.habit.id,
          date: state.selectedDate,
          // Serverga **qo'shiladigan** miqdor ketadi, jami emas.
          amount: event.amount,
        ),
      ),
    );
  }

  Future<void> _onDurationAdded(
    HabitDurationAdded event,
    Emitter<HabitsState> emit,
  ) async {
    final item = _find(event.habitId);
    if (item == null || state.isPending(item.habit.id)) return;

    // Timer odatlarida server sekundlarni `goal_unit` ga o'giradi, shuning
    // uchun lokal taxminni ham shu birlikda hisoblaymiz.
    final added = _durationInGoalUnit(item.habit, event.seconds);
    final newValue = item.currentValue + added;

    await _optimistic(
      emit,
      item: item,
      optimisticLog: _localLog(
        item,
        value: newValue,
        completed: _reachesGoal(item.habit, newValue),
      ),
      request: () => _logHabit(
        LogHabitParams.addDuration(
          habitId: item.habit.id,
          date: state.selectedDate,
          seconds: event.seconds,
        ),
      ),
    );
  }

  Future<void> _onLogCleared(
    HabitLogCleared event,
    Emitter<HabitsState> emit,
  ) async {
    final item = _find(event.habitId);
    if (item == null || item.log == null || state.isPending(item.habit.id)) {
      return;
    }

    await _optimistic(
      emit,
      item: item,
      optimisticLog: null,
      request: () => _unlogHabit(
        UnlogHabitParams(habitId: item.habit.id, date: state.selectedDate),
      ),
    );
  }

  Future<void> _onCreateSubmitted(
    HabitCreateSubmitted event,
    Emitter<HabitsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearNotice: true));

    final result = await _createHabit(event.draft);

    result.fold(
      // `notice` ataylab qo'yilmaydi: xabarni forma o'zi ko'rsatadi, aks holda
      // "Bugun" ekranining listeneri ham xuddi shu snackbarni takrorlaydi.
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          failure: failure,
          noticeId: state.noticeId + 1,
        ),
      ),
      (habit) {
        emit(
          state.copyWith(
            isSubmitting: false,
            createdHabit: habit,
            noticeId: state.noticeId + 1,
            clearFailure: true,
          ),
        );
        // Yangi odat bugungi jadvalga tushishi mumkin — ro'yxatni yangilaymiz.
        add(const HabitsRequested(silent: true));
      },
    );
  }

  Future<void> _onUpdateSubmitted(
    HabitUpdateSubmitted event,
    Emitter<HabitsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearNotice: true));

    final result = await _updateHabit(
      UpdateHabitParams(original: event.original, edited: event.edited),
    );

    result.fold(
      // Yaratishdagi kabi: xabarni forma o'zi ko'rsatadi.
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          failure: failure,
          noticeId: state.noticeId + 1,
        ),
      ),
      (habit) {
        emit(
          state.copyWith(
            isSubmitting: false,
            updatedHabit: habit,
            noticeId: state.noticeId + 1,
            clearFailure: true,
          ),
        );
        // Jadval yoki guruh o'zgargan bo'lishi mumkin — ro'yxatni qayta olamiz.
        add(const HabitsRequested(silent: true));
      },
    );
  }

  // --- Optimistik yangilash yadrosi ---

  /// UI ni darhol yangilaydi, so'rovni yuboradi, xato bo'lsa qaytaradi.
  ///
  /// [request] `LogResult` yoki `Unit` qaytarishi mumkin — birinchisida
  /// serverdagi yakuniy log bilan almashtiramiz va yutuqlarni tekshiramiz.
  Future<void> _optimistic(
    Emitter<HabitsState> emit, {
    required DailyHabit item,
    required HabitLog? optimisticLog,
    required Future<Either<Failure, Object>> Function() request,
  }) async {
    final previous = state.habits;
    final habitId = item.habit.id;

    emit(
      state.copyWith(
        habits: _replaceLog(previous, habitId, optimisticLog),
        pendingIds: {...state.pendingIds, habitId},
        clearNotice: true,
      ),
    );

    final result = await request();

    result.fold(
      (failure) => emit(
        state.copyWith(
          // Rollback: serverdagi holat o'zgarmagan, demak UI ham qaytadi.
          habits: previous,
          pendingIds: _withoutPending(habitId),
          notice: failure.message,
          noticeId: state.noticeId + 1,
        ),
      ),
      (value) {
        if (value is LogResult) {
          emit(
            state.copyWith(
              habits: _replaceLog(state.habits, habitId, value.log),
              pendingIds: _withoutPending(habitId),
              newlyUnlocked: value.newlyUnlocked.isEmpty
                  ? null
                  : value.newlyUnlocked,
              unlockId: value.newlyUnlocked.isEmpty
                  ? state.unlockId
                  : state.unlockId + 1,
            ),
          );
        } else {
          emit(state.copyWith(pendingIds: _withoutPending(habitId)));
        }
      },
    );
  }

  // --- Yordamchilar ---

  DailyHabit? _find(String habitId) {
    for (final item in state.habits) {
      if (item.habit.id == habitId) return item;
    }
    return null;
  }

  Set<String> _withoutPending(String habitId) =>
      state.pendingIds.where((id) => id != habitId).toSet();

  List<DailyHabit> _replaceLog(
    List<DailyHabit> source,
    String habitId,
    HabitLog? log,
  ) {
    return [
      for (final item in source)
        if (item.habit.id == habitId) item.copyWithLog(log) else item,
    ];
  }

  /// Server javobini kutmasdan ko'rsatiladigan vaqtinchalik log.
  ///
  /// `id` soxta — u faqat UI uchun; muvaffaqiyatli javobdan keyin haqiqiysi
  /// bilan almashtiriladi.
  HabitLog _localLog(
    DailyHabit item, {
    double? value,
    required bool completed,
  }) {
    return HabitLog(
      id: item.log?.id ?? 'optimistic-${item.habit.id}',
      habitId: item.habit.id,
      date: item.date,
      value: value,
      durationSeconds: item.log?.durationSeconds,
      completed: completed,
    );
  }

  /// Backenddagi `goal_type` mantig'ining lokal nusxasi.
  bool _reachesGoal(Habit habit, double value) {
    final goal = habit.goalValue;
    if (goal == null) return true;

    return switch (habit.goalType ?? GoalType.atLeast) {
      GoalType.atLeast => value >= goal,
      GoalType.atMost => value <= goal,
      GoalType.exact => value == goal,
    };
  }

  double _durationInGoalUnit(Habit habit, int seconds) {
    return switch (habit.goalUnit?.toLowerCase()) {
      'hour' || 'hours' => seconds / 3600,
      'minute' || 'minutes' => seconds / 60,
      _ => seconds.toDouble(),
    };
  }
}
