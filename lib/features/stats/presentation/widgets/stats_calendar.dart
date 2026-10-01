import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_date.dart';
import '../../../../core/widgets/wd_icon.dart';
import '../../domain/entities/stats_entities.dart';
import 'status_circle.dart';

/// Oylik kalendar: sarlavha + hafta kunlari + 6 haftalik doiralar gridi.
///
/// Ketma-ket `done` kunlar orasiga bog'lovchi chiziq chiziladi.
class StatsCalendar extends StatelessWidget {
  const StatsCalendar({
    required this.month,
    required this.days,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  final DateTime month;
  final List<CalendarDay> days;
  final bool loading;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const double _circle = 30;
  static const double _rowHeight = 40;

  @override
  Widget build(BuildContext context) {
    // Grid boshlanishi — oyning 1-kuni joylashgan haftaning dushanbasi.
    final gridStart = month.subtract(Duration(days: month.weekday - 1));
    final byDate = {for (final d in days) _key(d.date): d};

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      ),
      child: Column(
        children: [
          _header(),
          const SizedBox(height: 14),
          _weekdayLabels(),
          const SizedBox(height: 6),
          // 6 hafta.
          for (var week = 0; week < 6; week++)
            _WeekRow(
              circle: _circle,
              rowHeight: _rowHeight,
              cells: [
                for (var d = 0; d < 7; d++)
                  _cellFor(gridStart.add(Duration(days: week * 7 + d)), byDate),
              ],
            ),
        ],
      ),
    );
  }

  _Cell _cellFor(DateTime date, Map<String, CalendarDay> byDate) {
    final data = byDate[_key(date)];
    return _Cell(date: date, day: data, inMonth: date.month == month.month);
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          '${AppStrings.monthsNominative[month.month - 1]} ${month.year}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (loading)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const SizedBox(width: 8),
        _NavButton(icon: AppIcons.chevronLeft, onTap: onPrev),
        const SizedBox(width: 4),
        _NavButton(icon: AppIcons.chevronRight, onTap: onNext),
      ],
    );
  }

  Widget _weekdayLabels() {
    return Row(
      children: [
        for (final label in AppStrings.weekdayShort)
          Expanded(
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _key(DateTime d) => ApiDate.format(d);
}

/// Bitta kun uchun kalendar katakchasi ma'lumoti.
class _Cell {
  const _Cell({required this.date, required this.day, required this.inMonth});

  final DateTime date;
  final CalendarDay? day;
  final bool inMonth;
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.cells,
    required this.circle,
    required this.rowHeight,
  });

  final List<_Cell> cells;
  final double circle;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          // Ketma-ket `done` kunlar orasidagi bog'lovchi chiziqlar — doiralar
          // ostida.
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectorPainter(cells: cells, circle: circle),
            ),
          ),
          Row(
            children: [
              for (final cell in cells)
                Expanded(child: Center(child: _circleFor(cell))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleFor(_Cell cell) {
    final day = cell.day;
    if (day == null) {
      // Ma'lumot yo'q — bo'sh raqam.
      return SizedBox(
        width: circle,
        height: circle,
        child: Center(
          child: Text(
            '${cell.date.day}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final child = StatusCircle(
      status: day.status,
      progressPercent: day.progressPercent,
      label: '${cell.date.day}',
      size: circle,
    );

    // Qo'shni oy kunlari so'niqroq.
    return cell.inMonth ? child : Opacity(opacity: 0.35, child: child);
  }
}

/// Ketma-ket bajarilgan kunlarni bitta uzluksiz chiziq bilan bog'laydi.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.cells, required this.circle});

  final List<_Cell> cells;
  final double circle;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cells.length;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = circle * 0.34
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < cells.length - 1; i++) {
      final a = cells[i].day;
      final b = cells[i + 1].day;
      if (a == null || b == null) continue;
      if (!a.status.isDone || !b.status.isDone) continue;

      final x1 = (i + 0.5) * cellWidth;
      final x2 = (i + 1.5) * cellWidth;
      canvas.drawLine(Offset(x1, centerY), Offset(x2, centerY), paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) => old.cells != cells;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final AppIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 30,
        width: 30,
        alignment: Alignment.center,
        child: WdIcon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
