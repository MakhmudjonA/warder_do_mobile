import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/utils/api_date.dart';
import '../../domain/entities/habit.dart';
import '../models/achievement_model.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';

/// Odatlar bo'yicha barcha HTTP so'rovlar.
///
/// Bu qatlamda `Either` yo'q — xatolik bo'lsa exception otiladi, uni
/// `Failure` ga aylantirish repository'ning ishi.
abstract class HabitsRemoteDataSource {
  /// Bosh ekran uchun: shu kunga tegishli odatlar + har biriga o'sha kungi log.
  Future<List<DailyHabitModel>> getHabits({
    DateTime? date,
    bool all = false,
    bool includeArchived = false,
  });

  Future<HabitModel> getHabit(String id);
  Future<HabitModel> createHabit(Habit habit);
  Future<HabitModel> updateHabit(String id, Map<String, dynamic> changes);

  /// AI: matndan saqlanmagan odat qoralamasi.
  Future<HabitModel> parseHabit(String text);
  Future<void> deleteHabit(String id);
  Future<HabitModel> archiveHabit(String id);
  Future<HabitModel> unarchiveHabit(String id);
  Future<List<HabitModel>> reorderHabits(List<String> orderedIds);

  Future<LogResultModel> logHabit(
    String habitId, {
    required DateTime date,
    double? value,
    int? durationSeconds,
    bool? completed,
  });

  Future<void> unlogHabit(String habitId, DateTime date);

  Future<List<HabitLogModel>> getLogs(
    String habitId, {
    DateTime? from,
    DateTime? to,
  });

  Future<StreakInfoModel> getStreak(String habitId);

  /// Auth talab qilmaydi.
  Future<List<HabitTemplateModel>> getTemplates({String? category});
}

class HabitsRemoteDataSourceImpl implements HabitsRemoteDataSource {
  const HabitsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<DailyHabitModel>> getHabits({
    DateTime? date,
    bool all = false,
    bool includeArchived = false,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.habits,
        queryParameters: {
          if (date != null) 'date': ApiDate.format(date),
          if (all) 'all': true,
          if (includeArchived) 'include_archived': true,
        },
      );
      return response.data!
          .map((e) => DailyHabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<HabitModel> getHabit(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.habit(id),
      );
      return HabitModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<HabitModel> createHabit(Habit habit) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.habits,
        data: HabitModel.toCreateJson(habit),
      );
      return HabitModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<HabitModel> updateHabit(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.habit(id),
        data: changes,
      );
      return HabitModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    try {
      // 204 — javob tanasi bo'lmaydi, `response.data` o'qilmaydi.
      await _dio.delete<void>(ApiConstants.habit(id));
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<HabitModel> archiveHabit(String id) =>
      _postReturningHabit(ApiConstants.habitArchive(id));

  @override
  Future<HabitModel> unarchiveHabit(String id) =>
      _postReturningHabit(ApiConstants.habitUnarchive(id));

  Future<HabitModel> _postReturningHabit(String path) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path);
      return HabitModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<List<HabitModel>> reorderHabits(List<String> orderedIds) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        ApiConstants.habitsReorder,
        data: HabitModel.toReorderJson(orderedIds),
      );
      return response.data!
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<LogResultModel> logHabit(
    String habitId, {
    required DateTime date,
    double? value,
    int? durationSeconds,
    bool? completed,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.habitLogs(habitId),
        data: HabitLogModel.toLogJson(
          date: date,
          value: value,
          durationSeconds: durationSeconds,
          completed: completed,
        ),
      );
      return LogResultModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> unlogHabit(String habitId, DateTime date) async {
    try {
      // Idempotent: bo'sh kunni o'chirsa ham 204 keladi, 404 emas.
      await _dio.delete<void>(
        ApiConstants.habitLogs(habitId),
        queryParameters: {'date': ApiDate.format(date)},
      );
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<List<HabitLogModel>> getLogs(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.habitLogs(habitId),
        queryParameters: {
          if (from != null) 'from': ApiDate.format(from),
          if (to != null) 'to': ApiDate.format(to),
        },
      );
      return response.data!
          .map((e) => HabitLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<StreakInfoModel> getStreak(String habitId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.habitStreak(habitId),
      );
      return StreakInfoModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<List<HabitTemplateModel>> getTemplates({String? category}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.templates,
        queryParameters: {'category': ?category},
      );
      return response.data!
          .map((e) => HabitTemplateModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<HabitModel> parseHabit(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.habitsParse,
        data: {'text': text},
        // AI javobi oddiy so'rovdan uzoqroq.
        options: Options(receiveTimeout: ApiConstants.aiReceiveTimeout),
      );
      return HabitModel.fromDraftJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
