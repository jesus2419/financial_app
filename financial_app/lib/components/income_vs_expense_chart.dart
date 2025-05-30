import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/transaction.dart';
import '../model/category.dart';
import 'package:intl/intl.dart';

enum IncomeExpenseGroupBy { day, week, month }

class IncomeVsExpenseChart extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final IncomeExpenseGroupBy groupBy;

  const IncomeVsExpenseChart({
    Key? key,
    required this.transactions,
    required this.categories,
    this.groupBy = IncomeExpenseGroupBy.month,
  }) : super(key: key);

  String _groupKey(DateTime date) {
    switch (groupBy) {
      case IncomeExpenseGroupBy.day:
        return DateFormat('yyyy-MM-dd').format(date);
      case IncomeExpenseGroupBy.week:
        final year = date.year;
        final dayOfYear = int.parse(DateFormat('D').format(date));
        final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
        return '$year-W${weekNumber.toString().padLeft(2, '0')}';
      case IncomeExpenseGroupBy.month:
      default:
        return DateFormat('yyyy-MM').format(date);
    }
  }

  String _groupLabel(String key) {
    switch (groupBy) {
      case IncomeExpenseGroupBy.day:
        final dt = DateFormat('yyyy-MM-dd').parse(key);
        return DateFormat('d MMM', 'es').format(dt);
      case IncomeExpenseGroupBy.week:
        final parts = key.split('-W');
        if (parts.length == 2) {
          final year = int.tryParse(parts[0]) ?? 0;
          final weekNumber = int.tryParse(parts[1]) ?? 1;
          final firstDay = DateTime(
            year,
            1,
            1,
          ).add(Duration(days: (weekNumber - 1) * 7));
          final firstDayOfWeek = firstDay.subtract(
            Duration(days: firstDay.weekday - 1),
          );
          return 'Sem ${weekNumber.toString().padLeft(2, '0')}\n${DateFormat('d/M').format(firstDayOfWeek)}';
        }
        return key;
      case IncomeExpenseGroupBy.month:
      default:
        final dt = DateFormat('yyyy-MM').parse(key);
        return toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(dt)) ??
            '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> incomeByGroup = {};
    final Map<String, double> expenseByGroup = {};
    final catMap = {for (var c in categories) c.id: c};

    for (final tx in transactions) {
      final date = DateTime.tryParse(tx.date);
      if (date == null) continue;
      final groupKey = _groupKey(date);
      final cat = catMap[tx.categoryId];
      final isIncome = cat != null && cat.type == 'income';
      if (isIncome) {
        incomeByGroup[groupKey] =
            (incomeByGroup[groupKey] ?? 0) + tx.amount.abs();
      } else {
        expenseByGroup[groupKey] =
            (expenseByGroup[groupKey] ?? 0) + tx.amount.abs();
      }
    }

    final allGroups = <String>{
      ...incomeByGroup.keys,
      ...expenseByGroup.keys,
    }.toList()..sort();

    if (allGroups.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar la gráfica.'));
    }

    final barGroups = <BarChartGroupData>[];
    final barWidth = 12.0;
    for (int i = 0; i < allGroups.length; i++) {
      final group = allGroups[i];
      final income = incomeByGroup[group] ?? 0;
      final expense = expenseByGroup[group] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green[600],
              width: barWidth,
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.green[900]!, width: 1),
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.red[400],
              width: barWidth,
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.red[900]!, width: 1),
            ),
          ],
        ),
      );
    }

    final maxY =
        [
          ...incomeByGroup.values,
          ...expenseByGroup.values,
        ].fold<double>(0, (prev, e) => e > prev ? e : prev) *
        1.25;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.green[600]!, label: 'Ingresos'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red[400]!, label: 'Gastos'),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              backgroundColor: Colors.grey[50],
              barGroups: barGroups,
              groupsSpace: 20,
              maxY: maxY < 100 ? 100 : maxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[300] ?? Colors.grey,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black26),
                  bottom: BorderSide(color: Colors.black26),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('0');
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 11),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= allGroups.length)
                        return const SizedBox();
                      final group = allGroups[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _groupLabel(group),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.white,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? "Ingresos" : "Gastos"}: \$${rod.toY.toStringAsFixed(2)}',
                      TextStyle(
                        color: isIncome ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
