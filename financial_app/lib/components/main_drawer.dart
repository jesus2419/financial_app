import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import '../view/category_crud_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database/database_handler.dart';

class MainDrawer extends StatefulWidget {
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

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  late String _userName;
  String? _userImagePath;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _loadUserImage();
  }

  Future<void> _loadUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userImagePath = prefs.getString('userImagePath');
    });
  }

  Future<void> _editUserInfo() async {
    final nameController = TextEditingController(text: _userName);
    String? tempImagePath = _userImagePath;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    tempImagePath = picked.path;
                    setState(() {
                      _userImagePath = picked.path;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: tempImagePath != null
                      ? FileImage(File(tempImagePath!))
                      : null,
                  child: tempImagePath == null
                      ? const Icon(Icons.person, size: 40, color: Colors.indigo)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userName', nameController.text.trim());
                if (tempImagePath != null) {
                  await prefs.setString('userImagePath', tempImagePath!);
                }
                setState(() {
                  _userName = nameController.text.trim();
                  _userImagePath = tempImagePath;
                });
                Navigator.pop(context);
                // Opcional: recargar la app para reflejar el cambio globalmente
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Elimina SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Cierra y elimina base de datos
    try {
      if (DatabaseHandler.databaseInstance != null) {
        await DatabaseHandler.databaseInstance!.close();
        DatabaseHandler.databaseInstance = null;
      }
    } catch (_) {
      // Ignora errores de cierre
    }
    final dbPath = await getDatabasesPath();
    final dbFile = '$dbPath/DB_super';
    await deleteDatabase(dbFile);

    // Elimina caché
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }

    // Opcional: elimina archivos de app support (más limpieza)
    final appSupportDir = await getApplicationSupportDirectory();
    if (appSupportDir.existsSync()) {
      appSupportDir.deleteSync(recursive: true);
    }

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
                GestureDetector(
                  onTap: _editUserInfo,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: _userImagePath != null
                        ? FileImage(File(_userImagePath!))
                        : null,
                    child: _userImagePath == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.indigo,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Editar perfil',
                      onPressed: _editUserInfo,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', 0),
          _buildDrawerItem(context, Icons.list_alt, 'Transacciones', 1),
          _buildDrawerItem(context, Icons.savings, 'Metas de Ahorro', 2),
          _buildDrawerItem(context, Icons.bar_chart, 'Reportes', 4),
          const Divider(),
          _buildDrawerItem(
            context,
            Icons.account_balance_wallet,
            'Mis Cuentas',
            3,
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorías'),
            selected: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoryCrudScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
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
      selected: widget.selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          widget.onSectionTap(index);
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
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión? Se borrarán todos los datos de la sesión actual.',
          ),
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
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }
}
