import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Choisissez votre\nrôle', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sélectionnez le rôle qui correspond\nà vos responsabilités', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 40),
              _RoleCard(
                icon: Icons.admin_panel_settings,
                color: const Color(0xFFF59E0B),
                title: 'Orange (Admin)',
                subtitle: 'Accès complet à la plateforme',
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.business_center,
                color: const Color(0xFF3B82F6),
                title: 'PME (Manager)',
                subtitle: 'Gestion des projets et équipes',
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.engineering,
                color: const Color(0xFF6B7280),
                title: 'Technicien',
                subtitle: 'Interventions et monitoring terrain',
                onTap: () => context.go('/dashboard'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B21B6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Continuer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { setState(() => _selected = true); widget.onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selected ? const Color(0xFFEDE9FE) : Colors.white,
          border: Border.all(color: _selected ? const Color(0xFF5B21B6) : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(widget.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (_selected)
              const Icon(Icons.check_circle, color: Color(0xFF5B21B6))
            else
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
