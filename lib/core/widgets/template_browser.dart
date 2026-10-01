import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'wd_icon.dart';

/// Shablon ekranlari (odat va guruh) uchun umumiy qismlar.

/// Kategoriya chip'lari: "Все" + bo'limlar, gorizontal aylantiriladi.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...categories];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = options[index];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(value ?? AppStrings.allCategories),
            selected: isSelected,
            showCheckmark: false,
            side: BorderSide.none,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.textPrimary,
            labelStyle: AppTextStyles.caption.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.background
                  : AppColors.textSecondary,
            ),
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}

/// Qidiruv — tepada, iOS'dagidek.
class TemplateSearchField extends StatelessWidget {
  const TemplateSearchField({
    required this.controller,
    required this.onChanged,
    this.hint = AppStrings.searchHabits,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMuted,
          prefixIcon: const WdIcon(
            AppIcons.search,
            color: AppColors.textTertiary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
