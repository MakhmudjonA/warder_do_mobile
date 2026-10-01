import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../groups/domain/entities/group.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/constants/goal_units.dart';

/// Одна строка списка «Изменить порядок»: либо заголовок группы, либо привычка.
///
/// Плоский список удобнее для `ReorderableListView` — он умеет двигать только
/// прямых детей, вложенные списки сюда не годятся.
class OrganizerRow {
  const OrganizerRow.header(this.group) : habit = null;
  const OrganizerRow.habit(this.habit) : group = null;

  /// `null` в заголовке — секция «Без группы».
  final Group? group;
  final Habit? habit;

  bool get isHeader => habit == null;

  /// Уникальный ключ для `ReorderableListView`.
  String get key => isHeader ? 'g:${group?.id ?? 'none'}' : 'h:${habit!.id}';
}

/// Заголовок секции — сплошная плашка цвета группы.
class OrganizerHeaderTile extends StatelessWidget {
  const OrganizerHeaderTile({
    required this.group,
    required this.index,
    this.onRemove,
    super.key,
  });

  final Group? group;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isUngrouped = group == null;
    final color = isUngrouped
        ? AppColors.textSecondary
        : HabitColors.parse(group!.color);

    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          // «Без группы» удалить нельзя — это не настоящая группа.
          if (isUngrouped)
            const SizedBox(width: 28)
          else
            _RemoveButton(onTap: onRemove),
          const SizedBox(width: 12),
          if (!isUngrouped) ...[
            HabitIconTile(iconKey: group!.icon, size: 30, onColor: true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              isUngrouped ? AppStrings.noGroup : group!.name,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (isUngrouped)
            const _DragHandle(enabled: false)
          else
            ReorderableDragStartListener(
              index: index,
              child: const _DragHandle(),
            ),
        ],
      ),
    );
  }
}

/// Строка привычки: минус, эмодзи, название цветом группы, ручка справа.
class OrganizerHabitTile extends StatelessWidget {
  const OrganizerHabitTile({
    required this.habit,
    required this.index,
    required this.onRemove,
    super.key,
  });

  final Habit habit;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(habit.color);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _RemoveButton(onTap: onRemove),
          const SizedBox(width: 12),
          HabitIconTile(iconKey: habit.icon, color: habit.color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  _subtitle(habit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const _DragHandle(),
          ),
        ],
      ),
    );
  }

  static String _subtitle(Habit habit) {
    final schedule = switch (habit.repeatRule) {
      DailyRepeat() => AppStrings.everyDay,
      WeeklyRepeat(:final days) =>
        days.isEmpty
            ? AppStrings.noSchedule
            : days.map((d) => AppStrings.weekdayShort[d - 1]).join(', '),
      IntervalRepeat(:final everyNDays) => AppStrings.everyNDays.replaceFirst(
        '%s',
        '$everyNDays',
      ),
      ProgramRepeat() => AppStrings.byProgram,
      OnceRepeat(:final date) =>
        '${AppStrings.once}, ${dayLabel(date).toLowerCase()}',
    };

    final goal = habit.goalValue;
    if (goal == null) return schedule;

    final value = goal == goal.roundToDouble()
        ? goal.toInt().toString()
        : goal.toString();
    return '$schedule, $value ${GoalUnits.label(habit.goalUnit)}'.trim();
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
        child: const WdIcon(AppIcons.remove, size: 20, color: Colors.white),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: WdIcon(
        AppIcons.dragHandle,
        size: 24,
        color: enabled
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
