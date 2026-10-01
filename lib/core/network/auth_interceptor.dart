import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../storage/token_storage.dart';
import 'session_notifier.dart';

/// Har bir so'rovga `Authorization: Bearer <access>` qo'shadi va access token
/// tuganda uni `/auth/refresh` orqali **jimgina** yangilaydi.
///
/// Faqat access token muddati tuganda (backend `"Access token has expired"`
/// deydi) refresh qilamiz. Boshqa 401/403 — sessiya haqiqatan tugagan yoki
/// hisob bloklangan degani, foydalanuvchi login ekraniga qaytariladi.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage storage,
    required SessionNotifier sessionNotifier,
  }) : _dio = dio,
       _storage = storage,
       _sessionNotifier = sessionNotifier,
       // Refresh so'rovi shu interceptordan **o'tmasligi** kerak — aks holda
       // cheksiz sikl bo'ladi. Shuning uchun alohida, "yalang'och" Dio.
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: dio.options.baseUrl,
           connectTimeout: dio.options.connectTimeout,
           receiveTimeout: dio.options.receiveTimeout,
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
         ),
       );

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final SessionNotifier _sessionNotifier;

  /// Ayni paytda ketayotgan refresh (bo'lsa). Bir martalik refresh tokenni
  /// bir vaqtda ikki marta ishlatib yubormaslik uchun — barcha 401 lar shu
  /// bitta Future'ni kutadi (single-flight lock).
  Future<bool>? _refreshing;

  /// Bu yo'llarga token kerak emas va ulardagi 401 "sessiya tugadi" degani emas.
  static const Set<String> _publicPaths = {
    ApiConstants.register,
    ApiConstants.login,
    ApiConstants.token,
    ApiConstants.refresh,
    ApiConstants.logout,
    ApiConstants.telegramAuth,
    ApiConstants.telegramLoginRequest,
    ApiConstants.telegramLoginPoll,
  };

  bool _isPublic(String path) => _publicPaths.any(path.endsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _storage.read(StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (_isPublic(path) || (status != 401 && status != 403)) {
      return handler.next(err);
    }

    final detail = _detail(err.response?.data);
    final accessExpired =
        status == 401 && detail == ApiConstants.accessExpiredDetail;

    // 403 (bloklangan) yoki boshqa sababli 401 — refresh yordam bermaydi.
    if (!accessExpired) {
      await _clearTokens();
      _sessionNotifier.notifyExpired();
      return handler.next(err);
    }

    final refreshed = await _ensureRefreshed();
    if (!refreshed) {
      // Refresh token ham o'lik — sessiya tugadi.
      await _clearTokens();
      _sessionNotifier.notifyExpired();
      return handler.next(err);
    }

    // Yangi access token bilan asl so'rovni qayta yuboramiz.
    try {
      final newAccess = await _storage.read(StorageKeys.accessToken);
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess';
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Refresh navbat bilan — birinchi chaqiruv haqiqatan yangilaydi, qolganlari
  /// o'sha natijani kutadi.
  Future<bool> _ensureRefreshed() {
    return _refreshing ??= _performRefresh().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data == null) return false;
      await _saveTokens(data);
      return true;
    } on DioException {
      return false;
    }
  }

  /// `/auth/refresh` javobini xom ko'rinishda saqlaydi. Modelga bog'lanmaymiz —
  /// core qatlami feature qatlamini bilmasligi kerak.
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final now = DateTime.now().toUtc();
    final accessSeconds = (data['expires_in'] as num?)?.toInt() ?? 3600;
    final refreshSeconds =
        (data['refresh_expires_in'] as num?)?.toInt() ?? 2592000;

    await _storage.write(
      StorageKeys.accessToken,
      data['access_token'] as String,
    );
    await _storage.write(
      StorageKeys.tokenType,
      data['token_type'] as String? ?? 'bearer',
    );
    await _storage.write(
      StorageKeys.tokenExpiresAt,
      now.add(Duration(seconds: accessSeconds)).toIso8601String(),
    );
    await _storage.write(
      StorageKeys.refreshToken,
      data['refresh_token'] as String? ?? '',
    );
    await _storage.write(
      StorageKeys.refreshExpiresAt,
      now.add(Duration(seconds: refreshSeconds)).toIso8601String(),
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.tokenType);
    await _storage.delete(StorageKeys.tokenExpiresAt);
    await _storage.delete(StorageKeys.refreshToken);
    await _storage.delete(StorageKeys.refreshExpiresAt);
  }

  String? _detail(dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return null;
  }
}
