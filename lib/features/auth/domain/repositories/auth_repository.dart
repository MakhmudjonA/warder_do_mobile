import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/telegram_login.dart';

/// Auth bo'yicha domain kontrakti.
///
/// Domain qatlami **faqat shu interfeysni** biladi. Dio, secure storage va
/// JSON — hammasi `data` qatlamidagi implementatsiyada qoladi. Shu sabab
/// backendni almashtirish yoki testda soxta repository berish oson.
abstract class AuthRepository {
  /// Yangi hisob yaratadi va darhol login qiladi.
  ///
  /// Backend `/register` token qaytarmaydi, shuning uchun implementatsiya
  /// register'dan keyin `/login` ni o'zi chaqiradi — mobil ilovada
  /// foydalanuvchini ikki marta parol yozishga majburlash mantiqsiz.
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? fullName,
    String? timezone,
  });

  /// Email + parol bilan kirish. Token saqlanadi, `/me` orqali user olinadi.
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Telegram Mini App ichidan kirish (email/parolsiz).
  Future<Either<Failure, User>> loginWithTelegram({
    required String initData,
    String? timezone,
  });

  /// Telefon ilovasi: "Войти через Telegram" — bot orqali tasdiqlash.
  Future<Either<Failure, TelegramLoginTicket>> startTelegramLogin({
    String? timezone,
  });

  /// Tasdiqlangan bo'lsa sessiya saqlanadi va [TelegramLoginResult.user] keladi.
  Future<Either<Failure, TelegramLoginResult>> checkTelegramLogin(String code);

  /// `GET /auth/me` — serverdagi eng so'nggi holat.
  Future<Either<Failure, User>> getCurrentUser();

  /// `PATCH /auth/me` — faqat berilgan maydonlar o'zgaradi.
  Future<Either<Failure, User>> updateProfile({
    String? fullName,
    String? timezone,
    int? taskRemindBefore,
  });

  /// Tokenni va cache'ni o'chiradi.
  ///
  /// Stateless JWT'ni serverdan bekor qilib bo'lmaydi — "chiqish" degani
  /// clientdagi tokenni o'chirish. Token muddati tugaguncha u texnik jihatdan
  /// amal qiladi, lekin bizda nusxasi qolmaydi.
  Future<Either<Failure, Unit>> logout();

  /// Ilova ochilganda: saqlangan token bormi va u hali amal qiladimi?
  ///
  /// `null` — sessiya yo'q, login ekrani kerak.
  Future<Either<Failure, User?>> restoreSession();

  /// Cache'dagi user (tarmoqqa chiqmasdan). Splash'da tez ko'rsatish uchun.
  Future<Either<Failure, User?>> getCachedUser();
}
