import 'package:equatable/equatable.dart';

import 'user.dart';

/// "Войти через Telegram" urinishi (telefon ilovasida).
///
/// [code] — maxfiy, serverdan holatni so'rash uchun. [displayCode] — ekranda
/// ko'rsatiladi; bot ham xuddi shu raqamni ko'rsatadi, foydalanuvchi ularni
/// solishtirib tasdiqlaydi (begona havola bilan kirib qolmaslik uchun).
class TelegramLoginTicket extends Equatable {
  const TelegramLoginTicket({
    required this.code,
    required this.displayCode,
    required this.botUrl,
    required this.expiresAt,
  });

  final String code;
  final String displayCode;

  /// `https://t.me/<bot>?start=login_<code>` — Telegram'da ochiladi.
  final String botUrl;

  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [code, displayCode, botUrl, expiresAt];
}

enum TelegramLoginStatus { pending, confirmed, cancelled, expired }

class TelegramLoginResult extends Equatable {
  const TelegramLoginResult(this.status, [this.user]);

  final TelegramLoginStatus status;

  /// Faqat [TelegramLoginStatus.confirmed] da.
  final User? user;

  @override
  List<Object?> get props => [status, user];
}
