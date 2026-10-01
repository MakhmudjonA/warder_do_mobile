import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/stats_bloc.dart';
import '../widgets/habit_filter.dart';
import '../widgets/stats_calendar.dart';
import '../widgets/stats_records.dart';
import '../widgets/stats_weekly.dart';

/// Вкладка «Статистика»: календарь, записи (4 числа) и недельная таблица.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StatsBloc>()..add(const StatsStarted()),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.statsTitle)),
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state.status == StatsStatus.loading && state.calendar.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == StatsStatus.failure && state.calendar.isEmpty) {
            return _ErrorView(
              message: state.failure?.message ?? AppStrings.errUnknown,
              onRetry: () =>
                  context.read<StatsBloc>().add(const StatsStarted()),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async =>
                context.read<StatsBloc>().add(const StatsRefreshed()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    AppStrings.statsSelectedHabits,
                    style: AppTextStyles.sectionLabel,
                  ),
                ),
                HabitFilterCard(
                  habits: state.habits,
                  selected: state.selectedHabit,
                  onChanged: (id) => context.read<StatsBloc>().add(
                    StatsHabitFilterChanged(id),
                  ),
                ),
                const SizedBox(height: 16),
                StatsCalendar(
                  month: state.month,
                  days: state.calendar,
                  loading: state.calendarLoading,
                  onPrev: () => context.read<StatsBloc>().add(
                    const StatsMonthStepped(-1),
                  ),
                  onNext: () =>
                      context.read<StatsBloc>().add(const StatsMonthStepped(1)),
                ),
                const SizedBox(height: 16),
                StatsRecordsCard(
                  records: state.records,
                  period: state.period,
                  loading: state.recordsLoading,
                  onPeriodChanged: (p) =>
                      context.read<StatsBloc>().add(StatsPeriodChanged(p)),
                ),
                const SizedBox(height: 16),
                StatsWeekly(
                  weekStart: state.weekStart,
                  weekly: state.weekly,
                  loading: state.weeklyLoading,
                  onPrev: () =>
                      context.read<StatsBloc>().add(const StatsWeekStepped(-1)),
                  onNext: () =>
                      context.read<StatsBloc>().add(const StatsWeekStepped(1)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
