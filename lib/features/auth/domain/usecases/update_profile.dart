import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// `PATCH /auth/me`. Faqat `null` bo'lmagan maydonlar yuboriladi.
class UpdateProfile implements UseCase<User, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      fullName: params.fullName,
      timezone: params.timezone,
      taskRemindBefore: params.taskRemindBefore,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    this.fullName,
    this.timezone,
    this.taskRemindBefore,
  });

  final String? fullName;
  final String? timezone;

  /// `-1` — server standartiga qaytarish.
  final int? taskRemindBefore;

  bool get isEmpty =>
      fullName == null && timezone == null && taskRemindBefore == null;

  @override
  List<Object?> get props => [fullName, timezone, taskRemindBefore];
}
