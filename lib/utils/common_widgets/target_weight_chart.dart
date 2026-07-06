import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TargetWeightChart extends StatelessWidget {
  final List<double> values;
  final List<String> dates;
  final String targetWeight;
  final double changePercent;
  final double currentWeight;

  const TargetWeightChart({
    super.key,
    required this.values,
    this.dates = const [],
    this.targetWeight = '',
    this.changePercent = 0.0,
    this.currentWeight = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _buildEmptyState();
    }

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    // Smart Y-axis range with padding
    final range = maxVal - minVal;
    final padding = range < 5 ? 3.0 : range * 0.15;
    final chartMin = ((minVal - padding) / 5).floorToDouble() * 5;
    final chartMax = ((maxVal + padding) / 5).ceilToDouble() * 5;
    final yRange = chartMax - chartMin;

    // Smart interval: show 4-5 labels max
    final rawInterval = yRange / 4;
    final interval = _niceInterval(rawInterval);

    final isNegative = changePercent < 0;
    final absPercent = changePercent.abs();

    // Unique date labels — if repeated, append #index
    final displayDates = _buildUniqueLabels(dates);

    // Bar width based on count
    final barWidth = values.length <= 4
        ? 36.0
        : (values.length <= 7 ? 30.0 : 24.0);
    final chartWidth = (values.length * (barWidth + 20)).clamp(
      200.0,
      double.infinity,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: 'Weight Progress',
                      fontSize: 12,
                      color: Color(0xff9DA4AE),
                      fontWeight: FontWeight.w400,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(
                          text: values.last.toStringAsFixed(1),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff111927),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2, left: 2),
                          child: CustomText(
                            text: 'kg',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff6B7280),
                          ),
                        ),
                        if (absPercent > 0 && absPercent < 100) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffFDF2FA),
                              border: Border.all(
                                color: const Color(0xffFCE7F6),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isNegative
                                      ? Icons.south_rounded
                                      : Icons.north_rounded,
                                  color: const Color(0xffDE2493),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                CustomText(
                                  text: '${absPercent.toStringAsFixed(1)}%',
                                  fontSize: 11,
                                  color: const Color(0xffDE2493),
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (targetWeight.isNotEmpty &&
                  (double.tryParse(targetWeight) ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const CustomText(
                        text: 'Target',
                        fontSize: 10,
                        color: Color(0xff9DA4AE),
                        fontWeight: FontWeight.w400,
                      ),
                      const SizedBox(height: 1),
                      CustomText(
                        text: '$targetWeight kg',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff851653),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax,
                    minY: chartMin,
                    groupsSpace: 12,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tooltipMargin: 6,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)} kg',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xffF3E8EF),
                        strokeWidth: 0.8,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            if (value == chartMin || value == chartMax) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xff9DA4AE),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            final label =
                                (idx >= 0 && idx < displayDates.length)
                                ? displayDates[idx]
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xff9DA4AE),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    barGroups: List.generate(values.length, (index) {
                      final isLast = index == values.length - 1;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            width: barWidth,
                            toY: values[index],
                            color: isLast
                                ? const Color(0xff851653)
                                : const Color(0xffFCCEEF),
                            borderRadius: BorderRadius.circular(8),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: chartMax,
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            text: 'Weight Progress',
            fontSize: 12,
            color: Color(0xff9DA4AE),
            fontWeight: FontWeight.w400,
          ),
          const SizedBox(height: 4),
          if (targetWeight.isNotEmpty &&
              (double.tryParse(targetWeight) ?? 0) > 0)
            CustomText(
              text: 'Target: $targetWeight kg',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xff111927),
            ),
          if (currentWeight > 0) ...[
            const SizedBox(height: 2),
            CustomText(
              text: 'Current: ${currentWeight.toStringAsFixed(1)} kg',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xff6B7280),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 32,
                    color: const Color(0xffD4A9C7),
                  ),
                  const SizedBox(height: 8),
                  const CustomText(
                    text: 'No weight entries yet',
                    fontSize: 13,
                    color: Color(0xff9DA4AE),
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pick a "nice" round interval for Y-axis labels
  double _niceInterval(double raw) {
    if (raw <= 1) return 1;
    if (raw <= 2) return 2;
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 20) return 20;
    if (raw <= 25) return 25;
    if (raw <= 50) return 50;
    return (raw / 10).ceilToDouble() * 10;
  }

  /// Make duplicate date labels unique by appending #2, #3 etc.
  List<String> _buildUniqueLabels(List<String> rawDates) {
    if (rawDates.isEmpty) return [];
    final counts = <String, int>{};
    final result = <String>[];
    for (final d in rawDates) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    // If all unique, return as-is
    final hasDuplicates = counts.values.any((c) => c > 1);
    if (!hasDuplicates) return rawDates;

    final seen = <String, int>{};
    for (final d in rawDates) {
      seen[d] = (seen[d] ?? 0) + 1;
      if (counts[d]! > 1) {
        result.add('$d #${seen[d]}');
      } else {
        result.add(d);
      }
    }
    return result;
  }
}
