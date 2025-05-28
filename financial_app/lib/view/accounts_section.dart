import 'package:flutter/material.dart';
import '../database/database_handler.dart';
import '../model/account.dart';

class AccountsSection extends StatefulWidget {
  const AccountsSection({super.key});

  @override
  State<AccountsSection> createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<AccountsSection> {
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  void _refreshAccounts() {
    setState(() {
      _accountsFuture = DatabaseHandler.instance.getAllAccounts();
    });
  }

  void _showAccountDialog({Account? account}) {
    final _formKey = GlobalKey<FormState>();
    String type = account?.type ?? 'cash';
    String? bankName = account?.bankName;
    String? description = account?.description;
    String? creditLimitStr = account?.creditLimit?.toString();
    String? cutOffDayStr = account?.cutOffDay?.toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account == null ? 'Agregar Cuenta' : 'Editar Cuenta'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                          DropdownMenuItem(value: 'debit', child: Text('Débito')),
                          DropdownMenuItem(value: 'credit', child: Text('Crédito')),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            type = val!;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                      ),
                      if (type == 'debit' || type == 'credit')
                        TextFormField(
                          initialValue: bankName,
                          decoration: const InputDecoration(labelText: 'Banco'),
                          validator: (val) {
                            if ((type == 'debit' || type == 'credit') && (val == null || val.isEmpty)) {
                              return 'El banco es obligatorio';
                            }
                            return null;
                          },
                          onChanged: (val) => bankName = val,
                        ),
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'La descripción es obligatoria';
                          }
                          return null;
                        },
                        onChanged: (val) => description = val,
                      ),
                      if (type == 'credit')
                        TextFormField(
                          initialValue: creditLimitStr,
                          decoration: const InputDecoration(labelText: 'Límite de crédito'),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (type == 'credit' && (val == null || val.isEmpty)) {
                              return 'El límite de crédito es obligatorio';
                            }
                            if (type == 'credit' && double.tryParse(val!) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                          onChanged: (val) => creditLimitStr = val,
                        ),
                      if (type == 'credit')
                        TextFormField(
                          initialValue: cutOffDayStr,
                          decoration: const InputDecoration(labelText: 'Día de corte'),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (type == 'credit' && (val == null || val.isEmpty)) {
                              return 'El día de corte es obligatorio';
                            }
                            if (type == 'credit' && int.tryParse(val!) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                          onChanged: (val) => cutOffDayStr = val,
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
                    if (_formKey.currentState!.validate()) {
                      final newAccount = Account(
                        id: account?.id,
                        type: type,
                        bankName: (type == 'debit' || type == 'credit') ? bankName : null,
                        creditLimit: type == 'credit'
                            ? (creditLimitStr != null && creditLimitStr!.isNotEmpty
                                ? double.parse(creditLimitStr!)
                                : null)
                            : null,
                        cutOffDay: type == 'credit'
                            ? (cutOffDayStr != null && cutOffDayStr!.isNotEmpty
                                ? int.parse(cutOffDayStr!)
                                : null)
                            : null,
                        description: description,
                      );
                      try {
                        int result;
                        // Solución: Forzar la recreación de la base de datos si la tabla no existe (solo para desarrollo)
                        // await DatabaseHandler.instance.database; // Esto asegura que la base esté inicializada

                        result = 0;
                        try {
                          if (account == null) {
                            result = await DatabaseHandler.instance.addAccount(newAccount);
                          } else {
                            result = await DatabaseHandler.instance.updateAccount(newAccount);
                          }
                        } catch (e) {
                          // Si hay error de tabla inexistente, muestra mensaje claro
                          if (e.toString().contains('no such table')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('La tabla de cuentas no existe. Reinicia la app o borra la base de datos para recrearla.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                          return;
                        }

                        if (result > 0) {
                          Navigator.pop(context);
                          _refreshAccounts();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al guardar la cuenta')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: Text(account == null ? 'Agregar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAccount(int id) async {
    await DatabaseHandler.instance.deleteAccount(id);
    _refreshAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar cuenta',
            onPressed: () => _showAccountDialog(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(), // El drawer real lo maneja el Scaffold principal
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay cuentas registradas.'));
          }
          final accounts = snapshot.data!;
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              String subtitle = '';
              if (account.type == 'credit') {
                subtitle = 'Banco: ${account.bankName ?? ''} | Límite: \$${account.creditLimit?.toStringAsFixed(2) ?? '-'}';
              } else if (account.type == 'debit') {
                subtitle = 'Banco: ${account.bankName ?? ''}';
              }
              // Para efectivo, subtitle queda vacío

              return ListTile(
                leading: Icon(
                  account.type == 'cash'
                      ? Icons.money
                      : account.type == 'debit'
                          ? Icons.account_balance
                          : Icons.credit_card,
                ),
                title: Text(account.description ?? 'Sin descripción'),
                subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAccountDialog(account: account);
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar cuenta'),
                          content: const Text('¿Estás seguro de eliminar esta cuenta?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deleteAccount(account.id!);
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
          );
        },
      ),
    );
  }
}
