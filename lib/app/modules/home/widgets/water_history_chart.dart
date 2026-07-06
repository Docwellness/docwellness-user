import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WaterHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const WaterHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          border: Border.all(color: const Color(0xffFDF2FA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CustomText(
            text: 'No water data yet',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff6C737F),
          ),
        ),
      );
    }

    final maxGoal = history.fold<double>(
      0,
      (m, e) => ((e['goal'] ?? 2500) / 1000).toDouble() > m
          ? ((e['goal'] ?? 2500) / 1000).toDouble()
          : m,
    );
    final maxAmount = history.fold<double>(
      0,
      (m, e) => ((e['totalAmount'] ?? 0) / 1000).toDouble() > m
          ? ((e['totalAmount'] ?? 0) / 1000).toDouble()
          : m,
    );
    final yMax = (maxGoal > maxAmount ? maxGoal : maxAmount) + 0.5;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        border: Border.all(color: const Color(0xffFDF2FA)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            text: 'Last 7 Days',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff384250),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}L',
                        const TextStyle(
                          color: Color(0xffC11576),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble() && value >= 0) {
                          return Text(
                            '${value.toInt()}L',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xff6C737F),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= history.length) {
                          return const SizedBox.shrink();
                        }
                        final dateStr = history[i]['date'] ?? '';
                        String label = '';
                        try {
                          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                          label = DateFormat('E').format(date); // Mon, Tue...
                        } catch (_) {
                          label = dateStr.length > 5
                              ? dateStr.substring(5)
                              : dateStr;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xff6C737F),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xffFCE7F6), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(history.length, (i) {
                  final amount = ((history[i]['totalAmount'] ?? 0) / 1000)
                      .toDouble();
                  final goal = ((history[i]['goal'] ?? 2500) / 1000).toDouble();
                  final metGoal = amount >= goal;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: metGoal
                              ? [
                                  const Color(0xff81C784),
                                  const Color(0xff4CAF50),
                                ]
                              : [
                                  const Color(0xffF48FB1),
                                  const Color(0xffC11576),
                                ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: goal,
                          color: const Color(0xffFCE7F6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xffC11576), 'Below goal'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xff4CAF50), 'Met goal'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xffFCE7F6), 'Goal line'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xff6C737F)),
        ),
      ],
    );
  }
}
