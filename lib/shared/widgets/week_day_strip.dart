import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

/// Shared Mon-Sun day-strip cell styling/color-coding - used by both Diet
/// Plan's week row (see diet_view.dart's _buildWeekRow) and the Exercise
/// screen's day strip, so the two can never visually drift apart again
/// (they used to be independently-built near-duplicates with a couple of
/// small, easy-to-miss differences - e.g. a solid vs dashed border on a
/// selected future day).
class WeekDayStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDaySelected;
  // Stretches all 7 cells to fill the available width (Expanded per cell)
  // instead of sizing to content - see diet_view.dart's _buildWeekRow,
  // which only wants this for a single-week plan with no "Week N" chips
  // sharing the row; a multi-week plan's horizontally-scrollable chip row
  // needs fixed-width cells instead (the default here).
  final bool expand;

  const WeekDayStrip({
    super.key,
    required this.weekStart,
    required this.selectedDate,
    required this.onDaySelected,
    this.expand = false,
  });

  // Weekday label keyed by DateTime.weekday (1=Mon..7=Sun) - read off each
  // cell's actual date rather than assumed from its position, since
  // weekStart isn't always a calendar Monday (see DietController's own
  // currentWeekStart doc comment - a diet plan's week can start on any
  // weekday).
  static const Map<int, String> _weekdayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  static const double cellWidth = 44;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isSelected =
            day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day;
        final isPast = day.isBefore(todayOnly);
        final isToday = day.isAtSameMomentAs(todayOnly);
        final isFuture = day.isAfter(todayOnly);

        // Today/future days that aren't selected get the same
        // bordered-card look as the home screen's action cards
        // (see actionContainer in home_view.dart: FEF6FB fill,
        // 9F1561 border) instead of sitting as bare text.
        final isDefaultBox = !isPast && !isSelected;

        final cellColor = isPast
            ? (isSelected ? const Color(0xffF3F4F6) : const Color(0xff9DA4AE))
            : (isToday && isSelected)
            ? Colors.white
            : (isFuture && isSelected)
            ? const Color(0xff851653)
            : const Color(0xff6C737F);

        Widget cell = Container(
          width: expand ? null : cellWidth,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPast
                ? (isSelected ? const Color(0xff9DA4AE) : const Color(0xffF3F4F6))
                : (isToday && isSelected)
                ? const Color(0xff851653)
                : (isFuture && isSelected)
                ? const Color(0xffFCE7F6)
                : const Color(0xffFEF6FB),
            borderRadius: BorderRadius.circular(8),
            border: isPast
                ? Border.all(color: const Color(0xff9DA4AE))
                : isDefaultBox
                ? Border.all(color: const Color(0xff9F1561))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: _weekdayLabels[day.weekday] ?? '',
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: cellColor,
              ),
              const SizedBox(height: 2),
              CustomText(
                text: '${day.day}',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: cellColor,
              ),
            ],
          ),
        );

        // A selected future day gets a dashed pink border instead of a
        // plain one - Flutter has no built-in dashed border, hence
        // DashedRoundedRectPainter below. Uses foregroundPainter (not
        // painter) so the dashes are drawn on top of the cell's own opaque
        // fill - drawing them underneath meant the fill (which has no
        // vertical margin to create a gap) painted right over the
        // top/bottom dashes, cropping them away and leaving only the side
        // dashes visible.
        if (isFuture && isSelected) {
          cell = CustomPaint(
            foregroundPainter: DashedRoundedRectPainter(
              color: const Color(0xff851653),
              radius: 8,
            ),
            child: cell,
          );
        }

        final tappable = GestureDetector(
          onTap: () => onDaySelected(day),
          child: cell,
        );
        return expand ? Expanded(child: tappable) : tappable;
      }),
    );
  }
}

/// Flutter has no built-in dashed border, so a selected future day
/// (WeekDayStrip above) and a manually re-expanded completed week (see
/// diet_view.dart's _buildWeekRow) use this to paint one instead of
/// pulling in a package for a single small UI element.
class DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _strokeWidth = 1.5;
  static const double _dashWidth = 4;
  static const double _dashGap = 3;

  DashedRoundedRectPainter({required this.color, this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segment = draw ? _dashWidth : _dashGap;
        final end = (distance + segment).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
