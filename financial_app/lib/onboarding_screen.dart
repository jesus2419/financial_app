import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Bienvenido a neneros tu App Financiera',
      description:
          'Gestiona tus cuentas, ingresos y gastos de manera sencilla y visual.',
      image: Icons.account_balance_wallet,
    ),
    _OnboardingPage(
      title: 'Transacciones rápidas',
      description:
          'Registra ingresos y gastos, clasifícalos por categorías y consulta tu historial.',
      image: Icons.list_alt,
    ),
    _OnboardingPage(
      title: 'Metas de ahorro',
      description:
          'Crea metas, visualiza tu progreso y motívate a ahorrar más cada mes.',
      image: Icons.savings,
    ),
    _OnboardingPage(
      title: 'Reportes y gráficas',
      description:
          'Analiza tus finanzas con reportes visuales y toma mejores decisiones.',
      image: Icons.bar_chart,
    ),
    _OnboardingPage(
      title: '¡No olvides agregar una cuenta!',
      description:
          'Para empezar a gestionar tu dinero, primero debes agregar al menos una cuenta (efectivo o débito). Así podrás registrar tus movimientos y ver tu saldo actualizado.',
      image: Icons.add_card,
    ),
    _OnboardingPage(
      title: '¡Comienza ahora!',
      description:
          'Personaliza tu perfil y explora todas las funciones de la app.',
      image: Icons.emoji_emotions,
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.indigo[100],
                          child: Icon(
                            page.image,
                            size: 64,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 16,
                  ),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.indigo
                        : Colors.indigo[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.ease,
                        );
                      },
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _finishOnboarding
                        : () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.ease,
                            );
                          },
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Empezar'
                          : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
