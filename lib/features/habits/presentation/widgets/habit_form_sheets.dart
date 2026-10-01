import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/api_date.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/widgets/pickers.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../../groups/presentation/bloc/groups_bloc.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../../../core/widgets/habit_icon_tile.dart';
import '../../../../core/constants/goal_units.dart';

/// Цель привычки одним объектом — так её удобнее возвращать из панели.
class GoalDraft {
  const GoalDraft({this.value, this.unit, this.type = GoalType.atLeast});

  /// `null` — цели нет, привычка становится обычной галочкой.
  final double? value;
  final String? unit;
  final GoalType type;

  static const GoalDraft none = GoalDraft();
}

/// Общая обёртка для панелей: заголовок и скруглённые углы.
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 12),
            Flexible(child: child),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Тип привычки. Бэкенд знает только три: `good`, `bad`, `task`.
class HabitTypeSheet extends StatelessWidget {
  const HabitTypeSheet({required this.selected, super.key});

  final HabitType selected;

  static Future<HabitType?> show(BuildContext context, HabitType selected) {
    return showModalBottomSheet<HabitType>(
      context: context,
      builder: (_) => HabitTypeSheet(selected: selected),
    );
  }

  static const List<({HabitType type, String emoji, String label})> _options = [
    (type: HabitType.good, emoji: '👍', label: AppStrings.typeGood),
    (type: HabitType.bad, emoji: '✋', label: AppStrings.typeBad),
    (type: HabitType.task, emoji: '📋', label: AppStrings.typeTask),
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.typeLabel,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final option in _options)
            ListTile(
              leading: Text(option.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(option.label, style: AppTextStyles.body),
              trailing: option.type == selected
                  ? const WdIcon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(option.type),
            ),
        ],
      ),
    );
  }
}

/// Напоминание заранее. Возвращает [RemindBeforeSheet.auto] для «Авто»
/// (null на сервере), иначе минуты; null — панель закрыли без выбора.
class RemindBeforeSheet extends StatelessWidget {
  const RemindBeforeSheet({required this.selected, super.key});

  /// `null` — «Авто».
  final int? selected;

  static const int auto = -1;

  static Future<int?> show(BuildContext context, int? selected) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (_) => RemindBeforeSheet(selected: selected),
    );
  }

  static String label(int? minutes) => switch (minutes) {
    null => AppStrings.remindBeforeAuto,
    0 => AppStrings.remindBeforeOff,
    60 => AppStrings.remindBeforeHour,
    final m => AppStrings.remindBeforeFormat.replaceFirst('%s', '$m'),
  };

  static const List<int?> _options = [null, 0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.remindBeforeLabel,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final option in _options)
            ListTile(
              title: Text(label(option), style: AppTextStyles.body),
              subtitle: option == null
                  ? const Text(
                      AppStrings.remindBeforeAutoHint,
                      style: AppTextStyles.caption,
                    )
                  : null,
              trailing: option == selected
                  ? const WdIcon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(option ?? auto),
            ),
        ],
      ),
    );
  }
}

/// Выбор группы. Пустое значение — «Без группы» (`group_id: null`).
class GroupPickerSheet extends StatelessWidget {
  const GroupPickerSheet({required this.selectedId, super.key});

  final String? selectedId;

  /// Возвращает `('none', null)` при сбросе и `('id', <uuid>)` при выборе,
  /// чтобы отличить «ничего не выбрал» (null) от «убрал группу».
  static Future<(bool changed, String? groupId)> show(
    BuildContext context,
    String? selectedId,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => GroupPickerSheet(selectedId: selectedId),
    );

    if (result == null) return (false, null);
    return (true, result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.groupLabel,
      child: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          if (state.status == GroupsStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Text('—', style: TextStyle(fontSize: 20)),
                title: const Text(
                  AppStrings.noGroup,
                  style: AppTextStyles.body,
                ),
                trailing: selectedId == null
                    ? const WdIcon(AppIcons.check, color: AppColors.primary)
                    : null,
                // Пустая строка = сброс группы.
                onTap: () => Navigator.of(context).pop(''),
              ),
              for (final group in state.groups)
                ListTile(
                  leading: HabitIconTile(
                    iconKey: group.icon,
                    color: group.color,
                    size: 32,
                  ),
                  title: Text(group.name, style: AppTextStyles.body),
                  trailing: group.id == selectedId
                      ? const WdIcon(AppIcons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(group.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Цель: значение, единица измерения и способ сравнения.
class GoalSheet extends StatefulWidget {
  const GoalSheet({required this.initial, super.key});

  final GoalDraft initial;

  static Future<GoalDraft?> show(BuildContext context, GoalDraft initial) {
    return showModalBottomSheet<GoalDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalSheet(initial: initial),
    );
  }

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late final TextEditingController _valueController = TextEditingController(
    text: widget.initial.value == null ? '' : _format(widget.initial.value!),
  );

  late String _unit = widget.initial.unit ?? GoalUnits.choices.first;
  late GoalType _type = widget.initial.type;

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _valueController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);

    Navigator.of(context).pop(
      value == null || value <= 0
          ? GoalDraft.none
          : GoalDraft(value: value, unit: _unit, type: _type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.goalLabel,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextField(
            controller: _valueController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: AppStrings.goalValueLabel,
              hintStyle: AppTextStyles.bodyMuted,
              filled: true,
              fillColor: AppColors.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 18),
          const Text(AppStrings.goalUnitLabel, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Eski ruscha qiymat ("литров") ro'yxatda yo'q — uni ham ko'rsatamiz.
              for (final unit in {...GoalUnits.choices, _unit})
                ChoiceChip(
                  label: Text(GoalUnits.label(unit)),
                  selected: unit == _unit,
                  onSelected: (_) => setState(() => _unit = unit),
                  showCheckmark: false,
                  side: BorderSide.none,
                  backgroundColor: AppColors.surfaceHigh,
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.caption.copyWith(
                    fontSize: 14,
                    color: unit == _unit
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(AppStrings.goalTypeLabel, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          SegmentedButton<GoalType>(
            segments: const [
              ButtonSegment(
                value: GoalType.atLeast,
                label: Text(AppStrings.goalAtLeast),
              ),
              ButtonSegment(
                value: GoalType.atMost,
                label: Text(AppStrings.goalAtMost),
              ),
              ButtonSegment(
                value: GoalType.exact,
                label: Text(AppStrings.goalExact),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text(AppStrings.done, style: AppTextStyles.button),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(GoalDraft.none),
            child: const Text(
              AppStrings.goalRemove,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Расписание: каждый день / дни недели / раз в N дней.
class RepeatSheet extends StatefulWidget {
  const RepeatSheet({required this.initial, super.key});

  final RepeatRule initial;

  static Future<RepeatRule?> show(BuildContext context, RepeatRule initial) {
    return showModalBottomSheet<RepeatRule>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RepeatSheet(initial: initial),
    );
  }

  @override
  State<RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<RepeatSheet> {
  late int _mode = switch (widget.initial) {
    DailyRepeat() => 0,
    WeeklyRepeat() => 1,
    IntervalRepeat() => 2,
    OnceRepeat() => 3,
    // Форма не открывает эту панель для программы; на всякий случай — «каждый день».
    ProgramRepeat() => 0,
  };

  late DateTime _onceDate = switch (widget.initial) {
    OnceRepeat(:final date) => date,
    _ => ApiDate.dayOnly(DateTime.now()),
  };

  late final Set<int> _days = switch (widget.initial) {
    WeeklyRepeat(:final days) => days.toSet(),
    _ => {DateTime.now().weekday},
  };

  late final TextEditingController _intervalController = TextEditingController(
    text: switch (widget.initial) {
      IntervalRepeat(:final everyNDays) => '$everyNDays',
      _ => '2',
    },
  );

  String? _error;

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  void _submit() {
    switch (_mode) {
      case 0:
        Navigator.of(context).pop(const DailyRepeat());
      case 1:
        if (_days.isEmpty) {
          setState(() => _error = AppStrings.errWeekdaysRequired);
          return;
        }
        Navigator.of(context).pop(WeeklyRepeat(_days.toList()..sort()));
      case 2:
        final n = int.tryParse(_intervalController.text.trim()) ?? 0;
        Navigator.of(context).pop(IntervalRepeat(n < 1 ? 1 : n));
      default:
        Navigator.of(context).pop(OnceRepeat(_onceDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.repeatLabel,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Четыре режима не влезают в SegmentedButton на узком экране.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (mode, label) in const [
                (0, AppStrings.repeatDaily),
                (1, AppStrings.repeatWeekly),
                (2, AppStrings.repeatInterval),
                (3, AppStrings.repeatOnce),
              ])
                _choice(
                  label: label,
                  selected: _mode == mode,
                  onTap: () => setState(() {
                    _mode = mode;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_mode == 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 1 = понедельник … 7 = воскресенье, как в DateTime.weekday.
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(AppStrings.weekdayShort[day - 1]),
                    selected: _days.contains(day),
                    showCheckmark: false,
                    side: BorderSide.none,
                    backgroundColor: AppColors.surfaceHigh,
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.caption.copyWith(
                      fontSize: 14,
                      color: _days.contains(day)
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                    ),
                    onSelected: (selected) => setState(() {
                      selected ? _days.add(day) : _days.remove(day);
                      _error = null;
                    }),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 20),
          ],

          if (_mode == 3) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in _quickDays)
                  _choice(
                    label: dayLabel(day),
                    selected: ApiDate.isSameDay(day, _onceDate),
                    onTap: () => setState(() => _onceDate = day),
                  ),
                if (!_quickDays.any((d) => ApiDate.isSameDay(d, _onceDate)))
                  _choice(
                    label: dayLabel(_onceDate),
                    selected: true,
                    onTap: () {},
                  ),
                _choice(
                  label: '${AppStrings.otherDate}…',
                  selected: false,
                  onTap: () async {
                    final picked = await pickDate(context, _onceDate);
                    if (picked != null) setState(() => _onceDate = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          if (_mode == 2) ...[
            TextField(
              controller: _intervalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: AppStrings.repeatIntervalHint,
                hintStyle: AppTextStyles.bodyMuted,
                filled: true,
                fillColor: AppColors.surfaceInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 20),
          ],

          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text(AppStrings.done, style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}

/// Чип выбора в панели расписания.
Widget _choice({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    side: BorderSide.none,
    backgroundColor: AppColors.surfaceHigh,
    selectedColor: AppColors.primary,
    labelStyle: AppTextStyles.caption.copyWith(
      fontSize: 14,
      color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
    ),
    onSelected: (_) => onTap(),
  );
}

/// Сегодня и завтра — самые частые даты разовой задачи.
List<DateTime> get _quickDays {
  final today = ApiDate.dayOnly(DateTime.now());
  return [today, today.add(const Duration(days: 1))];
}

/// Напоминания. Сервер только хранит время — уведомление ставит телефон.
class RemindersSheet extends StatefulWidget {
  const RemindersSheet({required this.initial, super.key});

  final List<Reminder> initial;

  static Future<List<Reminder>?> show(
    BuildContext context,
    List<Reminder> initial,
  ) {
    return showModalBottomSheet<List<Reminder>>(
      context: context,
      builder: (_) => RemindersSheet(initial: initial),
    );
  }

  @override
  State<RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<RemindersSheet> {
  late final List<Reminder> _items = [...widget.initial];

  Future<void> _add() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;

    final reminder = Reminder(hour: picked.hour, minute: picked.minute);
    // Один и тот же час дважды сохранять незачем.
    if (_items.contains(reminder)) return;

    setState(() {
      _items
        ..add(reminder)
        ..sort((a, b) => a.json.compareTo(b.json));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.remindersLabel,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final reminder in _items)
            ListTile(
              leading: const Text('⏰', style: TextStyle(fontSize: 20)),
              title: Text(reminder.json, style: AppTextStyles.body),
              trailing: IconButton(
                icon: const WdIcon(
                  AppIcons.close,
                  color: AppColors.textTertiary,
                ),
                onPressed: () => setState(() => _items.remove(reminder)),
              ),
            ),
          ListTile(
            leading: const WdIcon(AppIcons.add, color: AppColors.primary),
            title: Text(
              AppStrings.addReminder,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
            // Бэкенд разрешает не больше 20 напоминаний.
            onTap: _items.length >= 20 ? null : _add,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(AppStrings.remindersHint, style: AppTextStyles.caption),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_items),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: const Text(AppStrings.done, style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

/// Описание привычки — свободный текст.
class DescriptionSheet extends StatefulWidget {
  const DescriptionSheet({required this.initial, super.key});

  final String initial;

  static Future<String?> show(BuildContext context, String initial) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DescriptionSheet(initial: initial),
    );
  }

  @override
  State<DescriptionSheet> createState() => _DescriptionSheetState();
}

class _DescriptionSheetState extends State<DescriptionSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: AppStrings.descriptionLabel,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: AppStrings.descriptionHint,
              hintStyle: AppTextStyles.bodyMuted,
              filled: true,
              fillColor: AppColors.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ),
            child: const Text(AppStrings.done, style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}

/// Панель выбора группы нужна вместе с загрузкой списка — вызывающий экран
/// должен один раз запросить группы.
void ensureGroupsLoaded(BuildContext context) {
  final bloc = context.read<GroupsBloc>();
  if (bloc.state.status == GroupsStatus.initial) {
    bloc.add(const GroupsRequested());
  }
}

/// Заглушка, чтобы не тянуть `NoParams` в каждый экран.
const NoParams noParams = NoParams();
