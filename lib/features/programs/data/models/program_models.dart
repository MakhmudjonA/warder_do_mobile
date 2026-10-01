import '../../../../core/utils/api_date.dart';
import '../../domain/entities/program.dart';

/// `target` obyektini o'qish/yozish.
class ProgramTargetModel extends ProgramTarget {
  const ProgramTargetModel({
    required super.type,
    super.sets,
    super.repsMin,
    super.repsMax,
    super.restSeconds,
    super.holdSecondsMin,
    super.holdSecondsMax,
  });

  factory ProgramTargetModel.fromJson(Map<String, dynamic> json) {
    return ProgramTargetModel(
      type: _typeFromString(json['type'] as String?),
      sets: (json['sets'] as num?)?.toInt(),
      repsMin: (json['reps_min'] as num?)?.toInt(),
      repsMax: (json['reps_max'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      holdSecondsMin: (json['hold_seconds_min'] as num?)?.toInt(),
      holdSecondsMax: (json['hold_seconds_max'] as num?)?.toInt(),
    );
  }

  /// Har qanday [ProgramTarget] ni JSON'ga o'giradi.
  static Map<String, dynamic> encode(ProgramTarget t) => {
    'type': _typeToString(t.type),
    if (t.sets != null) 'sets': t.sets,
    if (t.repsMin != null) 'reps_min': t.repsMin,
    if (t.repsMax != null) 'reps_max': t.repsMax,
    if (t.restSeconds != null) 'rest_seconds': t.restSeconds,
    if (t.holdSecondsMin != null) 'hold_seconds_min': t.holdSecondsMin,
    if (t.holdSecondsMax != null) 'hold_seconds_max': t.holdSecondsMax,
  };

  static ProgramTargetType _typeFromString(String? v) {
    switch (v) {
      case 'static':
        return ProgramTargetType.staticHold;
      case 'amrap':
        return ProgramTargetType.amrap;
      case 'test':
        return ProgramTargetType.test;
      case 'reps':
      default:
        return ProgramTargetType.reps;
    }
  }

  static String _typeToString(ProgramTargetType t) {
    switch (t) {
      case ProgramTargetType.staticHold:
        return 'static';
      case ProgramTargetType.amrap:
        return 'amrap';
      case ProgramTargetType.test:
        return 'test';
      case ProgramTargetType.reps:
        return 'reps';
    }
  }
}

class ProgramDayModel extends ProgramDay {
  const ProgramDayModel({
    required super.dayNumber,
    required super.isRest,
    super.target,
    super.note,
  });

  factory ProgramDayModel.fromJson(Map<String, dynamic> json) {
    final target = json['target'];
    return ProgramDayModel(
      dayNumber: (json['day_number'] as num).toInt(),
      isRest: json['is_rest'] as bool? ?? false,
      target: target == null
          ? null
          : ProgramTargetModel.fromJson(target as Map<String, dynamic>),
      note: json['note'] as String?,
    );
  }

  /// Har qanday [ProgramDay] ni saqlash uchun JSON'ga o'giradi.
  static Map<String, dynamic> encode(ProgramDay d) => {
    'day_number': d.dayNumber,
    'is_rest': d.isRest,
    if (d.target != null) 'target': ProgramTargetModel.encode(d.target!),
    if (d.note != null) 'note': d.note,
  };
}

class ProgramPreviewModel extends ProgramPreview {
  const ProgramPreviewModel({
    required super.title,
    required super.description,
    required super.durationDays,
    required super.days,
    super.disclaimer,
    super.startDate,
  });

  factory ProgramPreviewModel.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>? ?? const [])
        .map((e) => ProgramDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProgramPreviewModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? days.length,
      days: days,
      disclaimer: json['disclaimer'] as String?,
      startDate: ApiDate.tryParse(json['start_date']),
    );
  }
}
