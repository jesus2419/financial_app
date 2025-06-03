import 'package:flutter/material.dart';
import '../database/database_handler.dart';
import '../model/transaction.dart' as tx;
import '../model/category.dart';
import '../components/income_vs_expense_chart.dart';
import 'package:flutter/scheduler.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/savings_goal.dart'; // <-- Importar SavingsGoal

class ReportsSection extends StatefulWidget {
  const ReportsSection({super.key});

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  late Future<List<tx.Transaction>> _transactionsFuture;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<SavingsGoal>> _goalsFuture; // <-- Declarar _goalsFuture
  IncomeExpenseGroupBy _groupBy = IncomeExpenseGroupBy.month;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar datos cuando la pantalla se vuelve visible
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    setState(() {
      _transactionsFuture = DatabaseHandler.instance.getAllTransactions();
      _categoriesFuture = DatabaseHandler.instance.getAllCategories();
      _goalsFuture = DatabaseHandler.instance
          .getAllSavingsGoals(); // <-- Inicializar _goalsFuture
    });
  }

  Color _colorFromHex(String hexColor) {
    // <-- Función utilitaria para color
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          ),
          title: const Text('Reportes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refrescar datos',
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 0,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Ver por:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<IncomeExpenseGroupBy>(
                      value: _groupBy,
                      items: const [
                        DropdownMenuItem(
                          value: IncomeExpenseGroupBy.day,
                          child: Text('Día'),
                        ),
                        DropdownMenuItem(
                          value: IncomeExpenseGroupBy.week,
                          child: Text('Semana'),
                        ),
                        DropdownMenuItem(
                          value: IncomeExpenseGroupBy.month,
                          child: Text('Mes'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _groupBy = val);
                          _refreshData();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Category>>(
                  future: _categoriesFuture,
                  builder: (context, catSnap) {
                    if (!catSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return FutureBuilder<List<tx.Transaction>>(
                      future: _transactionsFuture,
                      builder: (context, txSnap) {
                        if (!txSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final categories = catSnap.data!;
                        final transactions = txSnap.data!;

                        // --- GASTOS POR CATEGORIA (Pie Chart) ---
                        final Map<int, double> gastosPorCategoria = {};
                        for (final t in transactions) {
                          if (t.amount < 0 && t.categoryId != null) {
                            gastosPorCategoria[t.categoryId!] =
                                (gastosPorCategoria[t.categoryId!] ?? 0) +
                                t.amount.abs();
                          }
                        }
                        final totalGastos = gastosPorCategoria.values
                            .fold<double>(0, (s, v) => s + v);

                        List<PieChartSectionData> pieSections = [];
                        int idx = 0;
                        for (final entry in gastosPorCategoria.entries) {
                          final cat = categories.firstWhere(
                            (c) => c.id == entry.key,
                            orElse: () =>
                                Category(name: 'Otro', type: 'expense'),
                          );
                          final percent = totalGastos > 0
                              ? entry.value / totalGastos
                              : 0.0;
                          pieSections.add(
                            PieChartSectionData(
                              color: Colors
                                  .primaries[idx % Colors.primaries.length],
                              value: entry.value,
                              title: '${(percent * 100).toStringAsFixed(1)}%',
                              radius: 48,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                          idx++;
                        }

                        return ListView(
                          children: [
                            // Gráfico de barras (original)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: IncomeVsExpenseChart(
                                transactions: transactions,
                                categories: categories,
                                groupBy: _groupBy,
                              ),
                            ),

                            // Sección de gastos por categoría (nuevo)
                            if (gastosPorCategoria.isNotEmpty)
                              Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Gastos por categoría',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.pie_chart,
                                            color: Colors.indigo[400],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 180,
                                        child: PieChart(
                                          PieChartData(
                                            sections: pieSections,
                                            centerSpaceRadius: 32,
                                            sectionsSpace: 2,
                                            borderData: FlBorderData(
                                              show: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Leyenda
                                      Wrap(
                                        spacing: 12,
                                        children: gastosPorCategoria.entries
                                            .map((entry) {
                                              final cat = categories.firstWhere(
                                                (c) => c.id == entry.key,
                                                orElse: () => Category(
                                                  name: 'Otro',
                                                  type: 'expense',
                                                ),
                                              );
                                              final color =
                                                  Colors.primaries[categories
                                                          .indexWhere(
                                                            (c) =>
                                                                c.id ==
                                                                entry.key,
                                                          ) %
                                                      Colors.primaries.length];
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 14,
                                                    height: 14,
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    cat.name,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Sección de progreso de metas (nuevo)
                            Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Progreso de metas',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.track_changes,
                                          color: Colors.indigo[400],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<List<SavingsGoal>>(
                                      future: _goalsFuture,
                                      builder: (context, goalSnap) {
                                        final goals = goalSnap.data ?? [];
                                        if (goals.isEmpty) {
                                          return const Text(
                                            'Sin metas activas',
                                          );
                                        }
                                        return SizedBox(
                                          height: 60,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: goals.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 16),
                                            itemBuilder: (context, i) {
                                              final g = goals[i];
                                              final percent =
                                                  (g.currentAmount /
                                                          (g.targetAmount == 0
                                                              ? 1
                                                              : g.targetAmount))
                                                      .clamp(0.0, 1.0);
                                              return Column(
                                                children: [
                                                  Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: 44,
                                                        height: 44,
                                                        child: CircularProgressIndicator(
                                                          value: percent,
                                                          strokeWidth: 6,
                                                          backgroundColor:
                                                              Colors.grey[200],
                                                          color: g.color != null
                                                              ? _colorFromHex(
                                                                  g.color!,
                                                                )
                                                              : Colors.blue,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${(percent * 100).toInt()}%',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    g.name,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
