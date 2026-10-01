import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../domain/entities/stats_entities.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// "Выбранные привычки" kartasi: statistikani bitta odatga yoki barchasiga
/// filtrlaydi. Bosilganda tanlagich paneli ochiladi.
class HabitFilterCard extends StatelessWidget {
  const HabitFilterCard({
    required this.habits,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<HabitOption> habits;

  /// `null` — barcha odatlar.
  final HabitOption? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final title = selected?.title ?? AppStrings.statsAllHabits;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habits.isEmpty ? null : () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const WdIcon(
                  AppIcons.check,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              if (selected == null)
                Text(
                  AppStrings.statsAllHabits,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                HabitIconTile(
                  iconKey: selected!.icon,
                  color: selected!.color,
                  size: 26,
                ),
              const Spacer(),
              if (selected != null)
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const WdIcon(
                AppIcons.chevronRight,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_Selection>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _HabitFilterSheet(habits: habits, selectedId: selected?.id),
    );
    if (result != null) onChanged(result.id);
  }
}

/// Panel `null` (barchasi) ni ham qaytarishi kerak, shuning uchun tanlov
/// alohida obyektga o'raladi — `null` "bekor qilindi" degani.
class _Selection {
  const _Selection(this.id);

  final String? id;
}

class _HabitFilterSheet extends StatelessWidget {
  const _HabitFilterSheet({required this.habits, required this.selectedId});

  final List<HabitOption> habits;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              AppStrings.statsSelectedHabits,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _tile(
                    context,
                    icon: 'checklist',
                    color: '#6C7BF5',
                    title: AppStrings.statsAllHabits,
                    id: null,
                  ),
                  const Divider(height: 1),
                  for (final habit in habits)
                    _tile(
                      context,
                      icon: habit.icon,
                      color: habit.color,
                      title: habit.title,
                      id: habit.id,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String? icon,
    required String? color,
    required String title,
    required String? id,
  }) {
    final isSelected = id == selectedId;
    return ListTile(
      leading: HabitIconTile(iconKey: icon, color: color, size: 32),
      title: Text(title, style: AppTextStyles.body),
      trailing: isSelected
          ? const WdIcon(AppIcons.check, size: 20, color: AppColors.primary)
          : null,
      onTap: () => Navigator.of(context).pop(_Selection(id)),
    );
  }
}
