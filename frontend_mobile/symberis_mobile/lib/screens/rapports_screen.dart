import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  int _totalAntennes = 0;
  int _activeAntennes = 0;
  int _alarmesCritiques = 0;
  int _interventionsTotal = 0;
  int _interventionsTerminees = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final antennesData = await _apiService.get('antennes/') as List<dynamic>? ?? [];
      final alarmesData = await _apiService.get('alarmes/') as List<dynamic>? ?? [];
      final interventionsData = await _apiService.get('interventions/') as List<dynamic>? ?? [];

      setState(() {
        _totalAntennes = antennesData.length;
        _activeAntennes = antennesData.where((a) => a['statut'] == 'ACTIF').length;
        _alarmesCritiques = alarmesData.where((a) => a['niveau'] == 'CRITIQUE').length;
        _interventionsTotal = interventionsData.length;
        _interventionsTerminees = interventionsData.where((i) => i['statut'] == 'TERMINEE').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double dispoPercent = _totalAntennes > 0 ? (_activeAntennes / _totalAntennes) * 100 : 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Rapports & Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
            tooltip: 'Exporter Antennes (PDF)',
            onPressed: () async {
              try {
                final antennes = await _apiService.get('antennes/') as List<dynamic>? ?? [];
                await ExportService.exportAntennasToPdf(antennes);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view, color: Color(0xFF22C55E)),
            tooltip: 'Exporter Alarmes (Excel)',
            onPressed: () async {
              try {
                final alarmes = await _apiService.get('alarmes/') as List<dynamic>? ?? [];
                await ExportService.exportAlarmesToExcel(alarmes);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Excel : $e')));
              }
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vue Générale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatCard(title: 'Disponibilité', value: '${dispoPercent.toStringAsFixed(1)}%', color: const Color(0xFF22C55E), icon: Icons.speed),
                    const SizedBox(width: 12),
                    _StatCard(title: 'Alarmes Critiques', value: '$_alarmesCritiques', color: const Color(0xFFEF4444), icon: Icons.warning),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Répartition des Antennes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(color: const Color(0xFF22C55E), value: _activeAntennes.toDouble(), title: '$_activeAntennes', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              PieChartSectionData(color: const Color(0xFF6B7280), value: (_totalAntennes - _activeAntennes).toDouble(), title: '${_totalAntennes - _activeAntennes}', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(color: const Color(0xFF22C55E), label: 'Actives'),
                          const SizedBox(height: 8),
                          _LegendItem(color: const Color(0xFF6B7280), label: 'Inactives/Autres'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Interventions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total des interventions', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('$_interventionsTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interventions terminées', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('$_interventionsTerminees', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B21B6),
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/antennes'); break;
            case 2: context.go('/alarmes'); break;
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cell_tower), label: 'Antennes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined), label: 'Alarmes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), activeIcon: Icon(Icons.bar_chart), label: 'Rapports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
