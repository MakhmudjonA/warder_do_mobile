import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../groups/domain/entities/group.dart';
import '../../domain/entities/habit.dart';
import '../bloc/organizer_bloc.dart';
import '../widgets/organizer_rows.dart';

/// Экран «Изменить порядок».
///
/// Один плоский `ReorderableListView`: заголовки групп и привычки вперемешку.
/// Привычка меняет группу просто потому, что оказалась под другим заголовком —
/// отдельного «переместить в…» не нужно.
///
/// [focusGroupId] показывает только одну группу и «Без группы» — так удобно
/// набирать привычки в конкретную группу.
class OrganizerPage extends StatefulWidget {
  const OrganizerPage({this.focusGroupId, super.key});

  final String? focusGroupId;

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrganizerBloc>().add(const OrganizerRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerBloc, OrganizerState>(
      listenWhen: (previous, current) => previous.noticeId != current.noticeId,
      listener: (context, state) {
        final message = state.isSaved ? AppStrings.saved : state.notice;
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
        if (state.isSaved) context.pop();
      },
      builder: (context, state) {
        final focusGroup = _focusGroup(state);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(
              focusGroup?.name ?? AppStrings.reorderTitle,
              overflow: TextOverflow.ellipsis,
            ),
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
            actions: [
              _SaveButton(
                enabled: state.isDirty && !state.isSubmitting,
                isLoading: state.isSubmitting,
                onPressed: () =>
                    context.read<OrganizerBloc>().add(const OrganizerSaved()),
              ),
              // На экране одной группы кнопка «Группы» не нужна — мы уже там.
              if (widget.focusGroupId == null) ...[
                const SizedBox(width: 8),
                _PillButton(
                  label: AppStrings.groups,
                  onPressed: () => context.push(AppRoutes.groups),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
          body: _Body(
            state: state,
            focusGroupId: widget.focusGroupId,
            onReorder: (oldIndex, newIndex) =>
                _reorder(context, state, oldIndex, newIndex),
            onRemoveHabit: (habit) => _showHabitActions(context, habit),
            onRemoveGroup: (group) => _confirmRemoveGroup(context, group),
          ),
        );
      },
    );
  }

  Group? _focusGroup(OrganizerState state) {
    if (widget.focusGroupId == null) return null;
    for (final group in state.groups) {
      if (group.id == widget.focusGroupId) return group;
    }
    return null;
  }

  /// Строки, которые видит пользователь.
  List<OrganizerRow> _rows(OrganizerState state) {
    final rows = <OrganizerRow>[];

    for (final group in state.groups) {
      if (widget.focusGroupId != null && group.id != widget.focusGroupId) {
        continue;
      }
      rows
        ..add(OrganizerRow.header(group))
        ..addAll(state.habitsOf(group.id).map(OrganizerRow.habit));
    }

    // «Без группы» всегда последней секцией — её саму двигать нельзя.
    rows
      ..add(const OrganizerRow.header(null))
      ..addAll(state.ungrouped.map(OrganizerRow.habit));

    return rows;
  }

  void _reorder(
    BuildContext context,
    OrganizerState state,
    int oldIndex,
    int newIndex,
  ) {
    final rows = _rows(state);
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final moved = rows[oldIndex];

    if (moved.isHeader) {
      // «Без группы» — не настоящая группа, её не двигаем.
      if (moved.group == null) return;
      _moveGroupBlock(rows, oldIndex, newIndex);
    } else {
      rows
        ..removeAt(oldIndex)
        // Привычка не может оказаться выше самого первого заголовка.
        ..insert(newIndex.clamp(1, rows.length), moved);
    }

    final rebuilt = _rebuild(state, rows);

    context.read<OrganizerBloc>().add(
      OrganizerArrangementChanged(
        habits: rebuilt.habits,
        groups: rebuilt.groups,
      ),
    );
  }

  /// Группа переезжает вместе со своими привычками.
  void _moveGroupBlock(List<OrganizerRow> rows, int oldIndex, int newIndex) {
    var blockEnd = oldIndex + 1;
    while (blockEnd < rows.length && !rows[blockEnd].isHeader) {
      blockEnd++;
    }
    final block = rows.sublist(oldIndex, blockEnd);
    rows.removeRange(oldIndex, blockEnd);

    // Вставлять можно только на границу секции, иначе блок разрежет чужую.
    final boundaries = <int>[
      for (var i = 0; i < rows.length; i++)
        if (rows[i].isHeader) i,
    ];

    var insertAt = boundaries.isEmpty ? 0 : boundaries.first;
    for (final boundary in boundaries) {
      if (boundary <= newIndex) insertAt = boundary;
    }

    rows.insertAll(insertAt, block);
  }

  /// Из строк обратно в модель: группа привычки — ближайший заголовок сверху.
  ({List<Habit> habits, List<Group> groups}) _rebuild(
    OrganizerState state,
    List<OrganizerRow> rows,
  ) {
    final groups = <Group>[];
    final visible = <Habit>[];
    String? current;

    for (final row in rows) {
      if (row.isHeader) {
        current = row.group?.id;
        if (row.group != null) groups.add(row.group!);
        continue;
      }

      final habit = row.habit!;
      visible.add(
        habit.groupId == current
            ? habit
            : habit.copyWith(groupId: current, clearGroup: current == null),
      );
    }

    if (widget.focusGroupId == null) {
      return (habits: visible, groups: groups);
    }

    // На экране одной группы остальные секции не видны — собираем полный
    // список заново, чтобы их порядок не потерялся.
    final full = <Habit>[];
    for (final group in state.groups) {
      full.addAll(
        group.id == widget.focusGroupId
            ? visible.where((h) => h.groupId == group.id)
            : state.habitsOf(group.id),
      );
    }
    full.addAll(visible.where((h) => h.groupId == null));

    return (habits: full, groups: state.groups);
  }

  Future<void> _showHabitActions(BuildContext context, Habit habit) async {
    final bloc = context.read<OrganizerBloc>();
    // Несохранённую расстановку перезагрузка после правки бы стёрла, поэтому
    // «Изменить» доступно только когда черновика нет.
    final canEdit = !bloc.state.isDirty;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(habit.title, style: AppTextStyles.title),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 16),
              child: Text(
                AppStrings.deleteHabitBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
            if (canEdit)
              ListTile(
                leading: const WdIcon(AppIcons.edit, color: AppColors.primary),
                title: Text(
                  AppStrings.editAction,
                  style: AppTextStyles.body.copyWith(color: AppColors.primary),
                ),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
            ListTile(
              leading: const WdIcon(AppIcons.archive, color: AppColors.primary),
              title: Text(
                AppStrings.archive,
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
              ),
              onTap: () => Navigator.of(sheetContext).pop('archive'),
            ),
            ListTile(
              leading: const WdIcon(AppIcons.delete, color: AppColors.danger),
              title: Text(
                AppStrings.delete,
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      if (!context.mounted) return;
      final updated = await context.push<Habit>(
        AppRoutes.habitEdit,
        extra: habit,
      );
      if (updated != null) bloc.add(const OrganizerRequested());
    } else if (action == 'archive') {
      bloc.add(OrganizerHabitArchived(habit.id));
    } else if (action == 'delete') {
      bloc.add(OrganizerHabitDeleted(habit.id));
    }
  }

  Future<void> _confirmRemoveGroup(BuildContext context, Group group) async {
    final bloc = context.read<OrganizerBloc>();

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

    if (confirmed ?? false) bloc.add(OrganizerGroupDeleted(group.id));
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.focusGroupId,
    required this.onReorder,
    required this.onRemoveHabit,
    required this.onRemoveGroup,
  });

  final OrganizerState state;
  final String? focusGroupId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Habit habit) onRemoveHabit;
  final void Function(Group group) onRemoveGroup;

  @override
  Widget build(BuildContext context) {
    if (state.status == OrganizerStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == OrganizerStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            state.failure?.message ?? AppStrings.errUnknown,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Text(AppStrings.reorderEmpty, style: AppTextStyles.bodyMuted),
      );
    }

    final rows = _visibleRows();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            AppStrings.reorderHint,
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
                // Ручка только справа: обычное касание не должно тащить строку.
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final row = rows[index];

                  if (row.isHeader) {
                    return OrganizerHeaderTile(
                      key: ValueKey(row.key),
                      group: row.group,
                      index: index,
                      onRemove: row.group == null
                          ? null
                          : () => onRemoveGroup(row.group!),
                    );
                  }

                  return OrganizerHabitTile(
                    key: ValueKey(row.key),
                    habit: row.habit!,
                    index: index,
                    onRemove: () => onRemoveHabit(row.habit!),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<OrganizerRow> _visibleRows() {
    final rows = <OrganizerRow>[];

    for (final group in state.groups) {
      if (focusGroupId != null && group.id != focusGroupId) continue;
      rows
        ..add(OrganizerRow.header(group))
        ..addAll(state.habitsOf(group.id).map(OrganizerRow.habit));
    }

    rows
      ..add(const OrganizerRow.header(null))
      ..addAll(state.ungrouped.map(OrganizerRow.habit));

    return rows;
  }
}

/// Синяя круглая галочка — активна, только когда есть что сохранять.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 40,
        width: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const WdIcon(AppIcons.check),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColors.primary : AppColors.surfaceHigh,
        foregroundColor: enabled
            ? AppColors.textOnPrimary
            : AppColors.textTertiary,
        shape: const CircleBorder(),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surfaceHigh,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(color: AppColors.primary),
      ),
    );
  }
}
