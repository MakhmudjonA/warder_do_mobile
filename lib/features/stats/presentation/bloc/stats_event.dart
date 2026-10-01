part of 'stats_bloc.dart';

sealed class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

/// Ekran birinchi ochilganda — odatlar ro'yxati + uchala blok.
class StatsStarted extends StatsEvent {
  const StatsStarted();
}

/// Tortib yangilash — hammasini qayta yuklaydi.
class StatsRefreshed extends StatsEvent {
  const StatsRefreshed();
}

/// "All Habits" tanlagichi o'zgardi. Kalendar va rekordlarga ta'sir qiladi,
/// haftalik jadval o'zgarmaydi (unda filtr yo'q).
class StatsHabitFilterChanged extends StatsEvent {
  const StatsHabitFilterChanged(this.habitId);

  /// `null` — barcha odatlar.
  final String? habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Kalendar oyi surildi (`-1` — oldingi, `+1` — keyingi).
class StatsMonthStepped extends StatsEvent {
  const StatsMonthStepped(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

/// Rekordlar davri o'zgardi (7 / 30 / 90 kun).
class StatsPeriodChanged extends StatsEvent {
  const StatsPeriodChanged(this.period);

  final RecordsPeriod period;

  @override
  List<Object?> get props => [period];
}

/// Haftalik jadvalda hafta surildi.
class StatsWeekStepped extends StatsEvent {
  const StatsWeekStepped(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}
