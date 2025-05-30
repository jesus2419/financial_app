import 'package:flutter/material.dart';
import '../database/database_handler.dart';
import '../model/transaction.dart' as tx;
import '../model/category.dart';
import '../components/income_vs_expense_chart.dart';
import 'package:flutter/scheduler.dart';

class ReportsSection extends StatefulWidget {
  const ReportsSection({super.key});

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  late Future<List<tx.Transaction>> _transactionsFuture;
  late Future<List<Category>> _categoriesFuture;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refrescar datos',
          ),
        ],
      ),
      body: Column(
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
                      _refreshData(); // Refrescar al cambiar el agrupamiento
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
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IncomeVsExpenseChart(
                        transactions: txSnap.data!,
                        categories: catSnap.data!,
                        groupBy: _groupBy,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
