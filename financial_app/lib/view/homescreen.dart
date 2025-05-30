import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dashboard_section.dart';
import 'transactions_section.dart';
import 'goals_section.dart';
import 'reports_section.dart';
import 'accounts_section.dart';
import '../database/database_handler.dart';
import '../components/main_drawer.dart';

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

  final double _totalBalance = 12500.50;

  // 1. GlobalKey para acceder al estado de AccountsSection
  final GlobalKey<AccountsSectionState> _accountsKey =
      GlobalKey<AccountsSectionState>();

  // 2. Usa el key al crear AccountsSection
  late final List<Widget> _appSections = [
    const DashboardSection(),
    const TransactionsSection(),
    const GoalsSection(),
    AccountsSection(key: _accountsKey),
    const ReportsSection(),
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
    DatabaseHandler.instance.getAllAccounts();
  }

  PreferredSizeWidget _buildAppBar() {
    // AppBar dinámico según la sección seleccionada
    if (_selectedIndex == 1) {
      // Transacciones
      return AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ); // AppBar vacío para cumplir con el tipo
    }
    if (_selectedIndex == 3) {
      // Cuentas
      return AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ); // AppBar vacío, lo maneja internamente AccountsSection
    }
    // AppBar por defecto
    return AppBar(
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
        IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _selectedIndex == 1 ? null : _buildAppBar(),
      drawer: MainDrawer(
        userName: widget.userName,
        totalBalance: _currencyFormat.format(_totalBalance),
        selectedIndex: _selectedIndex,
        onSectionTap: _onItemTapped,
      ),
      body: _appSections[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      //floatingActionButton: _selectedIndex == 1 ? _buildAddTransactionButton() : null,
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
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Resumen'),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Transacciones',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Metas'),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet), // Icono para cuentas
          label: 'Cuentas',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      ],
    );
  }
}
