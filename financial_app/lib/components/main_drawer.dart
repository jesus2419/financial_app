import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  final String userName;
  final String totalBalance;
  final int selectedIndex;
  final Function(int) onSectionTap;

  const MainDrawer({
    Key? key,
    required this.userName,
    required this.totalBalance,
    required this.selectedIndex,
    required this.onSectionTap,
  }) : super(key: key);

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
            -1,
          ),
          _buildDrawerItem(context, Icons.category, 'Categorías', -1),
          _buildDrawerItem(context, Icons.payment, 'Pagos Obligatorios', -1),
          const Divider(),
          _buildDrawerItem(context, Icons.exit_to_app, 'Cerrar sesión', -1),
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
        // Aquí deberías manejar la navegación para los ítems con index negativo
      },
    );
  }
}
