import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/theme/app_theme.dart';
import 'package:invoice_pro/core/widgets/app_card.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/models/dashboard_models.dart';

class DashboardSeriesChart extends StatelessWidget {
  const DashboardSeriesChart.line({
    super.key,
    required this.title,
    required this.points,
  }) : _variant = _ChartVariant.line;

  const DashboardSeriesChart.bar({
    super.key,
    required this.title,
    required this.points,
  }) : _variant = _ChartVariant.bar;

  final String title;
  final List<ChartPoint> points;
  final _ChartVariant _variant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: points.every((point) => point.amount.isZero)
              ? const AppEmptyState(
                  title: AppStrings.emptyChartTitle,
                  message: AppStrings.emptyChartBody,
                  icon: Icons.show_chart_rounded,
                )
              : SizedBox(
                  height: 220,
                  child: _variant == _ChartVariant.bar
                      ? _BarSeries(points: points)
                      : _LineSeries(points: points),
                ),
        ),
      ],
    );
  }
}

enum _ChartVariant { line, bar }

double _toY(ChartPoint point) => point.amount.minorUnits / 100;

class _BarSeries extends StatelessWidget {
  const _BarSeries({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[index].label, style: Theme.of(context).textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: _toY(points[i]), color: color, width: 10, borderRadius: BorderRadius.circular(4)),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineSeries extends StatelessWidget {
  const _LineSeries({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[index].label, style: Theme.of(context).textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: color,
            barWidth: 3,
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), _toY(points[i])),
            ],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
