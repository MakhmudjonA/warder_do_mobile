import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/program.dart';
import '../repositories/programs_repository.dart';

/// AI plan tayyorlaydi (saqlamaydi).
class GenerateProgram
    implements UseCase<ProgramPreview, GenerateProgramParams> {
  const GenerateProgram(this._repository);

  final ProgramsRepository _repository;

  @override
  Future<Either<Failure, ProgramPreview>> call(GenerateProgramParams params) =>
      _repository.generate(
        prompt: params.prompt,
        durationDays: params.durationDays,
      );
}

class GenerateProgramParams extends Equatable {
  const GenerateProgramParams({required this.prompt, this.durationDays});

  final String prompt;

  /// `null` — foydalanuvchi aniq bermagan, uzunlikni AI o'zi aniqlaydi.
  final int? durationDays;

  @override
  List<Object?> get props => [prompt, durationDays];
}

/// Tasdiqlangan planni saqlaydi.
class SaveProgram implements UseCase<Unit, SaveProgramParams> {
  const SaveProgram(this._repository);

  final ProgramsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveProgramParams params) =>
      _repository.save(
        preview: params.preview,
        startDate: params.startDate,
        habitTitle: params.habitTitle,
        habitIcon: params.habitIcon,
        habitColor: params.habitColor,
      );
}

class SaveProgramParams extends Equatable {
  const SaveProgramParams({
    required this.preview,
    required this.startDate,
    required this.habitTitle,
    required this.habitIcon,
    required this.habitColor,
  });

  final ProgramPreview preview;
  final String startDate;
  final String habitTitle;
  final String habitIcon;
  final String habitColor;

  @override
  List<Object?> get props => [
    preview,
    startDate,
    habitTitle,
    habitIcon,
    habitColor,
  ];
}
