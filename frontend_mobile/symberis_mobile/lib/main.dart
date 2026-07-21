import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lancer l'initialisation en parallèle pour ne pas bloquer le runApp
  NotificationService().init();

  runApp(const SimidebisApp());
}

class SimidebisApp extends StatelessWidget {
  const SimidebisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Simidebis Network',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
