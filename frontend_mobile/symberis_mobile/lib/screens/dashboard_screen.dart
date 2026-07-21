import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _currentUser;
  
  List<dynamic> _antennes = [];
  List<dynamic> _alarmes = [];
  List<dynamic> _interconnexions = [];
  List<dynamic> _interventions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Chargement en parallèle de toutes les données nécessaires au dashboard
      final results = await Future.wait([
        _apiService.getCurrentUser(),
        _apiService.get('antennes/'),
        _apiService.get('alarmes/'),
        _apiService.get('interconnexions/'),
        _apiService.get('interventions/'),
      ]);

      if (mounted) {
        setState(() {
          _currentUser = results[0] as Map<String, dynamic>?;
          _antennes = results[1] as List<dynamic>? ?? [];
          _alarmes = results[2] as List<dynamic>? ?? [];
          _interconnexions = results[3] as List<dynamic>? ?? [];
          _interventions = results[4] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCompleteIntervention(dynamic inter) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clôturer l\'intervention', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Site ID: ${inter['antenne']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Rapport technique (ex: Remplacement câble terminé)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _apiService.patch('interventions/${inter['id']}/', {'statut': 'TERMINEE'});
                    // Ajouter à l'historique
                    await _apiService.post('historiques/', {
                      'antenne': inter['antenne'],
                      'description': 'Intervention terminée: ${commentController.text}',
                      'type_evenement': 'MAINTENANCE'
                    });
                    if (mounted) Navigator.pop(ctx);
                    _fetchData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Intervention clôturée avec succès !')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Erreur: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Valider la fin de mission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _currentUser?['role'] ?? 'TECHNICIEN';
    final username = _currentUser?['username'] ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Bonjour, $username', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: role == 'ADMIN' ? const Color(0xFFF59E0B) : (role == 'MANAGER' ? const Color(0xFF3B82F6) : const Color(0xFF22C55E)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role == 'ADMIN' ? 'Orange' : (role == 'MANAGER' ? 'PME' : 'Technicien'),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Text(DateTime.now().toString().substring(0, 10), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.map_outlined, color: Colors.black), onPressed: () => context.go('/map')),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF5B21B6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildDashboardContent(role),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B21B6),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0: break;
            case 1: context.go('/antennes'); break;
            case 2: context.go('/alarmes'); break;
            case 3: context.go('/rapports'); break;
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cell_tower), label: 'Antennes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined), label: 'Alarmes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rapports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
      floatingActionButton: (role == 'ADMIN' || role == 'TECHNICIEN') 
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/qr-scanner'),
              backgroundColor: const Color(0xFF5B21B6),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Scan QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildDashboardContent(String role) {
    if (role == 'ADMIN') {
      return _buildAdminDashboard();
    } else if (role == 'MANAGER') {
      return _buildManagerDashboard();
    } else {
      return _buildTechnicienDashboard();
    }
  }

  // ─── ADMIN (Orange) ────────────────────────────────────────────────────────

  Widget _buildAdminDashboard() {
    int actifs = _antennes.where((a) => a['statut'] == 'ACTIF').length;
    int enAttente = _antennes.where((a) => a['statut'] == 'EN_ATTENTE').length;
    int enAlarme = _antennes.where((a) => a['statut'] == 'ALARME').length;
    int horsLigne = _antennes.where((a) => a['statut'] == 'HORS_LIGNE').length;
    int total = _antennes.isNotEmpty ? _antennes.length : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message Flash de Direction
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.campaign, color: Color(0xFFEA580C)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Maintenance nationale prévue ce dimanche à 02h00.',
                  style: TextStyle(color: Color(0xFF9A3412), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const Text('Vue Globale du Réseau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(label: 'Antennes', value: _antennes.length.toString(), color: const Color(0xFF5B21B6), icon: Icons.cell_tower),
            const SizedBox(width: 12),
            _StatCard(label: 'Alarmes', value: _alarmes.length.toString(), color: const Color(0xFFEF4444), icon: Icons.warning_amber),
            const SizedBox(width: 12),
            _StatCard(label: 'Connexions', value: _interconnexions.length.toString(), color: const Color(0xFF22C55E), icon: Icons.link),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Actions Rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAction(icon: Icons.add_location_alt_outlined, label: 'Nouveau site', color: Colors.blue, onTap: () => context.go('/antennes/nouveau')),
            _QuickAction(icon: Icons.alt_route_outlined, label: 'Liaison', color: Colors.orange, onTap: () => context.go('/interconnexion')),
            _QuickAction(icon: Icons.map_outlined, label: 'Carte', color: Colors.green, onTap: () => context.go('/map')),
            _QuickAction(icon: Icons.analytics_outlined, label: 'Rapports', color: Colors.purple, onTap: () => context.go('/rapports')),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Performance (SLA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Disponibilité du réseau', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${((actifs/total)*100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: actifs/total,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('État du réseau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(value: actifs.toDouble(), color: const Color(0xFF22C55E), title: '', radius: 25),
                      PieChartSectionData(value: enAttente.toDouble(), color: const Color(0xFF3B82F6), title: '', radius: 25),
                      PieChartSectionData(value: enAlarme.toDouble(), color: const Color(0xFFF59E0B), title: '', radius: 25),
                      PieChartSectionData(value: horsLigne.toDouble(), color: const Color(0xFFEF4444), title: '', radius: 25),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(color: const Color(0xFF22C55E), label: 'Actif', percent: '${(actifs/total * 100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    _LegendItem(color: const Color(0xFF3B82F6), label: 'Attente', percent: '${(enAttente/total * 100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    _LegendItem(color: const Color(0xFFEF4444), label: 'Hors ligne', percent: '${(horsLigne/total * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── MANAGER (PME) ────────────────────────────────────────────────────────

  Widget _buildManagerDashboard() {
    int interventionsEnCours = _interventions.where((i) => i['statut'] == 'EN_COURS').length;
    int alarmesCritiques = _alarmes.where((a) => a['niveau'] == 'CRITIQUE' && a['statut'] != 'RESOLUE').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Synthèse Partenaire (PME)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(label: 'Mes sites', value: _antennes.length.toString(), color: const Color(0xFF3B82F6), icon: Icons.location_city),
            const SizedBox(width: 12),
            _StatCard(label: 'Interventions', value: interventionsEnCours.toString(), color: const Color(0xFFF59E0B), icon: Icons.engineering),
            const SizedBox(width: 12),
            _StatCard(label: 'Urgences', value: alarmesCritiques.toString(), color: const Color(0xFFEF4444), icon: Icons.notification_important),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Performance Équipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Column(
            children: [
              _TaskRow(label: 'Résolution alarmes', value: '88%', color: Colors.green),
              Divider(),
              _TaskRow(label: 'Respect délais', value: '92%', color: Colors.blue),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Alarmes sur mes sites', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_alarmes.isEmpty)
          const Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune alarme en cours.", style: TextStyle(color: Colors.grey)))
        else
          ..._alarmes.take(3).map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _ActivityCard(
                icon: Icons.warning,
                color: a['niveau'] == 'CRITIQUE' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                title: a['type_alarme'] ?? 'Alarme inconnue',
                subtitle: 'Site ID: ${a['antenne']}',
                time: (a['statut'] == 'RESOLUE') ? 'Résolue' : 'En cours',
              ),
            );
          }).toList(),
      ],
    );
  }

  // ─── TECHNICIEN ──────────────────────────────────────────────────────────

  Widget _buildTechnicienDashboard() {
    int totalInter = _interventions.length;
    int terminees = _interventions.where((i) => i['statut'] == 'TERMINEE').length;
    double progress = totalInter > 0 ? terminees / totalInter : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Widget Sécurité/Météo
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Météo : Ensoleillé (28°C)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Condition idéale pour les interventions en hauteur.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Text('Mon Objectif du Jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$terminees / $totalInter Interventions', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${(progress*100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6))),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                color: const Color(0xFF5B21B6),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Outils d\'alignement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.alt_route_outlined, 
              label: 'Azimut & Tilt', 
              color: Colors.orange, 
              onTap: () => context.go('/interconnexion')
            ),
            const SizedBox(width: 12),
            _QuickAction(
              icon: Icons.map_outlined, 
              label: 'Carte sites', 
              color: Colors.green, 
              onTap: () => context.go('/map')
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Dernières interventions assignées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_interventions.isEmpty)
          const Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune intervention assignée.", style: TextStyle(color: Colors.grey)))
        else
          ..._interventions.take(4).map((i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                onTap: i['statut'] != 'TERMINEE' ? () => _showCompleteIntervention(i) : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: i['statut'] == 'TERMINEE' ? Colors.green : Colors.orange, width: 4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(i['statut'] == 'TERMINEE' ? Icons.check_circle : Icons.handyman, color: i['statut'] == 'TERMINEE' ? Colors.green : Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Site ID: ${i['antenne']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(i['description'] ?? 'Pas de description', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text(i['statut'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}

// ─── Composants réutilisables ────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TaskRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label, percent;
  const _LegendItem({required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(percent, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _ActivityCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
