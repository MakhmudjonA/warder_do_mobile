import 'package:equatable/equatable.dart';

/// Mashq kunidagi yuklama turi.
enum ProgramTargetType { reps, staticHold, amrap, test }

/// Bitta mashq kunining maqsadi (podxod/takror/statika/test).
class ProgramTarget extends Equatable {
  const ProgramTarget({
    required this.type,
    this.sets,
    this.repsMin,
    this.repsMax,
    this.restSeconds,
    this.holdSecondsMin,
    this.holdSecondsMax,
  });

  final ProgramTargetType type;
  final int? sets;
  final int? repsMin;
  final int? repsMax;
  final int? restSeconds;
  final int? holdSecondsMin;
  final int? holdSecondsMax;

  @override
  List<Object?> get props => [
    type,
    sets,
    repsMin,
    repsMax,
    restSeconds,
    holdSecondsMin,
    holdSecondsMax,
  ];
}

/// Dasturdagi bitta kun. Dam kunida [isRest] `true`, [target] `null`.
class ProgramDay extends Equatable {
  const ProgramDay({
    required this.dayNumber,
    required this.isRest,
    this.target,
    this.note,
  });

  final int dayNumber;
  final bool isRest;
  final ProgramTarget? target;
  final String? note;

  @override
  List<Object?> get props => [dayNumber, isRest, target, note];
}

/// AI (yoki qo'lda) tayyorlangan, hali **saqlanmagan** dastur ko'rinishi.
class ProgramPreview extends Equatable {
  const ProgramPreview({
    required this.title,
    required this.description,
    required this.durationDays,
    required this.days,
    this.disclaimer,
    this.startDate,
  });

  final String title;
  final String description;
  final int durationDays;
  final List<ProgramDay> days;

  /// AI ogohlantirishi (tibbiy maslahat emasligi haqida).
  final String? disclaimer;

  /// Foydalanuvchi matnda aytgan boshlanish kuni ("с 5 октября"); aytmagan
  /// bo'lsa `null` — unda bugundan boshlanadi.
  final DateTime? startDate;

  int get trainingDays => days.where((d) => !d.isRest).length;

  @override
  List<Object?> get props => [
    title,
    description,
    durationDays,
    days,
    disclaimer,
    startDate,
  ];
}
