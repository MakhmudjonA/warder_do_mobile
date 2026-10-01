import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';
import '../../domain/entities/telegram_login.dart';

/// Domain kontraktining yagona implementatsiyasi.
///
/// Vazifasi: remote va local manbalarni muvofiqlashtirish va **barcha**
/// exception'larni [Failure] ga aylantirish. Bu qatlamdan yuqoriga
/// hech qachon exception chiqmasligi kerak.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  }) {
    return guardApi(() async {
      await _remote.register(
        email: email,
        password: password,
        fullName: fullName,
        timezone: timezone,
      );
      // Backend `/register` token qaytarmaydi — darhol login qilamiz,
      // shunda foydalanuvchi parolni ikkinchi marta yozmaydi.
      return _authenticate(email: email, password: password);
    });
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) {
    return guardApi(() => _authenticate(email: email, password: password));
  }

  @override
  Future<Either<Failure, User>> loginWithTelegram({
    required String initData,
    String? timezone,
  }) {
    return guardApi(() async {
      final token = await _remote.loginWithTelegram(
        initData: initData,
        timezone: timezone,
      );
      return _startSession(token);
    });
  }

  @override
  Future<Either<Failure, TelegramLoginTicket>> startTelegramLogin({
    String? timezone,
  }) => guardApi(() => _remote.requestTelegramLogin(timezone: timezone));

  @override
  Future<Either<Failure, TelegramLoginResult>> checkTelegramLogin(String code) {
    return guardApi(() async {
      final (status, token) = await _remote.pollTelegramLogin(code);
      if (status != TelegramLoginStatus.confirmed || token == null) {
        return TelegramLoginResult(
          status == TelegramLoginStatus.confirmed
              ? TelegramLoginStatus.cancelled
              : status,
        );
      }
      return TelegramLoginResult(status, await _startSession(token));
    });
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() {
    return guardApi(() async {
      final user = await _remote.getMe();
      await _local.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  }) {
    return guardApi(() async {
      final user = await _remote.updateMe(
        fullName: fullName,
        timezone: timezone,
        taskRemindBefore: taskRemindBefore,
      );
      await _local.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    // Refresh tokenni serverda bekor qilamiz (best-effort) — shu qurilma
    // sessiyasi o'chadi. Internet bo'lmasa ham lokal chiqishni to'xtatmaymiz.
    try {
      final refreshToken = await _local.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remote.logout(refreshToken);
      }
    } on Exception catch (_) {
      // Serverga yetib bormasa mayli — lokal tokenlarni baribir o'chiramiz.
    }
    await _local.clearSession();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User?>> restoreSession() async {
    try {
      final token = await _local.getToken();
      // Na access, na refresh amal qilsa — sessiyani tiklab bo'lmaydi.
      if (token == null || (token.isExpired && token.isRefreshExpired)) {
        await _local.clearSession();
        return const Right(null);
      }

      // Access eskirgan bo'lsa ham `/me` ni chaqiramiz — interceptor kerak
      // bo'lganda avval `/auth/refresh` qiladi. Refresh ham o'lik bo'lsa,
      // 401 qaytadi va quyidagi `catch` sessiyani tozalaydi.

      // Token bor — lekin foydalanuvchi bloklangan yoki o'chirilgan bo'lishi
      // mumkin. Yagona ishonchli tekshiruv — `/me`.
      final user = await _remote.getMe();
      await _local.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _local.clearSession();
        return const Right(null);
      }
      return Left(mapServerException(e));
    } on NetworkException {
      // Internet yo'q — cache'dagi user bilan offline ishlashga ruxsat beramiz.
      return Right(await _safeCachedUser());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> getCachedUser() async {
    try {
      return Right(await _local.getUser());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // --- Ichki yordamchilar ---

  /// Login qilib, tokenni saqlaydi va profilni oladi.
  Future<UserModel> _authenticate({
    required String email,
    required String password,
  }) async {
    final token = await _remote.login(email: email, password: password);
    return _startSession(token);
  }

  /// Tokenni saqlab, profilni oladi — login'ning har qanday turi uchun.
  Future<UserModel> _startSession(AuthTokenModel token) async {
    // Tokenni `/me` dan **oldin** saqlaymiz — interceptor uni o'sha so'rovga
    // qo'shishi kerak.
    await _local.cacheToken(token);
    final user = await _remote.getMe();
    await _local.cacheUser(user);
    return user;
  }

  Future<UserModel?> _safeCachedUser() async {
    try {
      return await _local.getUser();
    } on CacheException {
      return null;
    }
  }
}
