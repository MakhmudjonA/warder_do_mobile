part of 'stats_bloc.dart';

enum StatsStatus { initial, loading, ready, failure }

class StatsState extends Equatable {
  StatsState({
    this.status = StatsStatus.initial,
    this.habits = const [],
    this.selectedHabitId,
    DateTime? month,
    this.calendar = const [],
    this.calendarLoading = false,
    this.period = RecordsPeriod.last30,
    this.records,
    this.recordsLoading = false,
    DateTime? weekStart,
    this.weekly,
    this.weeklyLoading = false,
    this.failure,
  }) : month = month ?? _defaultMonth(),
       weekStart = weekStart ?? _defaultWeek();

  final StatsStatus status;

  /// "All Habits" tanlagichi uchun butun ro'yxat.
  final List<HabitOption> habits;

  /// `null` — barcha odatlar.
  final String? selectedHabitId;

  // --- Kalendar ---
  /// Ko'rsatilayotgan oy (oyning 1-kuni).
  final DateTime month;
  final List<CalendarDay> calendar;
  final bool calendarLoading;

  // --- Rekordlar ---
  final RecordsPeriod period;
  final StatsRecords? records;
  final bool recordsLoading;

  // --- Haftalik jadval ---
  final DateTime weekStart;
  final WeeklyStats? weekly;
  final bool weeklyLoading;

  /// Boshlang'ich yuklashdagi xatolik (butun ekran uchun).
  final Failure? failure;

  /// Hozir tanlangan odat (yo'q bo'lsa — `null`, ya'ni "barchasi").
  HabitOption? get selectedHabit {
    for (final habit in habits) {
      if (habit.id == selectedHabitId) return habit;
    }
    return null;
  }

  static DateTime _defaultMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime _defaultWeek() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return today.subtract(Duration(days: today.weekday - 1));
  }

  StatsState copyWith({
    StatsStatus? status,
    List<HabitOption>? habits,
    String? selectedHabitId,
    DateTime? month,
    List<CalendarDay>? calendar,
    bool? calendarLoading,
    RecordsPeriod? period,
    StatsRecords? records,
    bool? recordsLoading,
    DateTime? weekStart,
    WeeklyStats? weekly,
    bool? weeklyLoading,
    Failure? failure,
    bool clearHabit = false,
    bool clearFailure = false,
  }) {
    return StatsState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      selectedHabitId: clearHabit
          ? null
          : (selectedHabitId ?? this.selectedHabitId),
      month: month ?? this.month,
      calendar: calendar ?? this.calendar,
      calendarLoading: calendarLoading ?? this.calendarLoading,
      period: period ?? this.period,
      records: records ?? this.records,
      recordsLoading: recordsLoading ?? this.recordsLoading,
      weekStart: weekStart ?? this.weekStart,
      weekly: weekly ?? this.weekly,
      weeklyLoading: weeklyLoading ?? this.weeklyLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    habits,
    selectedHabitId,
    month,
    calendar,
    calendarLoading,
    period,
    records,
    recordsLoading,
    weekStart,
    weekly,
    weeklyLoading,
    failure,
  ];
}
