import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/antennas_screen.dart';
import '../screens/antenna_detail_screen.dart';
import '../screens/new_antenna_screen.dart';
import '../screens/alarmes_screen.dart';
import '../screens/alarme_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/interconnexion_screen.dart';
import '../screens/map_screen.dart';
import '../screens/users_screen.dart';
import '../screens/new_user_screen.dart';
import '../screens/rapports_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/audit_log_screen.dart';
import '../screens/notifications_screen.dart';

final _apiService = ApiService();

/// Routes publiques accessibles sans authentification
const _publicRoutes = ['/', '/onboarding', '/login'];

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final isPublic = _publicRoutes.contains(state.matchedLocation);
    final isAuthenticated = await _apiService.isAuthenticated();

    // Utilisateur non connecté tentant d'accéder à une page privée
    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    // Utilisateur déjà connecté tentant d'accéder au login, à la splash ou à l'onboarding
    if (isAuthenticated && (state.matchedLocation == '/login' || state.matchedLocation == '/' || state.matchedLocation == '/onboarding')) {
      return '/dashboard';
    }

    return null; // Pas de redirection
  },
  routes: [
    GoRoute(path: '/',           builder: (ctx, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (ctx, s) => const OnboardingScreen()),
    GoRoute(path: '/login',      builder: (ctx, s) => const LoginScreen()),
    GoRoute(path: '/role-selection', builder: (ctx, s) => const RoleSelectionScreen()),
    GoRoute(path: '/dashboard',  builder: (ctx, s) => const DashboardScreen()),

    // ── Antennes ─────────────────────────────────────────────────────────────
    GoRoute(path: '/antennes',   builder: (ctx, s) => const AntennasScreen()),
    GoRoute(
      path: '/antennes/detail',
      builder: (ctx, s) {
        final antenne = s.extra as Map<String, dynamic>?;
        return AntennaDetailScreen(antenne: antenne);
      },
    ),
    GoRoute(path: '/antennes/nouveau', builder: (ctx, s) => const NewAntennaScreen()),

    // ── Alarmes ───────────────────────────────────────────────────────────────
    GoRoute(path: '/alarmes',    builder: (ctx, s) => const AlarmesScreen()),
    GoRoute(
      path: '/alarmes/detail',
      builder: (ctx, s) {
        final alarme = s.extra as Map<String, dynamic>?;
        return AlarmeDetailScreen(alarme: alarme);
      },
    ),

    // ── Autres ────────────────────────────────────────────────────────────────
    GoRoute(path: '/profile',        builder: (ctx, s) => const ProfileScreen()),
    GoRoute(path: '/interconnexion', builder: (ctx, s) => const InterconnexionScreen()),
    GoRoute(path: '/map',            builder: (ctx, s) => const MapScreen()),
    GoRoute(path: '/users',          builder: (ctx, s) => const UsersScreen()),
    GoRoute(path: '/users/new',      builder: (ctx, s) => const NewUserScreen()),
    GoRoute(path: '/rapports',       builder: (ctx, s) => const RapportsScreen()),
    GoRoute(path: '/qr-scanner',     builder: (ctx, s) => const QrScannerScreen()),
    GoRoute(path: '/audit',          builder: (ctx, s) => const AuditLogScreen()),
    GoRoute(path: '/notifications',  builder: (ctx, s) => const NotificationsScreen()),
  ],
);
