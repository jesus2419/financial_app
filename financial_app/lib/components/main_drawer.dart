import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class MainDrawer extends StatelessWidget {
  final String userName;
  final String totalBalance;
  final int selectedIndex;
  final Function(int) onSectionTap;

  const MainDrawer({
    super.key,
    required this.userName,
    required this.totalBalance,
    required this.selectedIndex,
    required this.onSectionTap,
  });

  Future<void> _logout(BuildContext context) async {
    // 1. Eliminar los datos de sesión
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');

    // 2. Navegar a MyApp (que manejará la redirección automática)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.indigo),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalBalance,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Resumen', 0),
          _buildDrawerItem(context, Icons.list_alt, 'Transacciones', 1),
          _buildDrawerItem(context, Icons.savings, 'Metas de Ahorro', 2),
          _buildDrawerItem(context, Icons.bar_chart, 'Reportes', 3),
          const Divider(),
          _buildDrawerItem(
            context,
            Icons.account_balance_wallet,
            'Mis Cuentas',
            4,
          ),
          _buildDrawerItem(context, Icons.category, 'Categorías', -1),
          _buildDrawerItem(context, Icons.payment, 'Pagos Obligatorios', -1),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context); // Cerrar el drawer
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          onSectionTap(index);
        }
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _logout(context); // Ejecutar el cierre de sesión
              },
            ),
          ],
        );
      },
    );
  }
}
