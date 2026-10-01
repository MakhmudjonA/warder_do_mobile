import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/error_mapper.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';
import '../../domain/entities/telegram_login.dart';

/// Backend bilan gaplashadigan yagona joy.
///
/// Bu yerda hech qanday `Either` yo'q — xatolik bo'lsa exception otiladi.
/// Uni `Failure` ga aylantirish repository'ning vazifasi.
abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  });

  Future<AuthTokenModel> login({
    required String email,
    required String password,
  });

  /// Telegram Mini App'dan kirish: `initData` ni server imzo bo'yicha
  /// tekshiradi, birinchi marta bo'lsa hisob yaratadi.
  Future<AuthTokenModel> loginWithTelegram({
    required String initData,
    String? timezone,
  });

  /// Telefon ilovasi: "Войти через Telegram" urinishini boshlash.
  Future<TelegramLoginTicket> requestTelegramLogin({String? timezone});

  /// Tasdiqlandimi? `confirmed` bo'lsa token ham keladi (bir marta).
  Future<(TelegramLoginStatus, AuthTokenModel?)> pollTelegramLogin(String code);

  Future<UserModel> getMe();

  /// [taskRemindBefore]: `null` — o'zgarmaydi, `-1` — server standartiga
  /// qaytarish (`null` yuboriladi), aks holda daqiqalar.
  Future<UserModel> updateMe({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  });

  /// Shu qurilma sessiyasini serverda bekor qiladi. Auth header shart emas —
  /// access token allaqachon eskirgan bo'lsa ham chiqish ishlashi kerak.
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          // `null` maydonlarni umuman yubormaymiz — server default qo'yadi.
          'full_name': ?fullName,
          'timezone': ?timezone,
        },
      );
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AuthTokenModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthTokenModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AuthTokenModel> loginWithTelegram({
    required String initData,
    String? timezone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.telegramAuth,
        data: {'init_data': initData, 'timezone': ?timezone},
      );
      return AuthTokenModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<TelegramLoginTicket> requestTelegramLogin({String? timezone}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.telegramLoginRequest,
        data: {'timezone': ?timezone},
      );
      final data = response.data!;
      return TelegramLoginTicket(
        code: data['code'] as String,
        displayCode: data['display_code'] as String,
        botUrl: data['bot_url'] as String,
        expiresAt: DateTime.now().add(
          Duration(seconds: (data['expires_in'] as num?)?.toInt() ?? 600),
        ),
      );
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<(TelegramLoginStatus, AuthTokenModel?)> pollTelegramLogin(
    String code,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.telegramLoginPoll,
        data: {'code': code},
      );
      final data = response.data!;
      final status = switch (data['status']) {
        'confirmed' => TelegramLoginStatus.confirmed,
        'cancelled' => TelegramLoginStatus.cancelled,
        'expired' => TelegramLoginStatus.expired,
        _ => TelegramLoginStatus.pending,
      };
      final token = data['token'];
      return (
        status,
        token is Map<String, dynamic> ? AuthTokenModel.fromJson(token) : null,
      );
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<UserModel> updateMe({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.me,
        data: {
          'full_name': ?fullName,
          'timezone': ?timezone,
          if (taskRemindBefore != null)
            'task_remind_before_minutes': taskRemindBefore < 0
                ? null
                : taskRemindBefore,
        },
      );
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
