import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_handler.dart';
import '../model/savings_goal.dart';
import '../model/transaction.dart' as tx;
import '../model/account.dart';

class GoalsSection extends StatefulWidget {
  const GoalsSection({super.key});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  late Future<List<SavingsGoal>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _refreshGoals();
  }

  void _refreshGoals() {
    setState(() {
      _goalsFuture = DatabaseHandler.instance.getAllSavingsGoals();
    });
  }

  Future<void> _showGoalDialog({SavingsGoal? goal}) async {
    final formKey = GlobalKey<FormState>();
    String? name = goal?.name;
    double? targetAmount = goal?.targetAmount;
    String? deadline = goal?.deadline;
    String? description = goal?.description;
    String? icon = goal?.icon ?? 'savings';
    String? color = goal?.color ?? '#2196F3';

    // Colores predefinidos
    final colorOptions = <String, Color>{
      '#2196F3': Colors.blue,
      '#4CAF50': Colors.green,
      '#FF9800': Colors.orange,
      '#F44336': Colors.red,
      '#9C27B0': Colors.purple,
      '#FFC107': Colors.amber,
      '#607D8B': Colors.blueGrey,
    };

    // Iconos predefinidos
    final iconOptions = <String, IconData>{
      'savings': Icons.savings,
      'star': Icons.star,
      'flight': Icons.flight,
      'car': Icons.directions_car,
      'home': Icons.home,
      'favorite': Icons.favorite,
      'school': Icons.school,
      'pets': Icons.pets,
      'shopping_cart': Icons.shopping_cart,
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal == null ? 'Crear Meta' : 'Editar Meta'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Campo requerido' : null,
                  onChanged: (val) => name = val,
                ),
                TextFormField(
                  initialValue: targetAmount?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad objetivo',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Campo requerido';
                    if (double.tryParse(val) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                  onChanged: (val) => targetAmount = double.tryParse(val),
                ),
                TextFormField(
                  controller: TextEditingController(text: deadline),
                  decoration: const InputDecoration(
                    labelText: 'Fecha límite (opcional)',
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline != null
                          ? DateTime.tryParse(deadline!) ?? DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      deadline = DateFormat('yyyy-MM-dd').format(picked);
                      (context as Element).markNeedsBuild();
                    }
                  },
                  readOnly: true,
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  onChanged: (val) => description = val,
                ),
                // ComboBox de color predefinido
                DropdownButtonFormField<String>(
                  value: color,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: colorOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(entry.key),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => color = val,
                ),
                // ComboBox de icono predefinido
                DropdownButtonFormField<String>(
                  value: icon,
                  decoration: const InputDecoration(labelText: 'Ícono'),
                  items: iconOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => icon = val,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newGoal = SavingsGoal(
                  id: goal?.id,
                  name: name!,
                  targetAmount: targetAmount!,
                  deadline: deadline,
                  description: description,
                  color: color,
                  icon: icon,
                  currentAmount: goal?.currentAmount ?? 0,
                );
                if (goal == null) {
                  await DatabaseHandler.instance.addSavingsGoal(newGoal);
                } else {
                  await DatabaseHandler.instance.updateSavingsGoal(newGoal);
                }
                Navigator.pop(context);
                _refreshGoals();
              }
            },
            child: Text(goal == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showGoalDetail(SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          GoalDetailSheet(goal: goal, onRefresh: _refreshGoals),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          ),
          title: const Text('Metas de Ahorro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Crear Meta',
              onPressed: () => _showGoalDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _goalsFuture = DatabaseHandler.instance.getAllSavingsGoals();
                });
              },
              tooltip: 'Refrescar metas',
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<SavingsGoal>>(
            future: _goalsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No hay metas registradas.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showGoalDialog(),
                        child: const Text('Crear primera meta'),
                      ),
                    ],
                  ),
                );
              }
              final goals = snapshot.data!;
              return ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final percent =
                      (goal.currentAmount /
                              (goal.targetAmount == 0 ? 1 : goal.targetAmount))
                          .clamp(0.0, 1.0);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      onTap: () => _showGoalDetail(goal),
                      leading: goal.icon != null
                          ? Icon(
                              _iconFromString(goal.icon!),
                              color: goal.color != null
                                  ? _colorFromHex(goal.color!)
                                  : null,
                            )
                          : const Icon(Icons.savings),
                      title: Text(goal.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            color: goal.color != null
                                ? _colorFromHex(goal.color!)
                                : Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (goal.deadline != null)
                            Text(
                              'Fecha límite: ${goal.deadline}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showGoalDialog(goal: goal),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _iconFromString(String iconName) {
    // Puedes expandir este método según tus necesidades
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'flight':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.savings;
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class GoalDetailSheet extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback onRefresh;
  const GoalDetailSheet({
    required this.goal,
    required this.onRefresh,
    super.key,
  });

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  late Future<List<tx.Transaction>> _relatedTransactionsFuture;
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _relatedTransactionsFuture = _getRelatedTransactions();
    _accountsFuture = DatabaseHandler.instance.getAllAccounts();
  }

  Future<List<tx.Transaction>> _getRelatedTransactions() async {
    final allTx = await DatabaseHandler.instance.getAllTransactions();
    // Considera como relacionadas las transacciones con descripción que contenga el nombre de la meta
    return allTx
        .where(
          (t) =>
              t.description != null &&
              t.description!.contains(widget.goal.name),
        )
        .toList();
  }

  Future<void> _showAddSavingDialog() async {
    final formKey = GlobalKey<FormState>();
    int? accountId;
    double? amount;
    String? desc;

    final accounts = await DatabaseHandler.instance.getAllAccounts();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar ahorro manual'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: accountId,
                items: accounts
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.description ?? 'Cuenta ${acc.id}'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => accountId = val,
                decoration: const InputDecoration(labelText: 'Cuenta origen'),
                validator: (val) =>
                    val == null ? 'Seleccione una cuenta' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Monto a transferir',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  if (double.tryParse(val) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
                onChanged: (val) => amount = double.tryParse(val),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                onChanged: (val) => desc = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Crea una transacción de salida en la cuenta y una de entrada en la meta
                final now = DateTime.now();
                final txOut = tx.Transaction(
                  accountId: accountId!,
                  amount: -amount!,
                  categoryId: null,
                  description:
                      'Transferencia a meta: ${widget.goal.name}${desc != null && desc!.isNotEmpty ? ' - $desc' : ''}',
                  date: DateFormat('yyyy-MM-ddTHH:mm').format(now),
                );
                final txIn = tx.Transaction(
                  accountId: 0, // 0 o un id especial para metas
                  amount: amount!,
                  categoryId: null,
                  description:
                      'Ahorro en meta: ${widget.goal.name}${desc != null && desc!.isNotEmpty ? ' - $desc' : ''}',
                  date: DateFormat('yyyy-MM-ddTHH:mm').format(now),
                );
                await DatabaseHandler.instance.addTransaction(txOut);
                await DatabaseHandler.instance.addTransaction(txIn);
                // Actualiza el monto acumulado en la meta
                final updatedGoal = SavingsGoal(
                  id: widget.goal.id,
                  name: widget.goal.name,
                  targetAmount: widget.goal.targetAmount,
                  currentAmount: widget.goal.currentAmount + amount!,
                  deadline: widget.goal.deadline,
                  description: widget.goal.description,
                  color: widget.goal.color,
                  icon: widget.goal.icon,
                );
                await DatabaseHandler.instance.updateSavingsGoal(updatedGoal);
                Navigator.pop(context);
                widget.onRefresh();
                setState(() {
                  _relatedTransactionsFuture = _getRelatedTransactions();
                });
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        (widget.goal.currentAmount /
                (widget.goal.targetAmount == 0 ? 1 : widget.goal.targetAmount))
            .clamp(0.0, 1.0);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                widget.goal.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: widget.goal.color != null
                    ? _colorFromHex(widget.goal.color!)
                    : Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${widget.goal.currentAmount.toStringAsFixed(2)} / \$${widget.goal.targetAmount.toStringAsFixed(2)}',
              ),
              if (widget.goal.deadline != null)
                Text(
                  'Fecha límite: ${widget.goal.deadline}',
                  style: const TextStyle(color: Colors.grey),
                ),
              if (widget.goal.description != null &&
                  widget.goal.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.goal.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar ahorro manual'),
                onPressed: _showAddSavingDialog,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Ahorros realizados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<tx.Transaction>>(
                future: _relatedTransactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay ahorros registrados para esta meta.'),
                    );
                  }
                  final txs = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    itemBuilder: (context, index) {
                      final t = txs[index];
                      return ListTile(
                        leading: Icon(
                          t.amount >= 0
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: t.amount >= 0 ? Colors.green : Colors.red,
                        ),
                        title: Text(t.description ?? ''),
                        subtitle: Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(DateTime.parse(t.date)),
                        ),
                        trailing: Text('\$${t.amount.toStringAsFixed(2)}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
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
