import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// Секция группы на главном экране: заголовок с эмодзи и стрелкой, внутри —
/// карточки привычек. Свернуть можно нажатием на заголовок или на стрелку.
class HabitGroupSection extends StatelessWidget {
  const HabitGroupSection({
    required this.group,
    required this.collapsed,
    required this.onToggle,
    required this.children,
    super.key,
  });

  final Group group;
  final bool collapsed;
  final VoidCallback onToggle;

  /// Карточки привычек этой группы.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final color = HabitColors.parse(group.color);

    return Container(
      decoration: BoxDecoration(
        // Лёгкая заливка цветом группы: секция читается как единый блок,
        // но не спорит с яркими карточками внутри.
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  HabitIconTile(
                    iconKey: group.icon,
                    color: group.color,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                  ),
                  _CollapseButton(
                    color: color,
                    collapsed: collapsed,
                    onTap: onToggle,
                  ),
                ],
              ),
            ),
          ),
          // Свёрнутая группа занимает только высоту заголовка.
          if (!collapsed) ...[
            const SizedBox(height: 2),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        ],
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.color,
    required this.collapsed,
    required this.onTap,
  });

  final Color color;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: !collapsed,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: collapsed ? 0.5 : 0,
            child: WdIcon(AppIcons.arrowUp, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}
