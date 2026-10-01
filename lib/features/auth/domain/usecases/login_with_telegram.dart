import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Telegram Mini App ichidan kirish. Birinchi kirishda hisob yaratiladi.
class LoginWithTelegram implements UseCase<User, TelegramLoginParams> {
  const LoginWithTelegram(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(TelegramLoginParams params) => _repository
      .loginWithTelegram(initData: params.initData, timezone: params.timezone);
}

class TelegramLoginParams extends Equatable {
  const TelegramLoginParams({required this.initData, this.timezone});

  /// `Telegram.WebApp.initData` — o'zgartirmasdan yuboriladi.
  final String initData;

  /// Faqat hisob yaratilganda ishlatiladi.
  final String? timezone;

  @override
  List<Object?> get props => [initData, timezone];
}
