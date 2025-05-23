import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String name;
  
  const HomeScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¡Hola, $name!'),
            const Text('Bienvenido/a')
          ],
        ),
      ),
    );
  }
}