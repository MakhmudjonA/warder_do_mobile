import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stats_entities.dart';
import '../repositories/stats_repository.dart';

/// Kalendar gridini oladi (odatda 6 haftalik oraliq).
class GetStatsCalendar implements UseCase<List<CalendarDay>, StatsRangeParams> {
  const GetStatsCalendar(this._repository);

  final StatsRepository _repository;

  @override
  Future<Either<Failure, List<CalendarDay>>> call(StatsRangeParams params) =>
      _repository.getCalendar(
        from: params.from,
        to: params.to,
        habitId: params.habitId,
      );
}

/// 4 ta katta raqam (streak, completed, success rate).
class GetStatsRecords implements UseCase<StatsRecords, StatsRangeParams> {
  const GetStatsRecords(this._repository);

  final StatsRepository _repository;

  @override
  Future<Either<Failure, StatsRecords>> call(StatsRangeParams params) =>
      _repository.getRecords(
        from: params.from,
        to: params.to,
        habitId: params.habitId,
      );
}

/// Haftalik jadval (odat × kun). `habit_id` filtri yo'q — allaqachon
/// odatlar bo'yicha ajratilgan.
class GetStatsWeekly implements UseCase<WeeklyStats, StatsRangeParams> {
  const GetStatsWeekly(this._repository);

  final StatsRepository _repository;

  @override
  Future<Either<Failure, WeeklyStats>> call(StatsRangeParams params) =>
      _repository.getWeekly(from: params.from, to: params.to);
}

class StatsRangeParams extends Equatable {
  const StatsRangeParams({required this.from, required this.to, this.habitId});

  final DateTime from;
  final DateTime to;

  /// `null` — barcha odatlar.
  final String? habitId;

  @override
  List<Object?> get props => [from, to, habitId];
}
