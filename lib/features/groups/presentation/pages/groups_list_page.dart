import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/habit_visuals.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../domain/entities/group.dart';
import '../bloc/groups_bloc.dart';
import '../../../../core/widgets/habit_icon_tile.dart';

/// Экран «Группы» — наши собственные группы, без всяких шаблонов.
///
/// Обычное нажатие открывает группу, чтобы перетаскивать в неё привычки.
/// «Править» включает режим, где группы можно переставлять и удалять,
/// а нажатие открывает форму редактирования.
class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    context.read<GroupsBloc>().add(const GroupsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupsBloc, GroupsState>(
      listenWhen: (previous, current) => previous.noticeId != current.noticeId,
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 0,
            title: const Text(AppStrings.groups),
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
              if (state.groups.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surfaceHigh,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ),
                  child: Text(
                    _editing ? AppStrings.doneEditing : AppStrings.edit,
                    style: AppTextStyles.body,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.push(AppRoutes.groupTemplates),
                icon: const WdIcon(AppIcons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceHigh,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: _Body(
            state: state,
            editing: _editing,
            onOpen: _open,
            onDelete: _confirmDelete,
            onReorder: (ids) =>
                context.read<GroupsBloc>().add(GroupsReordered(ids)),
          ),
        );
      },
    );
  }

  void _open(Group group) {
    if (_editing) {
      // В режиме правки нажатие ведёт в форму: имя, цвет, иконка.
      context.push(AppRoutes.groupEdit, extra: group);
      return;
    }
    // Обычное нажатие — набрать в группу привычки перетаскиванием.
    context.push('${AppRoutes.organizer}?group=${group.id}');
  }

  Future<void> _confirmDelete(Group group) async {
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

    if (confirmed ?? false) bloc.add(GroupDeleted(group.id));
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.editing,
    required this.onOpen,
    required this.onDelete,
    required this.onReorder,
  });

  final GroupsState state;
  final bool editing;
  final void Function(Group group) onOpen;
  final void Function(Group group) onDelete;
  final void Function(List<String> orderedIds) onReorder;

  @override
  Widget build(BuildContext context) {
    if (state.status == GroupsStatus.loading && state.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius + 8),
                ),
                child: const Center(
                  child: Text('🫙', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(AppStrings.groupsEmpty, style: AppTextStyles.body),
              const SizedBox(height: 6),
              const Text(
                AppStrings.groupsEmptyBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            AppStrings.groupsHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                itemCount: state.groups.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final ids = state.groups.map((g) => g.id).toList();
                  ids.insert(newIndex, ids.removeAt(oldIndex));
                  onReorder(ids);
                },
                itemBuilder: (context, index) {
                  final group = state.groups[index];

                  return _GroupRow(
                    key: ValueKey(group.id),
                    group: group,
                    index: index,
                    editing: editing,
                    onTap: () => onOpen(group),
                    onDelete: () => onDelete(group),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Сплошная цветная плашка — как в списке «Изменить порядок».
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.index,
    required this.editing,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Group group;
  final int index;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HabitColors.parse(group.color),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              if (editing) ...[
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const WdIcon(
                      AppIcons.remove,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              HabitIconTile(iconKey: group.icon, size: 36, onColor: true),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (editing)
                ReorderableDragStartListener(
                  index: index,
                  child: WdIcon(
                    AppIcons.dragHandle,
                    size: 24,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                )
              else
                WdIcon(
                  AppIcons.chevronRight,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
