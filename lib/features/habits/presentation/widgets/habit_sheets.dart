import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../programs/presentation/pages/program_import_sheet.dart'
    show describeTarget;
import '../../domain/entities/achievement.dart';
import '../../domain/entities/daily_habit.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/constants/goal_units.dart';

/// Miqdorli odatga qancha qo'shishni tanlash paneli.
///
/// Natija — **qo'shiladigan** miqdor (`null` — bekor qilindi).
class LogValueSheet extends StatefulWidget {
  const LogValueSheet({required this.item, super.key});

  final DailyHabit item;

  static Future<double?> show(BuildContext context, DailyHabit item) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogValueSheet(item: item),
    );
  }

  @override
  State<LogValueSheet> createState() => _LogValueSheetState();
}

class _LogValueSheetState extends State<LogValueSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tez tugmalar: maqsadning 1/4, 1/2 va qolgan qismi.
  List<double> get _quickSteps {
    final goal = widget.item.habit.goalValue ?? 1;
    final remaining = goal - widget.item.currentValue;

    final steps = <double>{
      _round(goal / 4),
      _round(goal / 2),
      if (remaining > 0) _round(remaining),
    }..removeWhere((v) => v <= 0);

    return steps.toList()..sort();
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(widget.item.habit.color);
    final unit = GoalUnits.label(widget.item.habit.goalUnit);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HabitIconTile(
                iconKey: widget.item.habit.icon,
                color: widget.item.habit.color,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.habit.title,
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.item.progressLabel, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final step in _quickSteps)
                ActionChip(
                  onPressed: () => Navigator.of(context).pop(step),
                  backgroundColor: color.withValues(alpha: 0.18),
                  side: BorderSide.none,
                  label: Text(
                    '+${_format(step)} $unit'.trim(),
                    style: AppTextStyles.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: AppStrings.customAmount,
              hintStyle: AppTextStyles.bodyMuted,
              suffixText: unit,
              suffixStyle: AppTextStyles.bodyMuted,
              filled: true,
              fillColor: AppColors.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
            onSubmitted: (_) => _submitCustom(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitCustom,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text(
              AppStrings.addProgress,
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  void _submitCustom() {
    // Foydalanuvchi vergul yozishi mumkin — `double.parse` faqat nuqtani biladi.
    final raw = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return;
    Navigator.of(context).pop(value);
  }

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Dastur (mashq) kunining tafsilotlari: shu kunga qancha podxod/takror
/// kerakligini va murabbiy izohini ko'rsatadi.
///
/// Natija — foydalanuvchi "bajarildi" tugmasini bosdimi (`true`), aks holda
/// `null` (shunchaki yopdi).
class ProgramDaySheet extends StatelessWidget {
  const ProgramDaySheet({required this.item, super.key});

  final DailyHabit item;

  static Future<bool?> show(BuildContext context, DailyHabit item) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (_) => ProgramDaySheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(item.habit.color);
    final day = item.programDay!;
    final done = item.isCompleted;
    final note = day.note?.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HabitIconTile(
                  iconKey: item.habit.icon,
                  color: item.habit.color,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.habit.title,
                        style: AppTextStyles.title.copyWith(fontSize: 20),
                      ),
                      Text(
                        'День ${day.dayNumber}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Yuklama — "3× максимум" kabi. Foydalanuvchi shundan necha podxod
            // qilishini biladi.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      describeTarget(day),
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WdIcon(
                      AppIcons.alert,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(note, style: AppTextStyles.body)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: done ? AppColors.surfaceHigh : color,
                foregroundColor: done ? AppColors.textPrimary : null,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: Text(
                done ? 'Отменить отметку' : 'Выполнено',
                style: AppTextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartani uzoq bosganda chiqadigan amallar.
enum HabitQuickAction { edit, clearLog }

class HabitActionsSheet extends StatelessWidget {
  const HabitActionsSheet({required this.item, super.key});

  final DailyHabit item;

  static Future<HabitQuickAction?> show(BuildContext context, DailyHabit item) {
    return showModalBottomSheet<HabitQuickAction>(
      context: context,
      builder: (_) => HabitActionsSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: HabitIconTile(
              iconKey: item.habit.icon,
              color: item.habit.color,
              size: 36,
            ),
            title: Text(
              item.habit.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(item.progressLabel, style: AppTextStyles.caption),
          ),
          const Divider(),
          ListTile(
            leading: const WdIcon(AppIcons.edit, color: AppColors.primary),
            title: Text(
              AppStrings.editAction,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
            onTap: () => Navigator.of(context).pop(HabitQuickAction.edit),
          ),
          ListTile(
            enabled: item.log != null,
            leading: const WdIcon(
              AppIcons.removeCircle,
              color: AppColors.danger,
            ),
            title: Text(
              AppStrings.clearLog,
              style: AppTextStyles.body.copyWith(
                color: item.log == null
                    ? AppColors.textTertiary
                    : AppColors.danger,
              ),
            ),
            onTap: () => Navigator.of(context).pop(HabitQuickAction.clearLog),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// "Yangi yutuq!" oynasi — screenshotdagi yashil olti burchakli nishon.
class AchievementDialog extends StatelessWidget {
  const AchievementDialog({required this.achievement, super.key});

  final Achievement achievement;

  static Future<void> show(BuildContext context, Achievement achievement) {
    return showDialog<void>(
      context: context,
      builder: (_) => AchievementDialog(achievement: achievement),
    );
  }

  /// `type` kaliti bo'yicha o'zbekcha nom.
  ///
  /// Server `title` ni ingliz tilida yuboradi, lekin `type` hech qachon
  /// o'zgarmaydi — shuning uchun tarjima shu kalitga bog'lanadi.
  static const Map<String, String> _titles = {
    'streak_2': 'Начало',
    'streak_7': 'Неделя',
    'streak_30': 'Месяц',
    'streak_100': '100 дней',
    'streak_365': 'Год',
    'goal_10': '10 раз',
    'goal_100': '100 раз',
    'goal_500': '500 раз',
    'goal_1000': '1000 раз',
    'timer_10min': '10 минут',
    'timer_30min': '30 минут',
    'timer_60min': '60 минут',
  };

  static const Map<String, String> _emoji = {
    'streak': '🔥',
    'goal': '🏁',
    'timer': '⏱️',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[achievement.type] ?? achievement.title;
    final emoji = _emoji[achievement.category] ?? '🏆';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.newAchievement,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 54)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.achievementCongrats,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: const Text(AppStrings.great, style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}
