import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoItem('Nom d\'utilisateur', _currentUser?['username'] ?? '—'),
            _infoItem('Email', _currentUser?['email'] ?? 'Non renseigné'),
            _infoItem('Rôle', _currentUser?['role'] ?? '—'),
            _infoItem('Date d\'inscription', _currentUser?['date_joined']?.toString().split('T').first ?? '—'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String username = _currentUser?['username'] ?? 'Utilisateur';
    final String role = _currentUser?['role'] ?? 'TECHNICIEN';
    final bool isAdmin = role == 'ADMIN';

    Color roleColor = const Color(0xFF22C55E);
    String roleLabel = 'Technicien';
    if (role == 'ADMIN') {
      roleColor = const Color(0xFFF59E0B);
      roleLabel = 'Admin Orange';
    } else if (role == 'MANAGER') {
      roleColor = const Color(0xFF3B82F6);
      roleLabel = 'Manager PME';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 50, color: roleColor),
                  ),
                  const SizedBox(height: 12),
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(roleLabel, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu items
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Informations personnelles',
                    onTap: _showInfoDialog,
                  ),
                  const Divider(height: 1, indent: 52),
                  if (isAdmin) ...[
                    _MenuItem(
                      icon: Icons.people_outline,
                      label: 'Gestion des utilisateurs',
                      onTap: () => context.go('/users'),
                    ),
                    const Divider(height: 1, indent: 52),
                    _MenuItem(
                      icon: Icons.history_edu,
                      label: 'Journal d\'audit système',
                      onTap: () => context.push('/audit'),
                    ),
                    const Divider(height: 1, indent: 52),
                  ],
                  _MenuItem(
                    icon: Icons.security,
                    label: 'Sécurité',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonction de changement de mot de passe à venir')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () async {
                      await _notificationService.requestPermissions();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Préférences de notifications mises à jour')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                  _MenuItem(
                    icon: Icons.language,
                    label: 'Langue',
                    trailing: 'Français',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(leading: const Icon(Icons.language), title: const Text('Français'), onTap: () => Navigator.pop(context)),
                              ListTile(leading: const Icon(Icons.language), title: const Text('English'), onTap: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                  _MenuItem(
                    icon: Icons.info_outline,
                    label: 'À propos',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'SIMIDEBIS NETWORK',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.cell_tower, color: Color(0xFF5B21B6), size: 40),
                        children: [
                          const Text('Solution de supervision de réseau télécom.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: _MenuItem(
                icon: Icons.logout,
                label: 'Déconnexion',
                color: const Color(0xFFEF4444),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B21B6),
        unselectedItemColor: Colors.grey,
        currentIndex: 4,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/antennes'); break;
            case 2: context.go('/alarmes'); break;
            case 3: context.go('/rapports'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cell_tower), label: 'Antennes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined), label: 'Alarmes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rapports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1F2937);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: Colors.grey, fontSize: 13))
          : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
