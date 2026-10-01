import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/habit_visuals.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/api_date.dart';
import 'wd_icon.dart';
import 'habit_icon_tile.dart';

/// Emoji tanlash paneli — kategoriyalar bo'yicha guruhlangan katak.
///
/// Natija — [HabitEmoji.catalog] dagi **kalit** (emoji belgisining o'zi emas):
/// backendga aynan shu kalit yoziladi.
class EmojiPickerSheet extends StatelessWidget {
  const EmojiPickerSheet({required this.selected, this.color, super.key});

  final String selected;

  /// Joriy odat rangi — ikonkalar o'sha rangda ko'rinadi.
  final String? color;

  static Future<String?> show(
    BuildContext context,
    String selected, {
    String? color,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmojiPickerSheet(selected: selected, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 14),
            Text(AppStrings.iconLabel, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final entry in HabitEmoji.categorized.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                      child: Text(entry.key, style: AppTextStyles.sectionLabel),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: entry.value.length,
                      itemBuilder: (context, index) {
                        final key = entry.value[index];
                        final isSelected = key == selected;

                        return InkWell(
                          onTap: () => Navigator.of(context).pop(key),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                width: 2,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: HabitIconTile(
                              iconKey: key,
                              color: color,
                              size: 42,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Rang tanlash paneli. Natija — hex string.
class ColorPickerSheet extends StatelessWidget {
  const ColorPickerSheet({required this.selected, super.key});

  final String selected;

  static Future<String?> show(BuildContext context, String selected) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => ColorPickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Text(AppStrings.colorLabel, style: AppTextStyles.title),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final hex in HabitColors.palette)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(hex),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: HabitColors.parse(hex),
                        shape: BoxShape.circle,
                        border: hex == selected
                            ? Border.all(color: AppColors.textPrimary, width: 3)
                            : null,
                      ),
                      child: hex == selected
                          ? const WdIcon(
                              AppIcons.check,
                              color: AppColors.background,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Screenshotdagi qatorlar: emoji + nom + chevron, yumaloq karta ichida.
class EmojiListTile extends StatelessWidget {
  const EmojiListTile({
    required this.emojiKey,
    required this.title,
    required this.onTap,
    this.trailing,
    this.color = '#8E8E93',
    super.key,
  });

  final String emojiKey;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  /// iOS sozlamalaridagidek: har qatorning o'z rangli ikonkasi.
  final String? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              HabitIconTile(iconKey: emojiKey, color: color, size: 30),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.body)),
              trailing ??
                  const WdIcon(
                    AppIcons.chevronRight,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Qatorlarni yumaloq kartaga jamlaydi va orasiga ajratuvchi qo'yadi.
class CardGroup extends StatelessWidget {
  const CardGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 58, right: 12),
                child: Divider(height: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

/// Sana tanlash (bugundan bir oy orqaga — ikki yil oldinga).
Future<DateTime?> pickDate(BuildContext context, DateTime initial) async {
  final today = ApiDate.dayOnly(DateTime.now());
  final first = today.subtract(const Duration(days: 31));
  final last = today.add(const Duration(days: 730));
  final start = initial.isBefore(first)
      ? first
      : (initial.isAfter(last) ? last : initial);

  final picked = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: first,
    lastDate: last,
    helpText: AppStrings.pickDate,
    cancelText: AppStrings.cancel,
    confirmText: AppStrings.done,
  );
  return picked == null ? null : ApiDate.dayOnly(picked);
}
