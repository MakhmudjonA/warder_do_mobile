part of 'program_import_bloc.dart';

sealed class ProgramImportEvent extends Equatable {
  const ProgramImportEvent();

  @override
  List<Object?> get props => [];
}

/// Foydalanuvchi matn kiritib "Yaratish" bosdi.
class ProgramGenerateRequested extends ProgramImportEvent {
  const ProgramGenerateRequested({required this.prompt, this.durationDays});

  final String prompt;

  /// `null` — uzunlikni AI o'zi aniqlaydi.
  final int? durationDays;

  @override
  List<Object?> get props => [prompt, durationDays];
}

/// Preview tasdiqlandi — saqlaymiz.
class ProgramSaveRequested extends ProgramImportEvent {
  const ProgramSaveRequested({
    required this.habitTitle,
    required this.habitIcon,
    required this.habitColor,
    required this.startDate,
  });

  final String habitTitle;
  final String habitIcon;
  final String habitColor;
  final String startDate;

  @override
  List<Object?> get props => [habitTitle, habitIcon, habitColor, startDate];
}

/// Boshidan boshlash (masalan yangi matn yozish uchun).
class ProgramImportRestarted extends ProgramImportEvent {
  const ProgramImportRestarted();
}
