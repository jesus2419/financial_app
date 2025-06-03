import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_handler.dart';
import '../model/account.dart';
import '../model/transaction.dart' as tx;
import '../model/category.dart';
import '../model/savings_goal.dart';
import '../model/mandatory_payment.dart';
import '../components/income_vs_expense_chart.dart';
import 'goals_section.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  late Future<List<Account>> _accountsFuture;
  late Future<List<tx.Transaction>> _transactionsFuture;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<SavingsGoal>> _goalsFuture;
  late Future<List<MandatoryPayment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = DatabaseHandler.instance.getAllAccounts();
    _transactionsFuture = DatabaseHandler.instance.getAllTransactions();
    _categoriesFuture = DatabaseHandler.instance.getAllCategories();
    _goalsFuture = DatabaseHandler.instance.getAllSavingsGoals();
    _paymentsFuture = DatabaseHandler.instance.getAllMandatoryPayments();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final today = DateTime.now();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧭 1. Encabezado (Resumen general)
            FutureBuilder<List<Account>>(
              future: _accountsFuture,
              builder: (context, accSnap) {
                final accounts = accSnap.data ?? [];
                // Suma de todos los saldos de cuentas (igual que en transactions)
                final totalBalance = accounts.fold<double>(
                  0.0,
                  (sum, acc) => sum + (acc.creditLimit ?? 0),
                );
                final efectivo = accounts
                    .where((a) => a.type == 'cash')
                    .fold<double>(0, (s, a) => s + (a.creditLimit ?? 0));
                final debito = accounts
                    .where((a) => a.type == 'debit')
                    .fold<double>(0, (s, a) => s + (a.creditLimit ?? 0));
                final credito = accounts
                    .where((a) => a.type == 'credit')
                    .fold<double>(0, (s, a) => s + (a.creditLimit ?? 0));
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<List<tx.Transaction>>(
                      future: _transactionsFuture,
                      builder: (context, txSnap) {
                        final txs = txSnap.data ?? [];
                        // Agrupa por cuenta y tipo usando las transacciones
                        double efectivo = 0,
                            debito = 0,
                            credito = 0,
                            totalBalance = 0;
                        for (final t in txs) {
                          // Busca la cuenta para saber el tipo
                          // NOTA: Para eficiencia, deberías cachear las cuentas, pero aquí se hace simple
                          // Si tienes muchas cuentas, puedes pasarlas por FutureBuilder o usar un Map
                          // Aquí se asume que las cuentas ya están cargadas en accSnap
                          final accounts = accSnap.data ?? [];
                          final acc = accounts.firstWhere(
                            (a) => a.id == t.accountId,
                            orElse: () => Account(
                              id: t.accountId,
                              type: 'cash',
                              creditLimit: 0,
                            ),
                          );
                          if (acc.type == 'cash') {
                            efectivo += t.amount;
                          } else if (acc.type == 'debit') {
                            debito += t.amount;
                          } else if (acc.type == 'credit') {
                            credito += t.amount;
                          }
                          totalBalance += t.amount;
                        }
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Saldo total disponible',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '\$',
                                        ).format(totalBalance),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(height: 6),
                                      // Mostrar desglose por tipo de cuenta
                                      Text(
                                        'Efectivo: ${NumberFormat.currency(symbol: '\$').format(efectivo)}   Débito: ${NumberFormat.currency(symbol: '\$').format(debito)}   Crédito: ${NumberFormat.currency(symbol: '\$').format(credito)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Calcular rendimiento mensual (ingresos - egresos del mes actual)
                                      Builder(
                                        builder: (context) {
                                          final now = DateTime.now();
                                          final txsMes = txs.where((t) {
                                            final date = DateTime.tryParse(
                                              t.date,
                                            );
                                            return date != null &&
                                                date.year == now.year &&
                                                date.month == now.month;
                                          }).toList();
                                          final ingresos = txsMes
                                              .where((t) => t.amount > 0)
                                              .fold<double>(
                                                0,
                                                (s, t) => s + t.amount,
                                              );
                                          final egresos = txsMes
                                              .where((t) => t.amount < 0)
                                              .fold<double>(
                                                0,
                                                (s, t) => s + t.amount,
                                              );
                                          final rendimientoLocal =
                                              ingresos + egresos;
                                          return Text(
                                            'Rendimiento mensual: ${currencyFormat.format(rendimientoLocal)}',
                                            style: TextStyle(
                                              color: rendimientoLocal >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Icono de alerta si hay pagos obligatorios próximos o metas vencidas
                                FutureBuilder<List<MandatoryPayment>>(
                                  future: _paymentsFuture,
                                  builder: (context, paySnap) {
                                    final pagos = paySnap.data ?? [];
                                    final pagosProximos = pagos.where((p) {
                                      final due = DateTime.tryParse(p.dueDate);
                                      return due != null &&
                                          due.isAfter(today) &&
                                          due.difference(today).inDays <= 7;
                                    }).toList();
                                    return pagosProximos.isNotEmpty
                                        ? const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                            size: 32,
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 📊 2. Gráficas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Progreso de metas de ahorro (circular)
                    Row(
                      children: [
                        const Text(
                          'Progreso de metas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(Icons.track_changes, color: Colors.indigo[400]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<SavingsGoal>>(
                      future: _goalsFuture,
                      builder: (context, goalSnap) {
                        final goals = goalSnap.data ?? [];
                        if (goals.isEmpty) {
                          return const Text('Sin metas activas');
                        }
                        return SizedBox(
                          height: 80, // Aumenta el alto para evitar overflow
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                          backgroundColor: Colors.grey[200],
                                          color: g.color != null
                                              ? _colorFromHex(g.color!)
                                              : Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        '${(percent * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width:
                                        60, // Limita el ancho del texto para evitar overflow
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
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
            const SizedBox(height: 16),

            // 🔄 3. Movimientos recientes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Movimientos recientes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<tx.Transaction>>(
                      future: _transactionsFuture,
                      builder: (context, txSnap) {
                        final txs = txSnap.data ?? [];
                        txs.sort((a, b) => b.date.compareTo(a.date));
                        final recent = txs.take(10).toList();
                        if (recent.isEmpty) {
                          return const Text('Sin movimientos recientes');
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recent.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final t = recent[i];
                            final isIngreso = t.amount > 0;
                            final isTransfer = t.categoryId == null;
                            return ListTile(
                              leading: Icon(
                                isTransfer
                                    ? Icons.compare_arrows
                                    : (isIngreso
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward),
                                color: isTransfer
                                    ? Colors.blueGrey
                                    : (isIngreso ? Colors.green : Colors.red),
                              ),
                              title: Text(
                                t.description ??
                                    (isTransfer ? 'Transferencia' : ''),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(DateTime.parse(t.date)),
                              ),
                              trailing: Text(
                                (isIngreso ? '+' : '') +
                                    currencyFormat.format(t.amount),
                                style: TextStyle(
                                  color: isIngreso ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🎯 4. Metas de ahorro activas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metas de ahorro activas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<SavingsGoal>>(
                      future: _goalsFuture,
                      builder: (context, goalSnap) {
                        final goals = goalSnap.data ?? [];
                        if (goals.isEmpty) {
                          return const Text('No hay metas activas');
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: goals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final g = goals[i];
                            final percent =
                                (g.currentAmount /
                                        (g.targetAmount == 0
                                            ? 1
                                            : g.targetAmount))
                                    .clamp(0.0, 1.0);
                            final restante = g.targetAmount - g.currentAmount;
                            return ListTile(
                              leading: Icon(
                                Icons.savings,
                                color: g.color != null
                                    ? _colorFromHex(g.color!)
                                    : Colors.blue,
                              ),
                              title: Text(g.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[200],
                                    color: g.color != null
                                        ? _colorFromHex(g.color!)
                                        : Colors.blue,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Restante: ${currencyFormat.format(restante > 0 ? restante : 0)}',
                                  ),
                                  if (g.deadline != null)
                                    Text(
                                      'Fecha objetivo: ${g.deadline}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'Aportar',
                                onPressed: () {
                                  // Navegar a la pantalla de metas
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const GoalsSection(),
                                    ),
                                  );
                                  // Aquí podrías abrir el diálogo de aporte rápido
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📅 5. Recordatorios de pagos obligatorios
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pagos obligatorios próximos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<MandatoryPayment>>(
                      future: _paymentsFuture,
                      builder: (context, paySnap) {
                        final pagos = paySnap.data ?? [];
                        final proximos = pagos.where((p) {
                          final due = DateTime.tryParse(p.dueDate);
                          return due != null &&
                              due.isAfter(
                                today.subtract(const Duration(days: 1)),
                              ) &&
                              due.difference(today).inDays <= 7;
                        }).toList();
                        if (proximos.isEmpty) {
                          return const Text('No hay pagos próximos');
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: proximos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = proximos[i];
                            return ListTile(
                              leading: Icon(
                                Icons.payments,
                                color: Colors.red[400],
                              ),
                              title: Text(p.name),
                              subtitle: Text('Fecha límite: ${p.dueDate}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currencyFormat.format(p.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.notes ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  // Botón para marcar como pagado o realizar pago
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Marcar como pagado',
                                    onPressed: () {
                                      // Aquí podrías implementar la lógica de pago
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📍 6. Accesos rápidos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.add,
                  label: 'Transacción',
                  onTap: () {
                    // Navegar o mostrar diálogo de transacción
                  },
                ),
                _QuickActionButton(
                  icon: Icons.compare_arrows,
                  label: 'Transferencia',
                  onTap: () {
                    // Navegar o mostrar diálogo de transferencia
                  },
                ),
                _QuickActionButton(
                  icon: Icons.savings,
                  label: 'Meta',
                  onTap: () {
                    // Navegar o mostrar diálogo de meta
                  },
                ),
                _QuickActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Cuenta',
                  onTap: () {
                    // Navegar o mostrar diálogo de cuenta
                  },
                ),
                _QuickActionButton(
                  icon: Icons.payments,
                  label: 'Pago',
                  onTap: () {
                    // Navegar o mostrar diálogo de pago obligatorio
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🌙 Sugerencia de ahorro inteligente
            Card(
              color: Colors.indigo[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hoy podrías ahorrar \$120 si cocinas en casa en vez de pedir comida.',
                        style: TextStyle(
                          color: Colors.indigo[900],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Ink(
          decoration: const ShapeDecoration(
            color: Colors.indigo,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
