import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Réduire le délai à 500ms (juste pour l'effet visuel)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    // On va directement au dashboard, le routeur redirigera vers login si pas connecté
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF5B21B6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cell_tower, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text('SIMIDEBIS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('NETWORK', style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 4)),
          ],
        ),
      ),
    );
  }
}
