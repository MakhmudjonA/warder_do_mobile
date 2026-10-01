import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/widgets/template_browser.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../data/group_template_catalog.dart';
import '../../domain/entities/group.dart';

/// Guruh shablonlari — odat shablonlari bilan bir xil uslubda: tepada qidiruv
/// va kategoriyalar, pastda uch ustunli kartalar.
///
/// Katalog **client tomonda** (backendda guruh shablonlari yo'q), shuning
/// uchun bu ekran hech qanday so'rov yubormaydi. Shablon tanlanganda
/// "Guruh qo'shish" formasi oldindan to'ldirilgan holda ochiladi.
class GroupTemplatesPage extends StatefulWidget {
  const GroupTemplatesPage({super.key});

  @override
  State<GroupTemplatesPage> createState() => _GroupTemplatesPageState();
}

class _GroupTemplatesPageState extends State<GroupTemplatesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty;
    final sections = GroupTemplateCatalog.search(_query)
        .where((s) => isSearching || _category == null || s.title == _category)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.templates),
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
            hint: AppStrings.searchTemplates,
            onChanged: (value) => setState(() => _query = value),
          ),
          if (!isSearching)
            CategoryChips(
              categories: [
                for (final s in GroupTemplateCatalog.sections) s.title,
              ],
              selected: _category,
              onSelected: (value) => setState(() => _category = value),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
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
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 104,
                        ),
                    itemCount: section.templates.length,
                    itemBuilder: (context, index) {
                      final template = section.templates[index];
                      return _GroupCard(
                        template: template,
                        onTap: () => _openForm(context, template: template),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                ],
                OutlinedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const WdIcon(AppIcons.add, size: 20),
                  label: const Text(AppStrings.createOwnGroup),
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

  void _openForm(BuildContext context, {GroupTemplate? template}) {
    context.push(AppRoutes.groupEdit, extra: template);
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.template, required this.onTap});

  final GroupTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              HabitIconTile(
                iconKey: template.icon,
                color: template.color,
                size: 42,
              ),
              const Spacer(),
              Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
