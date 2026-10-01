import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/utils/api_date.dart';
import '../models/stats_models.dart';

/// Statistika ekranining uchta so'rovi: kalendar, rekordlar, haftalik jadval.
///
/// Har biri oraliqdagi barcha ma'lumotni **bitta** so'rovda oladi va serverda
/// hisoblaydi — odat yoki kun soni oshganda ham so'rovlar soni o'zgarmaydi.
abstract class StatsRemoteDataSource {
  Future<List<CalendarDayModel>> getCalendar({
    required DateTime from,
    required DateTime to,
    String? habitId,
    bool includeArchived = false,
  });

  Future<StatsRecordsModel> getRecords({
    required DateTime from,
    required DateTime to,
    String? habitId,
  });

  Future<WeeklyStatsModel> getWeekly({
    required DateTime from,
    required DateTime to,
  });
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  const StatsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CalendarDayModel>> getCalendar({
    required DateTime from,
    required DateTime to,
    String? habitId,
    bool includeArchived = false,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.statsCalendar,
        queryParameters: {
          'from': ApiDate.format(from),
          'to': ApiDate.format(to),
          'habit_id': ?habitId,
          if (includeArchived) 'include_archived': true,
        },
      );
      return response.data!
          .map((e) => CalendarDayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<StatsRecordsModel> getRecords({
    required DateTime from,
    required DateTime to,
    String? habitId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.statsRecords,
        queryParameters: {
          'from': ApiDate.format(from),
          'to': ApiDate.format(to),
          'habit_id': ?habitId,
        },
      );
      return StatsRecordsModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<WeeklyStatsModel> getWeekly({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.statsWeekly,
        queryParameters: {
          'from': ApiDate.format(from),
          'to': ApiDate.format(to),
        },
      );
      return WeeklyStatsModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
