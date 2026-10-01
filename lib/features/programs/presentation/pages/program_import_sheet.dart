import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_date.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/widgets/pickers.dart';
import '../../../../core/widgets/wd_button.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../domain/entities/program.dart';
import '../bloc/program_import_bloc.dart';

/// AI orqali dastur import qilish oynasini ochadi.
///
/// Saqlansa `true` qaytaradi — chaqiruvchi bosh ekranni yangilashi kerak.
Future<bool?> showProgramImportSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => sl<ProgramImportBloc>(),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: const _ProgramImportView(),
      ),
    ),
  );
}

class _ProgramImportView extends StatefulWidget {
  const _ProgramImportView();

  @override
  State<_ProgramImportView> createState() => _ProgramImportViewState();
}

class _ProgramImportViewState extends State<_ProgramImportView> {
  final _promptController = TextEditingController();
  final _habitController = TextEditingController();

  /// `null` = «Авто»: uzunlikni AI matndan o'zi aniqlaydi (default).
  int? _duration;

  /// Matndan aniqlangan davomiylik (bo'lsa). Foydalanuvchi qo'lda chip tanlaganda
  /// [_durationManual] `true` bo'ladi va avtomatik aniqlash to'xtaydi.
  int? _detected;
  bool _durationManual = false;

  /// Dastur boshlanadigan kun: AI matndan topgan bo'lsa o'sha, aks holda
  /// bugun. Preview'da o'zgartirsa bo'ladi.
  DateTime _startDate = ApiDate.dayOnly(DateTime.now());
  ProgramImportStatus? _lastStatus;

  void _onPromptChanged(String text) {
    final detected = detectDuration(text);
    setState(() {
      _detected = detected;
      // Aniqlansa — o'sha; aniqlanmasa «Авто» (null).
      if (!_durationManual) _duration = detected;
    });
  }

  /// Standart variantlar + joriy qiymat (aniqlangan raqam ham chip bo'lib
  /// ko'rinsin, garchi ro'yxatda bo'lmasa ham).
  List<int> _durationOptions() {
    final set = {21, 30, 45, 60};
    if (_duration != null) set.add(_duration!);
    return set.toList()..sort();
  }

  // Odat uchun default belgi va rang — foydalanuvchi keyin tahrirlashi mumkin.
  static const String _habitIcon = 'workout';
  static const String _habitColor = '#F54F6C';

  @override
  void dispose() {
    _promptController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: BlocConsumer<ProgramImportBloc, ProgramImportState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == ProgramImportStatus.saved) {
              Navigator.of(context).pop(true);
            }
            // Preview kelganda odat nomini oldindan to'ldiramiz.
            if (state.status == ProgramImportStatus.preview &&
                _habitController.text.trim().isEmpty) {
              _habitController.text = state.preview?.title ?? '';
            }
            // Faqat yangi preview kelganda (saqlash xatosidan qaytganda emas)
            // sanani AI topgan kunga qo'yamiz — aks holda foydalanuvchi
            // tanlagani o'chib ketardi.
            if (state.status == ProgramImportStatus.preview &&
                _lastStatus == ProgramImportStatus.generating) {
              setState(
                () => _startDate =
                    state.preview?.startDate ?? ApiDate.dayOnly(DateTime.now()),
              );
            }
            _lastStatus = state.status;
          },
          builder: (context, state) {
            return Column(
              children: [
                _Handle(),
                Expanded(
                  child: switch (state.status) {
                    ProgramImportStatus.input ||
                    ProgramImportStatus.generating => _buildInput(
                      context,
                      state,
                    ),
                    _ => _buildPreview(context, state),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Kirish (matn) ---

  Widget _buildInput(BuildContext context, ProgramImportState state) {
    final generating = state.status == ProgramImportStatus.generating;
    final canGenerate =
        _promptController.text.trim().length >= 5 && !generating;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            children: [
              Row(
                children: [
                  const WdIcon(
                    AppIcons.import,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text('Создать программу с AI', style: AppTextStyles.title),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Опишите цель — вид упражнения, текущий результат, за сколько '
                'дней и какие этапы нужны.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _promptController,
                onChanged: _onPromptChanged,
                minLines: 5,
                maxLines: 8,
                maxLength: 2000,
                style: AppTextStyles.body,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText:
                      'Кистевой эспандер 60 lbs. Сейчас 20 раз. Цель — максимум '
                      'за 30 дней, статика на 3-й неделе, разгрузка перед тестом.',
                  hintStyle: AppTextStyles.bodyMuted.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceInput,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Длительность (дней)',
                    style: AppTextStyles.sectionLabel,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _duration == null
                          ? 'AI определит сам'
                          : (_detected != null && !_durationManual
                                ? 'определено из текста'
                                : 'можно изменить'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DurationChips(
                value: _duration,
                options: _durationOptions(),
                onChanged: (v) => setState(() {
                  _duration = v;
                  _durationManual = true;
                }),
              ),
              if (state.failure != null) ...[
                const SizedBox(height: 16),
                _ErrorText(state.failure!.message),
              ],
            ],
          ),
        ),
        _BottomBar(
          child: WdPrimaryButton(
            label: 'Создать',
            isLoading: generating,
            onPressed: canGenerate
                ? () {
                    FocusScope.of(context).unfocus();
                    context.read<ProgramImportBloc>().add(
                      ProgramGenerateRequested(
                        prompt: _promptController.text.trim(),
                        durationDays: _duration,
                      ),
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // --- Preview ---

  Widget _buildPreview(BuildContext context, ProgramImportState state) {
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();

    final saving = state.status == ProgramImportStatus.saving;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            children: [
              Text(preview.title, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Text(preview.description, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Badge('${preview.durationDays} дней'),
                  const SizedBox(width: 8),
                  _Badge('${preview.trainingDays} трениров.'),
                ],
              ),
              const SizedBox(height: 18),
              _LabeledField(
                label: 'Название привычки',
                controller: _habitController,
              ),
              const SizedBox(height: 18),
              Text('Начало', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              _StartDateTile(
                date: _startDate,
                onTap: saving
                    ? null
                    : () async {
                        final picked = await pickDate(context, _startDate);
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
              ),
              const SizedBox(height: 18),
              Text('Дни', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              for (final day in preview.days) _DayTile(day: day),
              if (preview.disclaimer != null) ...[
                const SizedBox(height: 16),
                _Disclaimer(preview.disclaimer!),
              ],
              if (state.failure != null) ...[
                const SizedBox(height: 16),
                _ErrorText(state.failure!.message),
              ],
            ],
          ),
        ),
        _BottomBar(
          child: Row(
            children: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => context.read<ProgramImportBloc>().add(
                        const ProgramImportRestarted(),
                      ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                child: const Text('Заново'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: WdPrimaryButton(
                  label: 'Сохранить',
                  isLoading: saving,
                  onPressed: _habitController.text.trim().isEmpty
                      ? null
                      : () => context.read<ProgramImportBloc>().add(
                          ProgramSaveRequested(
                            habitTitle: _habitController.text.trim(),
                            habitIcon: _habitIcon,
                            habitColor: _habitColor,
                            startDate: ApiDate.format(_startDate),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Foydalanuvchi matnidan davomiylikni (kun) topadi.
///
/// "30 kun", "за 30 дней", "30 days" → 30.  "4 hafta", "4 недели" → 28.
/// Topilmasa `null`. Natija 3..120 oralig'iga qisiladi.
int? detectDuration(String text) {
  final t = text.toLowerCase();

  final dayMatch = RegExp(r'(\d{1,3})\s*(kun|дн|day)').firstMatch(t);
  if (dayMatch != null) {
    final n = int.tryParse(dayMatch.group(1)!);
    if (n != null) return n.clamp(3, 120);
  }

  final weekMatch = RegExp(r'(\d{1,3})\s*(hafta|недел|нед|week)').firstMatch(t);
  if (weekMatch != null) {
    final n = int.tryParse(weekMatch.group(1)!);
    if (n != null) return (n * 7).clamp(3, 120);
  }

  return null;
}

/// Mashq kunini o'qiladigan matn qilib beradi.
String describeTarget(ProgramDay day) {
  if (day.isRest) return 'Отдых';
  final t = day.target;
  if (t == null) return '';
  switch (t.type) {
    case ProgramTargetType.reps:
      final reps = (t.repsMax != null && t.repsMax != t.repsMin)
          ? '${t.repsMin}–${t.repsMax}'
          : '${t.repsMin}';
      final rest = t.restSeconds != null ? ' · отдых ${t.restSeconds}с' : '';
      return '${t.sets}×$reps$rest';
    case ProgramTargetType.staticHold:
      final hold =
          (t.holdSecondsMax != null && t.holdSecondsMax != t.holdSecondsMin)
          ? '${t.holdSecondsMin}–${t.holdSecondsMax}с'
          : '${t.holdSecondsMin}с';
      return 'Статика ${t.sets}×$hold';
    case ProgramTargetType.amrap:
      return '${t.sets}× максимум';
    case ProgramTargetType.test:
      return '🏆 День теста';
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});

  final ProgramDay day;

  @override
  Widget build(BuildContext context) {
    final rest = day.isRest;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rest
                  ? AppColors.surfaceHigh
                  : AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.dayNumber}',
              style: AppTextStyles.caption.copyWith(
                color: rest ? AppColors.textTertiary : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  describeTarget(day),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: rest
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                if (day.note != null && day.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(day.note!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  const _DurationChips({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// `null` = «Авто» (AI o'zi hal qiladi).
  final int? value;
  final List<int> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          label: 'Авто',
          selected: value == null,
          onTap: () => onChanged(null),
        ),
        for (final option in options)
          _chip(
            label: '$option',
            selected: option == value,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Начало: 5 октября" — bosilsa sana tanlanadi.
class _StartDateTile extends StatelessWidget {
  const _StartDateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceInput,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(dayLabel(date), style: AppTextStyles.body)),
              const WdIcon(
                AppIcons.chevronRight,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WdIcon(AppIcons.alert, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const WdIcon(AppIcons.alert, size: 18, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: child,
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
