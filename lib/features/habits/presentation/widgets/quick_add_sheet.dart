import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/wd_button.dart';
import '../../domain/entities/habit.dart';
import '../bloc/quick_add_cubit.dart';

/// "Опишите словами": bitta gap yoziladi, AI undan odat qoralamasini yasaydi.
///
/// Natija — saqlanmagan [Habit]; chaqiruvchi uni odat formasida ochadi.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  static Future<Habit?> show(BuildContext context) {
    return showModalBottomSheet<Habit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => sl<QuickAddCubit>(),
        child: const QuickAddSheet(),
      ),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _controller = TextEditingController();

  static const List<String> _examples = [
    'завтра в 15:00 к врачу',
    'каждый день 2 литра воды, напомни в 9:00',
    'по понедельникам и четвергам бег в 7 утра',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<QuickAddCubit>().submit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuickAddCubit, QuickAddState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == QuickAddStatus.success && state.draft != null) {
          Navigator.of(context).pop(state.draft);
        }
      },
      builder: (context, state) {
        final loading = state.status == QuickAddStatus.loading;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.quickAddTitle,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.quickAddSubtitle,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !loading,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: AppTextStyles.body,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: AppStrings.quickAddHint,
                    hintStyle: AppTextStyles.bodyMuted,
                    filled: true,
                    fillColor: AppColors.surfaceInput,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final example in _examples)
                      ActionChip(
                        label: Text(example),
                        labelStyle: AppTextStyles.caption,
                        backgroundColor: AppColors.surfaceHigh,
                        side: BorderSide.none,
                        onPressed: loading
                            ? null
                            : () => _controller.text = example,
                      ),
                  ],
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.failure!.message,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                WdPrimaryButton(
                  label: AppStrings.quickAddAction,
                  isLoading: loading,
                  onPressed: _controller.text.trim().length < 2
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
