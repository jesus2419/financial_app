import 'package:flutter/material.dart';
import 'manageuser.dart'; // Asegúrate de importar tu pantalla de gestión

class HomeScreen extends StatelessWidget {
  final String name;
  
  const HomeScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          // Botón en el AppBar (opcional)
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DatabaseManagerScreen()),
              );
            },
            tooltip: 'Gestionar base de datos',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Hola, $name!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Bienvenido/a a la aplicación'),
            const SizedBox(height: 32),
            // Botón principal para gestionar BD
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DatabaseManagerScreen()),
                );
              },
              icon: const Icon(Icons.storage),
              label: const Text('Gestionar Base de Datos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón secundario alternativo
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DatabaseManagerScreen()),
                );
              },
              child: const Text('Ver todos los usuarios'),
            ),
          ],
        ),
      ),
      // Botón flotante alternativo
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DatabaseManagerScreen()),
          );
        },
        tooltip: 'Gestionar usuarios',
        child: const Icon(Icons.people),
      ),
    );
  }
}