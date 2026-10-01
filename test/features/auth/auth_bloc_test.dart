import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warder_do_mobile/core/constants/app_strings.dart';
import 'package:warder_do_mobile/core/error/failures.dart';
import 'package:warder_do_mobile/core/network/session_notifier.dart';
import 'package:warder_do_mobile/core/telegram/telegram_platform.dart';
import 'package:warder_do_mobile/features/auth/domain/entities/user.dart';
import 'package:warder_do_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/login_with_telegram.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/register_user.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/update_profile.dart';
import 'package:warder_do_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warder_do_mobile/features/auth/domain/entities/telegram_login.dart';
import 'package:warder_do_mobile/features/auth/domain/usecases/telegram_app_login.dart';

final tUser = User(
  id: 'id-1',
  email: 'ali@example.com',
  fullName: 'Ali',
  isActive: true,
  timezone: 'Asia/Tashkent',
  createdAt: DateTime.utc(2026, 9, 3),
);

final tTelegramUser = User(
  id: 'id-tg',
  telegramId: 777,
  fullName: 'Ali',
  isActive: true,
  timezone: 'Asia/Tashkent',
  createdAt: DateTime.utc(2026, 9, 3),
);

/// Telegram ichida ochilgan Mini App'ning soxtasi.
class FakeTelegram extends NoTelegram {
  const FakeTelegram({this.id = 777});

  final int id;

  @override
  bool get isAvailable => true;

  @override
  String get initData => 'query_id=1&hash=abc';

  @override
  int? get userId => id;
}

/// Domain kontraktining soxta implementatsiyasi — bloc uchun shu kifoya.
class FakeAuthRepository implements AuthRepository {
  Either<Failure, User> loginResult = Right(tUser);
  Either<Failure, User> registerResult = Right(tUser);
  Either<Failure, User> currentUserResult = Right(tUser);
  Either<Failure, User> updateResult = Right(tUser);
  Either<Failure, User?> restoreResult = Right(tUser);

  int logoutCalls = 0;

  Either<Failure, User> telegramResult = Right(tTelegramUser);
  int telegramCalls = 0;
  String? lastTimezone;

  @override
  Future<Either<Failure, User>> loginWithTelegram({
    required String initData,
    String? timezone,
  }) async {
    telegramCalls++;
    lastTimezone = timezone;
    return telegramResult;
  }

  Either<Failure, TelegramLoginTicket> ticketResult = Right(
    TelegramLoginTicket(
      code: 'secret',
      displayCode: '4821',
      botUrl: 'https://t.me/warder_do_bot?start=login_secret',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    ),
  );
  final List<Either<Failure, TelegramLoginResult>> pollResults = [];
  int pollCalls = 0;

  @override
  Future<Either<Failure, TelegramLoginTicket>> startTelegramLogin({
    String? timezone,
  }) async => ticketResult;

  @override
  Future<Either<Failure, TelegramLoginResult>> checkTelegramLogin(
    String code,
  ) async {
    pollCalls++;
    return pollResults.isEmpty
        ? const Right(TelegramLoginResult(TelegramLoginStatus.pending))
        : pollResults.removeAt(0);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  }) async => registerResult;

  @override
  Future<Either<Failure, User>> getCurrentUser() async => currentUserResult;

  @override
  Future<Either<Failure, User>> updateProfile({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  }) async => updateResult;

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User?>> restoreSession() async => restoreResult;

  @override
  Future<Either<Failure, User?>> getCachedUser() async => Right(tUser);
}

void main() {
  late FakeAuthRepository repository;
  late SessionNotifier sessionNotifier;
  late AuthBloc bloc;

  setUp(() {
    repository = FakeAuthRepository();
    sessionNotifier = SessionNotifier();
    bloc = AuthBloc(
      registerUser: RegisterUser(repository),
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      getCurrentUser: GetCurrentUser(repository),
      updateProfile: UpdateProfile(repository),
      restoreSession: RestoreSession(repository),
      sessionNotifier: sessionNotifier,
    );
  });

  tearDown(() async {
    await bloc.close();
    await sessionNotifier.dispose();
  });

  test('boshlang’ich holat unknown', () {
    expect(bloc.state.status, AuthStatus.unknown);
    expect(bloc.state.user, isNull);
  });

  group('AuthStarted', () {
    test('sessiya bor → authenticated', () async {
      bloc.add(const AuthStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.status == AuthStatus.authenticated && s.user == tUser,
          ),
        ),
      );
    });

    test('sessiya yo’q → unauthenticated', () async {
      repository.restoreResult = const Right(null);
      bloc.add(const AuthStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
        ),
      );
    });

    test('xatolik bo’lsa ham foydalanuvchini bezovta qilmaydi', () async {
      repository.restoreResult = const Left(NetworkFailure());
      bloc.add(const AuthStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.status == AuthStatus.unauthenticated && s.failure == null,
          ),
        ),
      );
    });
  });

  group('AuthLoginSubmitted', () {
    test('muvaffaqiyat: isSubmitting → authenticated', () async {
      bloc.add(
        const AuthLoginSubmitted(
          email: 'ali@example.com',
          password: 'supersecret1',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.isSubmitting),
          predicate<AuthState>(
            (s) =>
                !s.isSubmitting &&
                s.status == AuthStatus.authenticated &&
                s.user == tUser,
          ),
        ]),
      );
    });

    test('xato parol: failure va noticeId oshadi', () async {
      repository.loginResult = const Left(UnauthorizedFailure());

      bloc.add(
        const AuthLoginSubmitted(email: 'ali@example.com', password: 'x'),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                !s.isSubmitting &&
                s.failure is UnauthorizedFailure &&
                s.noticeId == 1 &&
                s.status != AuthStatus.authenticated,
          ),
        ),
      );
    });

    test('bir xil xatolik ikki marta kelsa noticeId farqlanadi', () async {
      repository.loginResult = const Left(UnauthorizedFailure());

      bloc.add(const AuthLoginSubmitted(email: 'a@b.uz', password: 'x'));
      await bloc.stream.firstWhere((s) => s.noticeId == 1);

      bloc.add(const AuthLoginSubmitted(email: 'a@b.uz', password: 'x'));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.noticeId == 2)),
      );
    });
  });

  group('AuthRegisterSubmitted', () {
    test('422 xatosida maydon xatolari state’ga tushadi', () async {
      repository.registerResult = const Left(
        ValidationFailure(fieldErrors: {'password': 'too short'}),
      );

      bloc.add(const AuthRegisterSubmitted(email: 'a@b.uz', password: 'short'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>((s) => s.fieldErrors['password'] == 'too short'),
        ),
      );
    });
  });

  group('AuthProfileUpdated', () {
    test('muvaffaqiyatda success xabari chiqadi', () async {
      repository.updateResult = Right(tUser.copyWith(timezone: 'UTC'));

      bloc.add(const AuthProfileUpdated(timezone: 'UTC'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.successMessage != null &&
                s.user?.timezone == 'UTC' &&
                !s.isSubmitting,
          ),
        ),
      );
    });
  });

  group('sessiya tugashi', () {
    test('SessionNotifier signal bersa unauthenticated bo’ladi', () async {
      bloc.add(const AuthStarted());
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

      sessionNotifier.notifyExpired();

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.status == AuthStatus.unauthenticated && s.failure != null,
          ),
        ),
      );
    });
  });

  group('AuthLogoutRequested', () {
    test('repository chaqiriladi va holat tozalanadi', () async {
      bloc.add(const AuthStarted());
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

      bloc.add(const AuthLogoutRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.status == AuthStatus.unauthenticated && s.user == null,
          ),
        ),
      );
      expect(repository.logoutCalls, 1);
    });
  });

  group('Telegram Mini App', () {
    AuthBloc telegramBloc({int telegramUserId = 777}) => AuthBloc(
      registerUser: RegisterUser(repository),
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      getCurrentUser: GetCurrentUser(repository),
      updateProfile: UpdateProfile(repository),
      restoreSession: RestoreSession(repository),
      sessionNotifier: sessionNotifier,
      loginWithTelegram: LoginWithTelegram(repository),
      telegram: FakeTelegram(id: telegramUserId),
      resolveTimezone: () async => 'Asia/Tashkent',
    );

    test('sessiya yo‘q → Telegram orqali avtomatik kiradi', () async {
      repository.restoreResult = const Right(null);
      final tg = telegramBloc()..add(const AuthStarted());

      await expectLater(
        tg.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.authenticated && s.user == tTelegramUser,
          ),
        ),
      );
      expect(repository.lastTimezone, 'Asia/Tashkent');
      await tg.close();
    });

    test('shu Telegram hisobining sessiyasi bo‘lsa — qayta kirmaydi', () async {
      repository.restoreResult = Right(tTelegramUser);
      final tg = telegramBloc()..add(const AuthStarted());

      await tg.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
      expect(repository.telegramCalls, 0);
      await tg.close();
    });

    test('boshqa Telegram hisobining sessiyasi → almashtiriladi', () async {
      repository.restoreResult = Right(tTelegramUser);
      final tg = telegramBloc(telegramUserId: 999)..add(const AuthStarted());

      await tg.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
      expect(repository.telegramCalls, 1);
      await tg.close();
    });

    test('Telegram ichida email bilan kirgan sessiyaga tegilmaydi', () async {
      repository.restoreResult = Right(tUser);
      final tg = telegramBloc()..add(const AuthStarted());

      final state = await tg.stream.firstWhere(
        (s) => s.status == AuthStatus.authenticated,
      );
      expect(state.user, tUser);
      expect(repository.telegramCalls, 0);
      await tg.close();
    });

    test('xato bo‘lsa Welcome + xabar', () async {
      repository.restoreResult = const Right(null);
      repository.telegramResult = const Left(UnauthorizedFailure('bad'));
      final tg = telegramBloc()..add(const AuthStarted());

      final state = await tg.stream.firstWhere(
        (s) => s.status == AuthStatus.unauthenticated,
      );
      expect(state.failure, isA<UnauthorizedFailure>());
      await tg.close();
    });

    test('Telegram tashqarisida hech narsa o‘zgarmaydi', () async {
      repository.restoreResult = const Right(null);
      bloc.add(const AuthStarted());

      await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.unauthenticated,
      );
      expect(repository.telegramCalls, 0);
    });
  });

  group('Telefon: Войти через Telegram', () {
    AuthBloc phoneBloc() => AuthBloc(
      registerUser: RegisterUser(repository),
      loginUser: LoginUser(repository),
      logoutUser: LogoutUser(repository),
      getCurrentUser: GetCurrentUser(repository),
      updateProfile: UpdateProfile(repository),
      restoreSession: RestoreSession(repository),
      sessionNotifier: sessionNotifier,
      resolveTimezone: () async => 'Asia/Tashkent',
      startTelegramLogin: StartTelegramLogin(repository),
      checkTelegramLogin: CheckTelegramLogin(repository),
      telegramPollInterval: const Duration(milliseconds: 1),
    );

    test('kod ko‘rsatiladi, tasdiqlangach kiradi', () async {
      repository.pollResults.addAll([
        const Right(TelegramLoginResult(TelegramLoginStatus.pending)),
        Right(
          TelegramLoginResult(TelegramLoginStatus.confirmed, tTelegramUser),
        ),
      ]);
      final b = phoneBloc()..add(const AuthTelegramAppLoginStarted());

      await b.stream.firstWhere((s) => s.telegramLogin?.displayCode == '4821');
      final done = await b.stream.firstWhere(
        (s) => s.status == AuthStatus.authenticated,
      );
      expect(done.user, tTelegramUser);
      expect(done.telegramLogin, isNull);
      expect(repository.pollCalls, 2);
      await b.close();
    });

    test('Отмена — so‘rash to‘xtaydi', () async {
      final b = phoneBloc()..add(const AuthTelegramAppLoginStarted());
      await b.stream.firstWhere((s) => s.telegramLogin != null);

      b.add(const AuthTelegramAppLoginCancelled());
      await b.stream.firstWhere((s) => s.telegramLogin == null);
      final calls = repository.pollCalls;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.pollCalls, calls, reason: 'polling stopped');
      await b.close();
    });

    test('botda bekor qilinsa — xabar va kutish tugaydi', () async {
      repository.pollResults.add(
        const Right(TelegramLoginResult(TelegramLoginStatus.cancelled)),
      );
      final b = phoneBloc()..add(const AuthTelegramAppLoginStarted());

      final ended = await b.stream.firstWhere(
        (s) => s.failure != null && s.telegramLogin == null,
      );
      expect(ended.failure!.message, AppStrings.telegramLoginCancelled);
      expect(ended.status, isNot(AuthStatus.authenticated));
      await b.close();
    });

    test('internet uzilsa — kutishda davom etadi', () async {
      repository.pollResults.addAll([
        const Left(NetworkFailure()),
        Right(
          TelegramLoginResult(TelegramLoginStatus.confirmed, tTelegramUser),
        ),
      ]);
      final b = phoneBloc()..add(const AuthTelegramAppLoginStarted());

      await b.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
      await b.close();
    });
  });
}
