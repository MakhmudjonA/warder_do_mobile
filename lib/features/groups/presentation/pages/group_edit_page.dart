import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/group.dart';
import '../bloc/groups_bloc.dart';
import '../../../../core/widgets/pickers.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// "Guruh qo'shish / tahrirlash" — screenshotdagi forma.
///
/// [template] berilsa forma oldindan to'ldiriladi, [group] berilsa
/// mavjud guruh tahrirlanadi.
class GroupEditPage extends StatefulWidget {
  const GroupEditPage({this.template, this.group, super.key});

  final GroupTemplate? template;
  final Group? group;

  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.group?.name ?? widget.template?.name,
  );

  late String _icon = widget.group?.icon ?? widget.template?.icon ?? 'folder';
  late String _color =
      widget.group?.color ??
      widget.template?.color ??
      HabitColors.palette.first;

  String? _nameError;

  bool get _isEditing => widget.group != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.errNameRequired);
      return;
    }

    setState(() => _nameError = null);
    FocusScope.of(context).unfocus();

    context.read<GroupsBloc>().add(
      GroupSubmitted(
        id: widget.group?.id,
        name: name,
        icon: _icon,
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = HabitColors.parse(_color);

    return BlocListener<GroupsBloc, GroupsState>(
      listenWhen: (previous, current) => previous.noticeId != current.noticeId,
      listener: (context, state) {
        if (state.savedGroup != null) {
          // Saqlandi — ekranni yopamiz, natijani chaqiruvchiga qaytaramiz.
          context.pop(state.savedGroup);
          return;
        }

        final failure = state.failure;
        if (failure != null) {
          // Server maydon bo'yicha xato bergan bo'lsa formada ko'rsatamiz.
          final nameError = failure.fieldErrors['name'];
          if (nameError != null) {
            setState(() => _nameError = nameError);
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      child: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editGroup : AppStrings.addGroup,
              ),
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const WdIcon(AppIcons.chevronLeft, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceHigh,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 40,
                          width: 40,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        )
                      : IconButton(
                          onPressed: _submit,
                          icon: const WdIcon(AppIcons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: const CircleBorder(),
                          ),
                        ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _NameField(
                  controller: _nameController,
                  errorText: _nameError,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 24),

                const _SectionTitle(AppStrings.appearance),
                CardGroup(
                  children: [
                    EmojiListTile(
                      emojiKey: 'art',
                      title: AppStrings.colorLabel,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const WdIcon(
                            AppIcons.unfoldMore,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () async {
                        final picked = await ColorPickerSheet.show(
                          context,
                          _color,
                        );
                        if (picked != null) setState(() => _color = picked);
                      },
                    ),
                    EmojiListTile(
                      emojiKey: 'check',
                      title: AppStrings.iconLabel,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HabitIconTile(
                            iconKey: _icon,
                            color: _color,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const WdIcon(
                            AppIcons.chevronRight,
                            size: 22,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () async {
                        final picked = await EmojiPickerSheet.show(
                          context,
                          _icon,
                        );
                        if (picked != null) setState(() => _icon = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const _SectionTitle(AppStrings.general),
                CardGroup(
                  children: [
                    EmojiListTile(
                      emojiKey: 'alarm',
                      title: AppStrings.notificationsLabel,
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.none, style: AppTextStyles.bodyMuted),
                          SizedBox(width: 6),
                          WdIcon(
                            AppIcons.chevronRight,
                            size: 22,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      // Guruh darajasidagi bildirishnomalar backendda yo'q —
                      // eslatmalar odat darajasida saqlanadi.
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.notificationsHint),
                          ),
                        ),
                    ),
                  ],
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  CardGroup(
                    children: [
                      EmojiListTile(
                        emojiKey: 'no_phone',
                        title: AppStrings.delete,
                        trailing: const SizedBox.shrink(),
                        onTap: _confirmDelete,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bloc = context.read<GroupsBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteGroupTitle),
        content: const Text(
          AppStrings.deleteGroupBody,
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(GroupDeleted(widget.group!.id));
      if (!mounted) return;
      context.pop();
    }
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 32,
                  child: Text('✏️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                const Text(AppStrings.nameLabel, style: AppTextStyles.body),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 100,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.body,
                    onSubmitted: (_) => onSubmitted(),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: AppStrings.nameLabel,
                      hintStyle: AppTextStyles.bodyMuted,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => Text(
              errorText ?? '${value.text.characters.length}/100',
              style: AppTextStyles.caption.copyWith(
                color: errorText == null
                    ? AppColors.textTertiary
                    : AppColors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(title, style: AppTextStyles.sectionLabel),
    );
  }
}
