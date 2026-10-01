import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import '../error/exceptions.dart';

/// `DioException` ni loyihaning o'z exception'lariga aylantiradi.
///
/// FastAPI ikki xil xato formatidan foydalanadi:
///   * oddiy xato  — `{"detail": "Incorrect email or password"}`
///   * 422         — `{"detail": [{"loc": ["body","password"], "msg": "..."}]}`
/// Ikkalasini ham shu yerda bitta ko'rinishga keltiramiz.
class ErrorMapper {
  const ErrorMapper._();

  static Exception map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(AppStrings.errTimeout);
      case DioExceptionType.transformTimeout:
        // Javob keldi, lekin uni parse qilish cho'zilib ketdi.
        return const NetworkException(AppStrings.errTimeout);
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const NetworkException(AppStrings.errNoInternet);
      case DioExceptionType.cancel:
        return const NetworkException(AppStrings.errUnknown);
      case DioExceptionType.badCertificate:
        return const NetworkException(AppStrings.errServer);
      case DioExceptionType.badResponse:
        final response = e.response;
        final status = response?.statusCode ?? 500;
        return ServerException(
          statusCode: status,
          message: _messageFor(status, response?.data, e.requestOptions.path),
          fieldErrors: _fieldErrors(response?.data),
        );
    }
  }

  static String _messageFor(int status, dynamic data, String path) {
    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    // 422 da detail — ro'yxat; foydalanuvchiga umumiy matn yaxshiroq,
    // aniqlik esa maydonlar ostida ko'rsatiladi.
    return _localize(
      status,
      detail is String && detail.isNotEmpty ? detail : null,
      path,
    );
  }

  /// Backend matnlari ingliz tilida — foydalanuvchi ko'radigan joyda
  /// ularni ilova tiliga almashtiramiz. Noma'lum holatlarda umumiy matn.
  ///
  /// Bir xil status turli endpointda turli ma'noga ega, shuning uchun
  /// [path] ham hisobga olinadi: login'dagi 401 — "parol noto'g'ri",
  /// boshqa joydagi 401 — "sessiya tugadi"; register'dagi 409 — "email
  /// band", dasturdagi 409 — "faol dastur allaqachon bor".
  static String _localize(int status, String? detail, String path) {
    switch (status) {
      case 401:
        if (path.endsWith(ApiConstants.telegramAuth)) {
          return AppStrings.errTelegramAuth;
        }
        return _isCredentialsCheck(path)
            ? AppStrings.errInvalidCredentials
            : AppStrings.errSessionExpired;
      case 403:
        if (path.endsWith(ApiConstants.telegramAuth)) {
          return AppStrings.errPrivateBot;
        }
        return AppStrings.errAccountBlocked;
      case 409:
        if (path.endsWith(ApiConstants.register)) {
          return AppStrings.errEmailTaken;
        }
        if (path.startsWith(ApiConstants.programs)) {
          return AppStrings.errProgramExists;
        }
        return AppStrings.errConflict;
      case 422:
        if (path.endsWith(ApiConstants.habitsParse)) {
          return AppStrings.errNotAHabit;
        }
        return AppStrings.errValidation;
      default:
        if (status >= 500) return AppStrings.errServer;
        return detail ?? AppStrings.errUnknown;
    }
  }

  static bool _isCredentialsCheck(String path) =>
      path.endsWith(ApiConstants.login) || path.endsWith(ApiConstants.token);

  /// `loc: ["body", "password"]` dan `{"password": "..."}` yasaydi.
  static Map<String, String> _fieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return const {};
    final detail = data['detail'];
    if (detail is! List) return const {};

    final result = <String, String>{};
    for (final item in detail) {
      if (item is! Map) continue;
      final loc = item['loc'];
      final msg = item['msg'];
      if (loc is! List || loc.isEmpty || msg is! String) continue;
      final field = loc.last.toString();
      result.putIfAbsent(field, () => msg);
    }
    return result;
  }
}
