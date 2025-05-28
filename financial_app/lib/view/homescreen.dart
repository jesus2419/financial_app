import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MainScreen extends StatefulWidget {
  final String userName;
  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  DateTime _currentDate = DateTime.now();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');
  bool _localeReady = false;

  // Datos de ejemplo (deberías reemplazarlos con tus modelos reales)
  final double _totalBalance = 12500.50;
  final Map<String, double> _accountBalances = {
    'Efectivo': 3500.00,
    'Banco ABC': 7000.50,
    'Tarjeta Crédito': -2000.00,
  };

  static const List<Widget> _appSections = [
    DashboardSection(),
    TransactionsSection(),
    GoalsSection(),
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

// Secciones de la aplicación (deberías mover cada una a su propio archivo)
class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});  // Añade const y key
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista de Resumen'));
  }
}

class TransactionsSection extends StatelessWidget {
    const TransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista de Transacciones'));
  }
}

class GoalsSection extends StatelessWidget {
    const GoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista de Metas de Ahorro'));
  }
}

class ReportsSection extends StatelessWidget {
    const ReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista de Reportes'));
  }
}