import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_handler.dart';
import '../model/transaction.dart' as tx;
import '../model/category.dart';
import '../model/account.dart';

class TransactionsSection extends StatefulWidget {
  const TransactionsSection({super.key});

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  late Future<List<tx.Transaction>> _transactionsFuture;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Account>> _accountsFuture;
  List<Category> _categories = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
    _refreshData();
  }

  Future<void> _initCategories() async {
    final db = DatabaseHandler.instance;
    final existing = await db.getAllCategories();
    if (existing.isEmpty) {
      final defaults = [
        Category(name: 'Nómina', type: 'income'),
        Category(name: 'Comida', type: 'expense'),
        Category(name: 'Gasolina', type: 'expense'),
        Category(name: 'Paseos', type: 'expense'),
      ];
      for (final cat in defaults) {
        await db.addCategory(cat);
      }
    }
    setState(() {
      _categoriesFuture = db.getAllCategories();
    });
  }

  void _refreshData() {
    setState(() {
      _transactionsFuture = DatabaseHandler.instance.getAllTransactions();
      _categoriesFuture = DatabaseHandler.instance.getAllCategories();
      _accountsFuture = DatabaseHandler.instance.getAllAccounts();
    });
  }

  Future<void> _showCategoryDialog() async {
    final _formKey = GlobalKey<FormState>();
    String? name;
    String type = 'expense';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Categoría'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                onChanged: (val) => name = val,
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                ],
                onChanged: (val) => type = val!,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await DatabaseHandler.instance.addCategory(Category(name: name!, type: type));
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransactionDialog({tx.Transaction? transaction}) async {
    final _formKey = GlobalKey<FormState>();
    int? accountId = transaction?.accountId;
    double? amount = transaction?.amount;
    int? categoryId = transaction?.categoryId;
    String? description = transaction?.description;
    // Usa la fecha y hora actual al crear o editar
    DateTime dateTime = DateTime.now();

    // Carga las cuentas y categorías actualizadas antes de mostrar el diálogo
    final accounts = await DatabaseHandler.instance.getAllAccounts();
    final categories = await DatabaseHandler.instance.getAllCategories();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction == null ? 'Agregar Transacción' : 'Editar Transacción'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: accountId,
                  items: accounts
                      .map((acc) => DropdownMenuItem(
                            value: acc.id,
                            child: Text(acc.description ?? 'Cuenta ${acc.id}'),
                          ))
                      .toList(),
                  onChanged: (val) => accountId = val,
                  decoration: const InputDecoration(labelText: 'Cuenta'),
                  validator: (val) => val == null ? 'Seleccione una cuenta' : null,
                ),
                TextFormField(
                  initialValue: amount?.toString(),
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Campo requerido';
                    if (double.tryParse(val) == null) return 'Ingrese un número válido';
                    return null;
                  },
                  onChanged: (val) => amount = double.tryParse(val),
                ),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  items: [
                    ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ))
                  ],
                  onChanged: (val) => categoryId = val,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (val) => val == null ? 'Seleccione una categoría' : null,
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (val) => description = val,
                ),
                // Elimina el input de fecha/hora editable
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Lógica para signo del monto según categoría
                final selectedCat = categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(name: '', type: 'expense'));
                double finalAmount = amount ?? 0;
                if (selectedCat.type == 'income' || selectedCat.name.toLowerCase() == 'nómina' || selectedCat.name.toLowerCase() == 'ingreso') {
                  finalAmount = finalAmount.abs();
                } else {
                  finalAmount = -finalAmount.abs();
                }
                final newTx = tx.Transaction(
                  id: transaction?.id,
                  accountId: accountId!,
                  amount: finalAmount,
                  categoryId: categoryId,
                  description: description,
                  date: DateFormat('yyyy-MM-ddTHH:mm').format(dateTime),
                );
                int result;
                if (transaction == null) {
                  result = await DatabaseHandler.instance.addTransaction(newTx);
                } else {
                  result = await DatabaseHandler.instance.updateTransaction(newTx);
                }
                if (result > 0) {
                  Navigator.pop(context);
                  _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al guardar la transacción')),
                  );
                }
              }
            },
            child: Text(transaction == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    await DatabaseHandler.instance.deleteTransaction(id);
    _refreshData();
  }

  String _formatDate(String dateStr) {
    final now = DateTime.now();
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      return dateStr;
    }
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;
    final hourMinute = DateFormat('HH:mm').format(date);

    if (diff == 0) {
      return 'Hoy $hourMinute';
    } else if (diff == 1) {
      return 'Ayer $hourMinute';
    } else if (now.year == date.year) {
      // Ejemplo: lun 10 14:30
      return '${DateFormat('EEE d', 'es').format(date)} $hourMinute';
    } else {
      // Ejemplo: 10/03/2023 14:30
      return '${DateFormat('dd/MM/yyyy', 'es').format(date)} $hourMinute';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar transacción',
            onPressed: () => _showTransactionDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Agregar Categoría',
            onPressed: _showCategoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return FutureBuilder<List<tx.Transaction>>(
            future: _transactionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay transacciones registradas.'));
              }
              final transactions = snapshot.data!;
              double total = transactions.fold(0.0, (sum, t) => sum + (t.amount));
              return FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, catSnap) {
                  if (!catSnap.hasData) return const SizedBox();
                  final categories = {for (var c in catSnap.data!) c.id: c};
                  return FutureBuilder<List<Account>>(
                    future: _accountsFuture,
                    builder: (context, accSnap) {
                      final accounts = accSnap.hasData
                          ? {for (var a in accSnap.data!) a.id: a}
                          : <int, Account>{};
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final t = transactions[index];
                                final cat = categories[t.categoryId];
                                final isPositive = t.amount >= 0;
                                final account = accounts[t.accountId];
                                // Define icono y color de borde según tipo de cuenta
                                IconData accountIcon;
                                Color borderColor;
                                if (account?.type == 'cash') {
                                  accountIcon = Icons.money;
                                  borderColor = Colors.orange;
                                } else if (account?.type == 'debit') {
                                  accountIcon = Icons.account_balance;
                                  borderColor = Colors.blue;
                                } else if (account?.type == 'credit') {
                                  accountIcon = Icons.credit_card;
                                  borderColor = Colors.purple;
                                } else {
                                  accountIcon = Icons.account_balance_wallet;
                                  borderColor = Colors.grey;
                                }
                                return ListTile(
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: borderColor,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isPositive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(accountIcon, color: borderColor, size: 20),
                                      const SizedBox(width: 6),
                                      Text(account?.description ?? 'Cuenta'),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${cat?.name ?? 'Sin categoría'}\n${t.description ?? ''}\n${_formatDate(t.date)}\n\$${t.amount.toStringAsFixed(2)}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showTransactionDialog(transaction: t);
                                      } else if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Eliminar transacción'),
                                            content: const Text('¿Estás seguro de eliminar esta transacción?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteTransaction(t.id!);
                                                },
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: \$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
