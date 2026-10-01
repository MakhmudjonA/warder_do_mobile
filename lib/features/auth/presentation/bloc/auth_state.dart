part of 'auth_bloc.dart';

/// Foydalanuvchi kirganmi yoki yo'q.
///
/// [unknown] — splash bosqichi: hali tekshirilmagan. Router shu holatda
/// hech qayerga yo'naltirmaydi, aks holda login ekrani bir lahza "chaqnab"
/// ketadi.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Bitta state klassi (bir nechta state sinflari o'rniga): forma xatolari
/// va yuklanish indikatori autentifikatsiya holatidan mustaqil o'zgaradi,
/// shuning uchun ularni bir joyda ushlab turgan qulayroq.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.failure,
    this.successMessage,
    this.noticeId = 0,
    this.telegramLogin,
  });

  final AuthStatus status;
  final User? user;

  /// Forma yuborilib, javob kutilmoqda — tugma spinner ko'rsatadi.
  final bool isSubmitting;

  /// Oxirgi xatolik. UI undan `message` va `fieldErrors` ni oladi.
  final Failure? failure;

  /// Muvaffaqiyat xabari (masalan "Profil yangilandi").
  final String? successMessage;

  /// Har bir yangi xabar/xatolikda oshadi.
  ///
  /// Nima uchun kerak: bir xil xatolik ketma-ket ikki marta kelsa
  /// (`Equatable` bo'yicha state teng bo'lib qoladi va) `BlocListener`
  /// ishlamay qolardi. Bu hisoblagich har bir xabarni noyob qiladi.
  final int noticeId;

  /// "Войти через Telegram" kutilmoqda (telefon ilovasida). `null` — yo'q.
  final TelegramLoginTicket? telegramLogin;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Forma maydonlari ostidagi server xatolari: `{'email': '...'}`.
  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isSubmitting,
    Failure? failure,
    String? successMessage,
    int? noticeId,
    TelegramLoginTicket? telegramLogin,
    bool clearUser = false,
    bool clearNotice = false,
    bool clearTelegramLogin = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearNotice ? null : (failure ?? this.failure),
      successMessage: clearNotice
          ? null
          : (successMessage ?? this.successMessage),
      noticeId: noticeId ?? this.noticeId,
      telegramLogin: clearTelegramLogin
          ? null
          : (telegramLogin ?? this.telegramLogin),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isSubmitting,
    failure,
    successMessage,
    noticeId,
    telegramLogin,
  ];
}
