import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/error/exceptions.dart';
import 'package:warder_do_mobile/core/error/failures.dart';
import 'package:warder_do_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:warder_do_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:warder_do_mobile/features/auth/data/models/auth_token_model.dart';
import 'package:warder_do_mobile/features/auth/data/models/user_model.dart';
import 'package:warder_do_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:warder_do_mobile/features/auth/domain/entities/telegram_login.dart';

final tUser = UserModel(
  id: 'e84c4875-9aa1-4062-8b21-815fbdaccbc0',
  email: 'ali@example.com',
  fullName: 'Ali',
  isActive: true,
  timezone: 'Asia/Tashkent',
  createdAt: DateTime.utc(2026, 9, 3),
);

AuthTokenModel tokenValidFor(
  Duration accessDuration, {
  Duration refreshDuration = const Duration(days: 30),
}) => AuthTokenModel(
  accessToken: 'jwt',
  tokenType: 'bearer',
  expiresAt: DateTime.now().toUtc().add(accessDuration),
  refreshToken: 'refresh',
  refreshExpiresAt: DateTime.now().toUtc().add(refreshDuration),
);

/// Sozlanadigan soxta remote — mocktail o'rniga qo'lda yozilgan, chunki
/// interfeys kichik va bog'liqlik qo'shishga arzimaydi.
class FakeRemote implements AuthRemoteDataSource {
  FakeRemote({this.onRegister, this.onLogin, this.onGetMe, this.onUpdateMe});

  final Future<UserModel> Function()? onRegister;
  final Future<AuthTokenModel> Function()? onLogin;
  final Future<UserModel> Function()? onGetMe;
  final Future<UserModel> Function()? onUpdateMe;

  int registerCalls = 0;
  int loginCalls = 0;
  int getMeCalls = 0;
  int logoutCalls = 0;
  String? lastLogoutToken;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  }) {
    registerCalls++;
    return onRegister?.call() ?? Future.value(tUser);
  }

  @override
  Future<AuthTokenModel> login({
    required String email,
    required String password,
  }) {
    loginCalls++;
    return onLogin?.call() ??
        Future.value(tokenValidFor(const Duration(hours: 1)));
  }

  int telegramCalls = 0;
  String? lastInitData;

  @override
  Future<AuthTokenModel> loginWithTelegram({
    required String initData,
    String? timezone,
  }) {
    telegramCalls++;
    lastInitData = initData;
    return Future.value(tokenValidFor(const Duration(hours: 1)));
  }

  @override
  Future<TelegramLoginTicket> requestTelegramLogin({String? timezone}) async =>
      TelegramLoginTicket(
        code: 'c',
        displayCode: '0000',
        botUrl: 'https://t.me/bot?start=login_c',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

  (TelegramLoginStatus, AuthTokenModel?) pollAnswer = (
    TelegramLoginStatus.pending,
    null,
  );

  @override
  Future<(TelegramLoginStatus, AuthTokenModel?)> pollTelegramLogin(
    String code,
  ) async => pollAnswer;

  @override
  Future<UserModel> getMe() {
    getMeCalls++;
    return onGetMe?.call() ?? Future.value(tUser);
  }

  @override
  Future<UserModel> updateMe({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  }) {
    return onUpdateMe?.call() ?? Future.value(tUser);
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls++;
    lastLogoutToken = refreshToken;
  }
}

class FakeLocal implements AuthLocalDataSource {
  AuthTokenModel? token;
  UserModel? user;
  int clearCalls = 0;

  @override
  Future<void> cacheToken(AuthTokenModel value) async => token = value;

  @override
  Future<AuthTokenModel?> getToken() async => token;

  @override
  Future<String?> getRefreshToken() async => token?.refreshToken;

  @override
  Future<void> cacheUser(UserModel value) async => user = value;

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<void> clearSession() async {
    clearCalls++;
    token = null;
    user = null;
  }
}

void main() {
  late FakeRemote remote;
  late FakeLocal local;
  late AuthRepositoryImpl repository;

  void build({FakeRemote? customRemote}) {
    remote = customRemote ?? FakeRemote();
    local = FakeLocal();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  }

  setUp(build);

  group('login', () {
    test('token saqlanadi va user qaytadi', () async {
      final result = await repository.login(
        email: 'ali@example.com',
        password: 'supersecret1',
      );

      expect(result.isRight(), isTrue);
      expect(local.token, isNotNull);
      expect(local.user, tUser);
      // Token `/me` dan oldin saqlanishi kerak, aks holda interceptor
      // Authorization sarlavhasini qo'sha olmaydi.
      expect(remote.getMeCalls, 1);
    });

    test('401 → UnauthorizedFailure', () async {
      build(
        customRemote: FakeRemote(
          onLogin: () async => throw const ServerException(
            statusCode: 401,
            message: 'Incorrect email or password',
          ),
        ),
      );

      final result = await repository.login(email: 'a@b.uz', password: 'x');

      expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
      expect(local.token, isNull);
    });

    test('403 → ForbiddenFailure (hisob bloklangan)', () async {
      build(
        customRemote: FakeRemote(
          onLogin: () async => throw const ServerException(
            statusCode: 403,
            message: 'Inactive account',
          ),
        ),
      );

      final result = await repository.login(email: 'a@b.uz', password: 'x');

      expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
    });

    test('tarmoq xatosi → NetworkFailure', () async {
      build(
        customRemote: FakeRemote(
          onLogin: () async => throw const NetworkException('yo’q'),
        ),
      );

      final result = await repository.login(email: 'a@b.uz', password: 'x');

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });
  });

  group('register', () {
    test('muvaffaqiyatli register darhol login qiladi', () async {
      final result = await repository.register(
        email: 'ali@example.com',
        password: 'supersecret1',
        fullName: 'Ali',
        timezone: 'Asia/Tashkent',
      );

      expect(result.isRight(), isTrue);
      expect(remote.registerCalls, 1);
      expect(remote.loginCalls, 1);
      expect(local.token, isNotNull);
    });

    test('409 → ConflictFailure va login chaqirilmaydi', () async {
      build(
        customRemote: FakeRemote(
          onRegister: () async => throw const ServerException(
            statusCode: 409,
            message: 'Email already registered',
          ),
        ),
      );

      final result = await repository.register(
        email: 'ali@example.com',
        password: 'supersecret1',
      );

      expect(result.fold((f) => f, (_) => null), isA<ConflictFailure>());
      expect(remote.loginCalls, 0);
    });

    test('422 → ValidationFailure maydon xatolari bilan', () async {
      build(
        customRemote: FakeRemote(
          onRegister: () async => throw const ServerException(
            statusCode: 422,
            message: 'validation',
            fieldErrors: {'password': 'too short'},
          ),
        ),
      );

      final result = await repository.register(
        email: 'ali@example.com',
        password: 'short',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ValidationFailure>());
      expect(failure!.fieldErrors['password'], 'too short');
    });
  });

  group('restoreSession', () {
    test('token yo’q → null', () async {
      final result = await repository.restoreSession();

      expect(result.fold((_) => null, (user) => user), isNull);
    });

    test(
      'access ham refresh ham eskirgan → tozalanadi, tarmoqqa chiqilmaydi',
      () async {
        local.token = tokenValidFor(
          const Duration(seconds: -10),
          refreshDuration: const Duration(seconds: -10),
        );

        final result = await repository.restoreSession();

        expect(result.fold((_) => null, (user) => user), isNull);
        expect(remote.getMeCalls, 0);
        expect(local.clearCalls, greaterThan(0));
      },
    );

    test('access eskirgan, refresh amal qiladi → /me chaqiriladi '
        '(interceptor refresh qiladi)', () async {
      local.token = tokenValidFor(
        const Duration(seconds: -10),
        refreshDuration: const Duration(days: 30),
      );

      final result = await repository.restoreSession();

      expect(result.fold((_) => null, (user) => user), tUser);
      expect(remote.getMeCalls, 1);
    });

    test('token amal qiladi → /me chaqiriladi va user qaytadi', () async {
      local.token = tokenValidFor(const Duration(hours: 1));

      final result = await repository.restoreSession();

      expect(result.fold((_) => null, (user) => user), tUser);
      expect(remote.getMeCalls, 1);
    });

    test('server 401 bersa sessiya tozalanadi', () async {
      build(
        customRemote: FakeRemote(
          onGetMe: () async =>
              throw const ServerException(statusCode: 401, message: 'expired'),
        ),
      );
      local.token = tokenValidFor(const Duration(hours: 1));

      final result = await repository.restoreSession();

      expect(result.fold((_) => null, (user) => user), isNull);
      expect(local.token, isNull);
    });

    test('internet yo’q bo’lsa cache’dagi user bilan davom etadi', () async {
      build(
        customRemote: FakeRemote(
          onGetMe: () async => throw const NetworkException('yo’q'),
        ),
      );
      local.token = tokenValidFor(const Duration(hours: 1));
      local.user = tUser;

      final result = await repository.restoreSession();

      expect(result.fold((_) => null, (user) => user), tUser);
      // Offline holatda tokenni o'chirib yubormaymiz.
      expect(local.token, isNotNull);
    });
  });

  group('logout', () {
    test(
      'serverga refresh token yuboriladi va lokal sessiya tozalanadi',
      () async {
        local.token = tokenValidFor(const Duration(hours: 1));
        local.user = tUser;

        final result = await repository.logout();

        expect(result.isRight(), isTrue);
        expect(remote.logoutCalls, 1);
        expect(remote.lastLogoutToken, 'refresh');
        expect(local.token, isNull);
        expect(local.user, isNull);
      },
    );
  });

  group('loginWithTelegram', () {
    test('token saqlanadi va profil olinadi', () async {
      final remote = FakeRemote();
      final local = FakeLocal();
      final repository = AuthRepositoryImpl(remote: remote, local: local);

      final result = await repository.loginWithTelegram(
        initData: 'query_id=1&hash=abc',
        timezone: 'Asia/Tashkent',
      );

      expect(result.isRight(), isTrue);
      expect(remote.lastInitData, 'query_id=1&hash=abc');
      expect(remote.getMeCalls, 1);
      expect(await local.getToken(), isNotNull);
    });
  });
}
