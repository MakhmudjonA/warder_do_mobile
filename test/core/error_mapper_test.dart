import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/constants/app_strings.dart';
import 'package:warder_do_mobile/core/error/exceptions.dart';
import 'package:warder_do_mobile/core/network/error_mapper.dart';

DioException _badResponse(
  int status,
  dynamic body, {
  String path = '/auth/login',
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('ErrorMapper', () {
    test('401 → foydalanuvchiga tushunarli matn', () {
      final result = ErrorMapper.map(
        _badResponse(401, {'detail': 'Incorrect email or password'}),
      );

      expect(result, isA<ServerException>());
      expect((result as ServerException).statusCode, 401);
      expect(result.message, AppStrings.errInvalidCredentials);
    });

    test('boshqa endpointdagi 401 → sessiya tugadi, parol emas', () {
      final result =
          ErrorMapper.map(
                _badResponse(401, {
                  'detail': 'Could not validate credentials',
                }, path: '/habits'),
              )
              as ServerException;

      expect(result.message, AppStrings.errSessionExpired);
    });

    test('AI "bu vazifa emas" (422) → tushunarli matn', () {
      final result =
          ErrorMapper.map(
                _badResponse(422, {
                  'detail': 'This does not look like a habit or a task',
                }, path: '/habits/parse'),
              )
              as ServerException;

      expect(result.message, AppStrings.errNotAHabit);
    });

    test('shaxsiy bot (403 /auth/telegram) → bloklangan emas', () {
      final result =
          ErrorMapper.map(
                _badResponse(403, {
                  'detail': 'This bot is private',
                }, path: '/auth/telegram'),
              )
              as ServerException;

      expect(result.message, AppStrings.errPrivateBot);
    });

    test('409 → email band', () {
      final result =
          ErrorMapper.map(
                _badResponse(409, {
                  'detail': 'Email already registered',
                }, path: '/auth/register'),
              )
              as ServerException;

      expect(result.message, AppStrings.errEmailTaken);
    });

    test('dasturdagi 409 → email haqida emas', () {
      final result =
          ErrorMapper.map(
                _badResponse(409, {
                  'detail': 'This habit already has an active program',
                }, path: '/programs'),
              )
              as ServerException;

      expect(result.message, AppStrings.errProgramExists);
    });

    test('422 → maydonlar bo’yicha xatolar ajratiladi', () {
      final result =
          ErrorMapper.map(
                _badResponse(422, {
                  'detail': [
                    {
                      'loc': ['body', 'password'],
                      'msg': 'String should have at least 8 characters',
                      'type': 'string_too_short',
                    },
                    {
                      'loc': ['body', 'email'],
                      'msg': 'value is not a valid email address',
                      'type': 'value_error',
                    },
                  ],
                }),
              )
              as ServerException;

      expect(result.statusCode, 422);
      expect(
        result.fieldErrors['password'],
        'String should have at least 8 characters',
      );
      expect(result.fieldErrors['email'], 'value is not a valid email address');
    });

    test('500 → umumiy server xatosi', () {
      final result =
          ErrorMapper.map(_badResponse(500, null)) as ServerException;

      expect(result.message, AppStrings.errServer);
    });

    test('connectionError → NetworkException', () {
      final result = ErrorMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(result, isA<NetworkException>());
    });

    test('timeout → NetworkException, timeout matni bilan', () {
      final result =
          ErrorMapper.map(
                DioException(
                  requestOptions: RequestOptions(path: '/auth/me'),
                  type: DioExceptionType.connectionTimeout,
                ),
              )
              as NetworkException;

      expect(result.message, AppStrings.errTimeout);
    });
  });
}
