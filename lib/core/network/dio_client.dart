import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'session_notifier.dart';
import '../storage/token_storage.dart';

/// Sozlangan `Dio` instansiyasini yasaydi.
///
/// Butun ilovada bitta `Dio` ishlatiladi — connection pool qayta ishlatiladi
/// va interceptor'lar bir marta ro'yxatdan o'tadi.
class DioClient {
  const DioClient._();

  static Dio create({
    required TokenStorage storage,
    required SessionNotifier sessionNotifier,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        // 4xx ni ham "javob" deb qabul qilamiz emas — Dio o'zi
        // DioException otsin, biz uni ErrorMapper orqali tarjima qilamiz.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    // Interceptor 401 "expired" da so'rovni qayta yuborishi uchun aynan shu
    // `dio` ga havola oladi — shuning uchun avval yasab, keyin qo'shamiz.
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        sessionNotifier: sessionNotifier,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          // Parol log'ga tushmasligi uchun body'ni filtrlaymiz.
          logPrint: (Object object) {
            final line = object.toString();
            developer.log(
              line.contains('password')
                  ? line.replaceAll(
                      RegExp(r'"password":\s*"[^"]*"'),
                      '"password": "***"',
                    )
                  : line,
              name: 'HTTP',
            );
          },
        ),
      );
    }

    return dio;
  }
}
