import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/utils/api_date.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../programs/presentation/pages/program_import_sheet.dart'
    show describeTarget;
import '../../domain/entities/daily_habit.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// Bosh ekrandagi odat kartasi.
///
/// O'ngdagi tugma odat turiga qarab o'zgaradi:
///   * maqsadsiz odat — oddiy belgilash doirasi
///   * miqdorli odat — progress halqasi ichida "+"
class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.item,
    required this.onPrimaryAction,
    required this.onLongPress,
    this.isPending = false,
    this.enabled = true,
    super.key,
  });

  final DailyHabit item;

  /// O'ngdagi tugma bosildi.
  final VoidCallback onPrimaryAction;

  /// Kartani uzoq bosish — qo'shimcha amallar.
  final VoidCallback onLongPress;

  /// So'rov ketayotgan paytda takroriy bosishni to'sish uchun.
  final bool isPending;

  /// `false` — kartani belgilash mumkin emas (masalan kelajak kun). Karta
  /// ko'rinadi, lekin bosilmaydi va so'niq holatda turadi.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(item.habit.color);
    final done = item.isCompleted;

    return Semantics(
      button: true,
      enabled: enabled,
      label: item.habit.title,
      child: Opacity(
        opacity: (isPending || !enabled) ? 0.6 : 1,
        child: Material(
          color: done ? color : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Kelajak kunda belgilash yo'q — faqat bosishni to'samiz,
            // uzoq bosish (o'chirish) baribir mantiqsiz bo'lgani uchun.
            onTap: enabled ? onPrimaryAction : null,
            onLongPress: enabled ? onLongPress : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  HabitIconTile(
                    iconKey: item.habit.icon,
                    color: item.habit.color,
                    size: 38,
                    onColor: done,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? AppColors.textOnPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _subtitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: _overdue ? FontWeight.w600 : null,
                            color: done
                                ? AppColors.textOnPrimary.withValues(
                                    alpha: 0.85,
                                  )
                                : (_overdue
                                      ? AppColors.danger
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    color: done ? AppColors.textOnPrimary : color,
                    progress: item.progress,
                    completed: done,
                    hasGoal: item.habit.hasGoal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vazifa vaqti o'tib ketgan va hali bajarilmagan (faqat bugun uchun).
  bool get _overdue {
    final time = item.habit.firstReminder;
    if (!item.habit.isTask || item.isCompleted || time == null) return false;
    if (!ApiDate.isToday(item.date)) return false;
    final now = DateTime.now();
    return now.hour * 60 + now.minute > time.hour * 60 + time.minute;
  }

  /// "Har kuni, 1,2/2 litr" — jadval va progressni bitta qatorga jamlaydi.
  String _subtitle() {
    // Vazifa: "⏰ 15:00" (+ "просрочено"); sana — faqat bugun bo'lmasa.
    if (item.habit.isTask) {
      final time = item.habit.firstReminder;
      final parts = <String>[
        if (time != null) '⏰ ${time.json}',
        if (_overdue) AppStrings.overdue,
        if (item.habit.repeatRule case OnceRepeat(
          :final date,
        ) when !ApiDate.isToday(date))
          dayLabel(date),
        if (item.progressLabel.isNotEmpty) item.progressLabel,
      ];
      return parts.isEmpty ? AppStrings.noTime : parts.join(' · ');
    }

    // Dastur odati: jadval ("program") o'rniga o'sha kunning yuklamasini
    // ko'rsatamiz — "3× максимум" kabi. To'liq izoh kartani bosganda.
    final programDay = item.programDay;
    if (programDay != null) return describeTarget(programDay);

    final schedule = switch (item.habit.repeatRule) {
      DailyRepeat() => AppStrings.everyDay,
      WeeklyRepeat(:final days) => _weekdayLabel(days),
      IntervalRepeat(:final everyNDays) => AppStrings.everyNDays.replaceFirst(
        '%s',
        '$everyNDays',
      ),
      ProgramRepeat() => AppStrings.byProgram,
      OnceRepeat(:final date) =>
        '${AppStrings.once}, ${dayLabel(date).toLowerCase()}',
    };

    final progress = item.progressLabel;
    return progress.isEmpty ? schedule : '$schedule, $progress';
  }

  static String _weekdayLabel(List<int> days) {
    if (days.isEmpty) return AppStrings.noSchedule;
    if (days.length == 7) return AppStrings.everyDay;

    final sorted = [...days]..sort();
    return sorted
        .where((d) => d >= 1 && d <= 7)
        .map((d) => AppStrings.weekdayShort[d - 1])
        .join(', ');
  }
}

/// O'ngdagi doira: belgilash yoki progress halqasi.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.progress,
    required this.completed,
    required this.hasGoal,
  });

  final Color color;
  final double progress;
  final bool completed;
  final bool hasGoal;

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: WdIcon(AppIcons.check, size: 18, color: AppColors.background),
      );
    }

    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _RingPainter(color: color, progress: hasGoal ? progress : 0),
        child: Center(child: WdIcon(AppIcons.add, size: 18, color: color)),
      ),
    );
  }
}

/// Progress halqasi. `CustomPainter` — chunki `CircularProgressIndicator`
/// fon halqasini bir xil qalinlikda chiza olmaydi.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.35);

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 12 soatdan boshlanadi
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
