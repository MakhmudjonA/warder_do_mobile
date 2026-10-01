import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/program.dart';

/// Dasturlar (AI planlar) kontrakti.
abstract class ProgramsRepository {
  /// AI matndan plan tayyorlaydi. Hech narsa saqlanmaydi — foydalanuvchi
  /// avval ko'rib tasdiqlaydi.
  Future<Either<Failure, ProgramPreview>> generate({
    required String prompt,
    int? durationDays,
  });

  /// Tasdiqlangan planni yangi odat bilan birga saqlaydi.
  Future<Either<Failure, Unit>> save({
    required ProgramPreview preview,
    required String startDate,
    required String habitTitle,
    required String habitIcon,
    required String habitColor,
  });
}
