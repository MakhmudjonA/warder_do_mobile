part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Ilova ishga tushdi — saqlangan sessiyani tekshiramiz.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Telegram Mini App ichida "Войти через Telegram" bosildi (odatda kirish
/// avtomatik bo'ladi — bu tugma faqat xatodan keyin qayta urinish uchun).
class AuthTelegramRequested extends AuthEvent {
  const AuthTelegramRequested();
}

/// Telefon ilovasida "Войти через Telegram" bosildi.
class AuthTelegramAppLoginStarted extends AuthEvent {
  const AuthTelegramAppLoginStarted();
}

/// Kutish oynasida "Отмена".
class AuthTelegramAppLoginCancelled extends AuthEvent {
  const AuthTelegramAppLoginCancelled();
}

class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({
    required this.email,
    required this.password,
    this.fullName,
    this.timezone,
  });

  final String email;
  final String password;
  final String? fullName;
  final String? timezone;

  @override
  List<Object?> get props => [email, password, fullName, timezone];
}

class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated({
    this.fullName,
    this.timezone,
    this.taskRemindBefore,
  });

  final String? fullName;
  final String? timezone;

  /// `-1` — server standartiga qaytarish.
  final int? taskRemindBefore;

  @override
  List<Object?> get props => [fullName, timezone, taskRemindBefore];
}

/// `/auth/me` ni qayta so'raydi (pull-to-refresh, ilova fon'dan qaytganda).
class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Interceptor 401 ko'rdi — token eskirgan.
///
/// Foydalanuvchi hech narsa bosmagan bo'lsa ham chaqirilishi mumkin.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

/// Snackbar ko'rsatilgandan keyin xabarni tozalash.
class AuthNoticeCleared extends AuthEvent {
  const AuthNoticeCleared();
}
