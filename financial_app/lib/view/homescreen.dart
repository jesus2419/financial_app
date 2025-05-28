import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dashboard_section.dart';
import 'transactions_section.dart';
import 'goals_section.dart';
import 'reports_section.dart';
import 'accounts_section.dart'; // Nueva importación

class MainScreen extends StatefulWidget {
  final String userName;
  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DateTime _currentDate = DateTime.now();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');
  bool _localeReady = false;

  // Datos de ejemplo (deberías reemplazarlos con tus modelos reales)
  final double _totalBalance = 12500.50;

  static const List<Widget> _appSections = [
    DashboardSection(),
    TransactionsSection(),
    GoalsSection(),
    AccountsSection(), // Nueva sección
    ReportsSection(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es').then((_) {
      setState(() {
        _localeReady = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${widget.userName}'),
            Text(
              DateFormat('EEEE, d MMMM', 'es').format(_currentDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _appSections[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedIndex == 1 ? _buildAddTransactionButton() : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
              )),
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
                  widget.userName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(_totalBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Resumen', 0),
          _buildDrawerItem(Icons.list_alt, 'Transacciones', 1),
          _buildDrawerItem(Icons.savings, 'Metas de Ahorro', 2),
          _buildDrawerItem(Icons.bar_chart, 'Reportes', 3),
          const Divider(),
          _buildDrawerItem(Icons.account_balance_wallet, 'Mis Cuentas', -1),
          _buildDrawerItem(Icons.category, 'Categorías', -1),
          _buildDrawerItem(Icons.payment, 'Pagos Obligatorios', -1),
          const Divider(),
          _buildDrawerItem(Icons.exit_to_app, 'Cerrar sesión', -1),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          _onItemTapped(index);
        }
        // Aquí deberías manejar la navegación para los ítems con index negativo
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Resumen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Transacciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.savings),
          label: 'Metas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet), // Icono para cuentas
          label: 'Cuentas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Reportes',
        ),
      ],
    );
  }

  Widget _buildAddTransactionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.indigo,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        // Navegar a pantalla de agregar transacción
      },
    );
  }
}