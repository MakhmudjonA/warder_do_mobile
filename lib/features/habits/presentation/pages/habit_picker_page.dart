import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/goal_units.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/widgets/template_browser.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../data/habit_template_catalog.dart';
import '../../domain/entities/habit_template.dart';
import '../widgets/quick_add_sheet.dart';
import 'habit_edit_page.dart';

/// Shablonlar: tepada qidiruv, AI kartasi va kategoriyalar, pastda 2 ustunli
/// kartalar. Karta bosilsa forma shu shablon bilan to'ldirilib ochiladi.
class HabitPickerPage extends StatefulWidget {
  const HabitPickerPage({super.key});

  @override
  State<HabitPickerPage> createState() => _HabitPickerPageState();
}

class _HabitPickerPageState extends State<HabitPickerPage> {
  final _searchController = TextEditingController();
  String _query = '';

  /// `null` — "Все".
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// AI qoralamasi odatdagi formada ochiladi — foydalanuvchi ko'rib, saqlaydi.
  Future<void> _quickAdd(BuildContext context) async {
    final draft = await QuickAddSheet.show(context);
    if (draft == null || !context.mounted) return;
    await context.push(AppRoutes.habitEdit, extra: NewHabitDraft(draft));
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty;
    final sections = HabitTemplateCatalog.search(_query)
        .where((s) => isSearching || _category == null || s.title == _category)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.templatesTitle),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const WdIcon(AppIcons.close),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          TemplateSearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
          if (!isSearching)
            CategoryChips(
              categories: [
                for (final s in HabitTemplateCatalog.sections) s.title,
              ],
              selected: _category,
              onSelected: (value) => setState(() => _category = value),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (!isSearching && _category == null) ...[
                  _AiCard(onTap: () => _quickAdd(context)),
                  const SizedBox(height: 22),
                ],
                if (sections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text(
                      AppStrings.nothingFound,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      section.title,
                      style: AppTextStyles.sectionLabel,
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 124,
                        ),
                    itemCount: section.templates.length,
                    itemBuilder: (context, index) {
                      final template = section.templates[index];
                      return _TemplateCard(
                        template: template,
                        onTap: () =>
                            context.push(AppRoutes.habitEdit, extra: template),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.habitEdit),
                  icon: const WdIcon(AppIcons.add, size: 20),
                  label: const Text(AppStrings.customHabit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceHigh),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shablon kartasi: ikonka, nom, maqsad yoki jadval.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback onTap;

  String get _hint {
    final value = template.goalValue;
    if (value == null) return AppStrings.everyDay;
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$text ${GoalUnits.label(template.goalUnit)}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitIconTile(
                iconKey: template.icon,
                color: template.color,
                size: 40,
              ),
              const Spacer(),
              Text(
                template.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Опишите словами" — eng tez yo'l, shuning uchun eng tepada va rangli.
class _AiCard extends StatelessWidget {
  const _AiCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const HabitIconTile(
                  iconKey: 'sparkles',
                  size: 44,
                  onColor: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.addMenuAi,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.quickAddHint,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnPrimary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const WdIcon(
                  AppIcons.chevronRight,
                  size: 22,
                  color: AppColors.textOnPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
