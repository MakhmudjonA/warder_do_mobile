import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../domain/entities/stats_entities.dart';
import 'status_circle.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// Haftalik jadval: har bir odat qatorida 7 kun holati.
class StatsWeekly extends StatelessWidget {
  const StatsWeekly({
    required this.weekStart,
    required this.weekly,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  final DateTime weekStart;
  final WeeklyStats? weekly;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const double _labelWidth = 104;
  static const double _circle = 24;

  @override
  Widget build(BuildContext context) {
    final habits = weekly?.habits ?? const <WeeklyHabit>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 12),
          _weekdayLabels(),
          const SizedBox(height: 8),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  AppStrings.statsEmpty,
                  style: AppTextStyles.caption,
                ),
              ),
            )
          else
            for (var i = 0; i < habits.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _HabitRow(
                habit: habits[i],
                circle: _circle,
                labelWidth: _labelWidth,
              ),
            ],
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          _rangeLabel(),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (loading)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const SizedBox(width: 8),
        _NavButton(icon: AppIcons.chevronLeft, onTap: onPrev),
        const SizedBox(width: 4),
        _NavButton(icon: AppIcons.chevronRight, onTap: onNext),
      ],
    );
  }

  Widget _weekdayLabels() {
    return Row(
      children: [
        const SizedBox(width: _labelWidth),
        for (final label in AppStrings.weekdayShort)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _rangeLabel() {
    final end = weekStart.add(const Duration(days: 6));
    final startMonth = AppStrings.monthsShort[weekStart.month - 1];
    final endMonth = AppStrings.monthsShort[end.month - 1];
    if (weekStart.month == end.month) {
      return '${weekStart.day}–${end.day} $endMonth';
    }
    return '${weekStart.day} $startMonth – ${end.day} $endMonth';
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.circle,
    required this.labelWidth,
  });

  final WeeklyHabit habit;
  final double circle;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(habit.color);

    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            children: [
              HabitIconTile(iconKey: habit.icon, color: habit.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final day in habit.days)
          Expanded(
            child: Center(
              child: StatusCircle(
                status: day.status,
                progressPercent: day.progressPercent,
                color: color,
                size: circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final AppIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 30,
        width: 30,
        alignment: Alignment.center,
        child: WdIcon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
