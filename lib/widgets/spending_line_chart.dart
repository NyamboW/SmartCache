import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/theme.dart';

class SpendingLineChart extends StatelessWidget {
  final Map<DateTime, double> dailySpending;
  final bool isMonthly;

  const SpendingLineChart({
    super.key,
    required this.dailySpending,
    this.isMonthly = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data Spots
    final entries = dailySpending.entries.toList();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: context.textStyles.bodyMedium?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final maxY = entries.map((e) => e.value).fold(0.0, (p, c) => c > p ? c : p);
    // Add 20% top padding
    final safeMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: AppCardDecoration.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeMaxY / 5 > 0 ? safeMaxY / 5 : 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (entries.length / 5)
                            .ceil()
                            .toDouble(), // Show ~5 labels
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            final date = entries[index].key;
                            final format = isMonthly ? 'MMM' : 'MMM d';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat(format).format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (entries.length - 1).toDouble(),
                  minY: 0,
                  maxY: safeMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.8),
                          primaryColor,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: primaryColor,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.2),
                            primaryColor.withOpacity(0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(context).colorScheme.surface,
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      tooltipBorder: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.x.toInt();
                          if (index >= 0 && index < entries.length) {
                            final date = entries[index].key;
                            final amount = entries[index].value;
                            final format = isMonthly ? 'MMM yyyy' : 'MMM d';
                            return LineTooltipItem(
                              '${DateFormat(format).format(date)}\n',
                              context.textStyles.bodySmall!.bold,
                              children: [
                                TextSpan(
                                  text: NumberFormat.simpleCurrency().format(
                                    amount,
                                  ),
                                  style: context.textStyles.bodySmall
                                      ?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
