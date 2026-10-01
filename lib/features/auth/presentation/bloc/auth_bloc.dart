import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/session_notifier.dart';
import '../../../../core/telegram/telegram_platform.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/device_timezone.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/login_with_telegram.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/restore_session.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/usecases/telegram_app_login.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Butun ilovadagi autentifikatsiya holati.
///
/// Bitta global instansiya sifatida `MultiBlocProvider` da beriladi —
/// router ham, profil ekrani ham shu bloc'ga qaraydi.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RegisterUser registerUser,
    required LoginUser loginUser,
    required LogoutUser logoutUser,
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
    required RestoreSession restoreSession,
    required SessionNotifier sessionNotifier,
    LoginWithTelegram? loginWithTelegram,
    TelegramPlatform telegram = const NoTelegram(),
    Future<String> Function() resolveTimezone = DeviceTimezone.resolve,
    StartTelegramLogin? startTelegramLogin,
    CheckTelegramLogin? checkTelegramLogin,
    Duration telegramPollInterval = const Duration(seconds: 2),
  }) : _registerUser = registerUser,
       _loginUser = loginUser,
       _logoutUser = logoutUser,
       _getCurrentUser = getCurrentUser,
       _updateProfile = updateProfile,
       _restoreSession = restoreSession,
       _loginWithTelegram = loginWithTelegram,
       _telegram = telegram,
       _resolveTimezone = resolveTimezone,
       _startTelegramLogin = startTelegramLogin,
       _checkTelegramLogin = checkTelegramLogin,
       _telegramPollInterval = telegramPollInterval,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(_onLogin);
    on<AuthRegisterSubmitted>(_onRegister);
    on<AuthTelegramRequested>(_onTelegramRequested);
    on<AuthTelegramAppLoginStarted>(_onTelegramAppLoginStarted);
    on<AuthTelegramAppLoginCancelled>(
      (event, emit) => emit(state.copyWith(clearTelegramLogin: true)),
    );
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthUserRefreshed>(_onUserRefreshed);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthNoticeCleared>(_onNoticeCleared);

    // Interceptor 401 ko'rsa shu yerdan xabar keladi.
    _expirySubscription = sessionNotifier.onSessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
  }

  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final LogoutUser _logoutUser;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final RestoreSession _restoreSession;
  final LoginWithTelegram? _loginWithTelegram;
  final TelegramPlatform _telegram;
  final Future<String> Function() _resolveTimezone;
  final StartTelegramLogin? _startTelegramLogin;
  final CheckTelegramLogin? _checkTelegramLogin;
  final Duration _telegramPollInterval;

  /// Telegram ichida va kirish use case'i berilgan bo'lsa — avtomatik kirish.
  bool get _canUseTelegram =>
      _telegram.isAvailable && _loginWithTelegram != null;

  late final StreamSubscription<void> _expirySubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.unknown, clearNotice: true));

    final result = await _restoreSession(const NoParams());

    // Telegram ichida foydalanuvchidan hech narsa so'ramaymiz: sessiya yo'q
    // bo'lsa yoki u boshqa Telegram hisobiga tegishli bo'lsa — Telegram
    // orqali kiramiz. Telegram ichida ataylab email bilan kirgan
    // foydalanuvchining sessiyasiga tegilmaydi.
    if (_canUseTelegram) {
      final restored = result.fold((_) => null, (user) => user);
      final otherTelegramAccount =
          restored?.telegramId != null &&
          restored!.telegramId != _telegram.userId;
      if (restored == null || otherTelegramAccount) {
        await _signInWithTelegram(emit, quiet: true);
        return;
      }
    }

    result.fold(
      (failure) => emit(
        // Sessiyani tiklab bo'lmadi — login ekrani. Xatolikni ko'rsatmaymiz:
        // ilova ochilishida snackbar chiqarish bezovta qiladi.
        state.copyWith(status: AuthStatus.unauthenticated, clearUser: true),
      ),
      (user) => emit(
        user == null
            ? state.copyWith(
                status: AuthStatus.unauthenticated,
                clearUser: true,
              )
            : state.copyWith(status: AuthStatus.authenticated, user: user),
      ),
    );
  }

  Future<void> _onLogin(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearNotice: true));

    final result = await _loginUser(
      LoginParams(email: event.email, password: event.password),
    );

    _emitAuthResult(result, emit);
  }

  Future<void> _onTelegramRequested(
    AuthTelegramRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_canUseTelegram) return;
    emit(state.copyWith(isSubmitting: true, clearNotice: true));
    await _signInWithTelegram(emit, quiet: false);
  }

  /// [quiet] — ilova ochilishida: xato bo'lsa ham splash'dan Welcome'ga
  /// o'tamiz, lekin xabarni baribir ko'rsatamiz (u yerda "Войти через
  /// Telegram" tugmasi bor).
  Future<void> _signInWithTelegram(
    Emitter<AuthState> emit, {
    required bool quiet,
  }) async {
    final result = await _loginWithTelegram!(
      TelegramLoginParams(
        initData: _telegram.initData,
        timezone: await _resolveTimezone(),
      ),
    );

    result.fold(
      (failure) => emit(
        quiet
            ? AuthState(
                status: AuthStatus.unauthenticated,
                failure: failure,
                noticeId: state.noticeId + 1,
              )
            : _withFailure(failure),
      ),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  /// Telefon ilovasi: kod olamiz, bot'da tasdiqlanishini kutamiz (so'rab
  /// turamiz). "Отмена" [TelegramLoginTicket] ni tozalaydi — sikl to'xtaydi.
  Future<void> _onTelegramAppLoginStarted(
    AuthTelegramAppLoginStarted event,
    Emitter<AuthState> emit,
  ) async {
    final start = _startTelegramLogin;
    final check = _checkTelegramLogin;
    if (start == null || check == null || state.telegramLogin != null) return;

    emit(state.copyWith(isSubmitting: true, clearNotice: true));
    final started = await start(await _resolveTimezone());
    final ticket = started.fold((failure) {
      emit(_withFailure(failure));
      return null;
    }, (ticket) => ticket);
    if (ticket == null) return;

    emit(state.copyWith(isSubmitting: false, telegramLogin: ticket));

    while (!isClosed && state.telegramLogin == ticket) {
      await Future<void>.delayed(_telegramPollInterval);
      if (isClosed || state.telegramLogin != ticket) return; // bekor qilindi

      if (ticket.isExpired) {
        emit(_telegramLoginEnded(AppStrings.telegramLoginExpired));
        return;
      }

      final result = await check(ticket.code);
      final done = result.fold(
        (failure) {
          // Internet bir lahza uzilsa — kutishda davom etamiz.
          if (failure is NetworkFailure) return false;
          emit(_telegramLoginEnded(failure.message));
          return true;
        },
        (value) {
          switch (value.status) {
            case TelegramLoginStatus.pending:
              return false;
            case TelegramLoginStatus.confirmed:
              emit(
                AuthState(status: AuthStatus.authenticated, user: value.user),
              );
            case TelegramLoginStatus.cancelled:
              emit(_telegramLoginEnded(AppStrings.telegramLoginCancelled));
            case TelegramLoginStatus.expired:
              emit(_telegramLoginEnded(AppStrings.telegramLoginExpired));
          }
          return true;
        },
      );
      if (done) return;
    }
  }

  AuthState _telegramLoginEnded(String message) => state.copyWith(
    isSubmitting: false,
    failure: UnauthorizedFailure(message),
    noticeId: state.noticeId + 1,
    clearTelegramLogin: true,
  );

  Future<void> _onRegister(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearNotice: true));

    final result = await _registerUser(
      RegisterParams(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        timezone: event.timezone,
      ),
    );

    _emitAuthResult(result, emit);
  }

  Future<void> _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearNotice: true));

    final result = await _updateProfile(
      UpdateProfileParams(
        fullName: event.fullName,
        timezone: event.timezone,
        taskRemindBefore: event.taskRemindBefore,
      ),
    );

    result.fold(
      (failure) => emit(_withFailure(failure)),
      (user) => emit(
        state.copyWith(
          isSubmitting: false,
          user: user,
          status: AuthStatus.authenticated,
          successMessage: AppStrings.profileSaved,
          noticeId: state.noticeId + 1,
        ),
      ),
    );
  }

  Future<void> _onUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUser(const NoParams());

    result.fold(
      (failure) {
        // 401/403 bo'lsa interceptor allaqachon AuthSessionExpired yuboradi.
        // Qolgan xatolarda ekrandagi ma'lumotni buzmaymiz — jimgina o'tamiz.
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          emit(_loggedOutState(AppStrings.errSessionExpired));
        }
      },
      (user) =>
          emit(state.copyWith(user: user, status: AuthStatus.authenticated)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUser(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) {
    // Allaqachon chiqib bo'lgan bo'lsa qayta xabar bermaymiz.
    if (state.status == AuthStatus.unauthenticated) return;
    emit(_loggedOutState(AppStrings.errSessionExpired));
  }

  void _onNoticeCleared(AuthNoticeCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearNotice: true));
  }

  // --- Yordamchilar ---

  /// Login va register natijasi bir xil ko'rinishda qayta ishlanadi.
  void _emitAuthResult(Either<Failure, User> result, Emitter<AuthState> emit) {
    result.fold(
      (failure) => emit(_withFailure(failure)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  AuthState _withFailure(Failure failure) => state.copyWith(
    isSubmitting: false,
    failure: failure,
    noticeId: state.noticeId + 1,
  );

  AuthState _loggedOutState(String message) => AuthState(
    status: AuthStatus.unauthenticated,
    failure: UnauthorizedFailure(message),
    noticeId: state.noticeId + 1,
  );

  @override
  Future<void> close() {
    _expirySubscription.cancel();
    return super.close();
  }
}
