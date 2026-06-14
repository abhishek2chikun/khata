import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueProfitChartPoint {
  const RevenueProfitChartPoint({
    required this.dateLabel,
    required this.revenue,
    required this.profit,
  });

  final String dateLabel;
  final double revenue;
  final double profit;
}

class RevenueProfitChart extends StatelessWidget {
  const RevenueProfitChart({
    super.key,
    required this.points,
    required this.semanticSummary,
  });

  final List<RevenueProfitChartPoint> points;
  final String semanticSummary;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Semantics(
        label: semanticSummary,
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No trend data for this range')),
          ),
        ),
      );
    }

    final maxValue = points
        .map((point) => point.revenue > point.profit ? point.revenue : point.profit)
        .fold<double>(0, (current, value) => value > current ? value : current);
    final chartMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return Semantics(
      label: semanticSummary,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue & profit trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LegendDot(color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  const Text('Revenue'),
                  const SizedBox(width: 16),
                  _LegendDot(color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 6),
                  const Text('Profit'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max || value == meta.min) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: points.length <= 7 ? 1 : (points.length / 4).ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                points[index].dateLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].revenue),
                        ],
                        isCurved: false,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].profit),
                        ],
                        isCurved: false,
                        color: Theme.of(context).colorScheme.tertiary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
