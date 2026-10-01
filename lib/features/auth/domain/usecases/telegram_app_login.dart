import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/telegram_login.dart';
import '../repositories/auth_repository.dart';

/// Telefon ilovasida "Войти через Telegram"ni boshlash. Parametr — qurilma
/// timezone'i (hisob yangi yaratilsa ishlatiladi).
class StartTelegramLogin implements UseCase<TelegramLoginTicket, String?> {
  const StartTelegramLogin(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, TelegramLoginTicket>> call(String? timezone) =>
      _repository.startTelegramLogin(timezone: timezone);
}

/// Bot'da tasdiqlandimi? Tasdiqlangan bo'lsa sessiya saqlanadi va user qaytadi.
class CheckTelegramLogin implements UseCase<TelegramLoginResult, String> {
  const CheckTelegramLogin(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, TelegramLoginResult>> call(String code) =>
      _repository.checkTelegramLogin(code);
}
