import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/widgets/wd_icon.dart';

/// "+" bosilganda: odat qo'shishning barcha yo'llari bitta joyda.
enum AddAction { ai, templates, custom, program }

class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  static Future<AddAction?> show(BuildContext context) {
    return showModalBottomSheet<AddAction>(
      context: context,
      builder: (_) => const AddMenuSheet(),
    );
  }

  static const _items = [
    (
      action: AddAction.ai,
      icon: 'sparkles',
      color: '#B84FF5',
      title: AppStrings.addMenuAi,
      subtitle: AppStrings.addMenuAiHint,
    ),
    (
      action: AddAction.templates,
      icon: 'checklist',
      color: '#4FA8E8',
      title: AppStrings.addMenuTemplates,
      subtitle: AppStrings.addMenuTemplatesHint,
    ),
    (
      action: AddAction.custom,
      icon: 'pen',
      color: '#F5A64F',
      title: AppStrings.addMenuCustom,
      subtitle: AppStrings.addMenuCustomHint,
    ),
    (
      action: AddAction.program,
      icon: 'workout',
      color: '#F54F6C',
      title: AppStrings.addMenuProgram,
      subtitle: AppStrings.addMenuProgramHint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(AppStrings.addMenuTitle, style: AppTextStyles.title),
            ),
            for (final item in _items) ...[
              Material(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(item.action),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        HabitIconTile(
                          iconKey: item.icon,
                          color: item.color,
                          size: 42,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(item.subtitle, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const WdIcon(
                          AppIcons.chevronRight,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
