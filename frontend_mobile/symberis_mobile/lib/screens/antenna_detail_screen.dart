import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AntennaDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? antenne;
  const AntennaDetailScreen({super.key, this.antenne});

  @override
  State<AntennaDetailScreen> createState() => _AntennaDetailScreenState();
}

class _AntennaDetailScreenState extends State<AntennaDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _apiService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    }
  }

  Color _colorForStatut(String? statut) {
    switch (statut) {
      case 'ACTIF':       return const Color(0xFF22C55E);
      case 'EN_ATTENTE':  return const Color(0xFF3B82F6);
      case 'ALARME':      return const Color(0xFFEF4444);
      case 'HORS_LIGNE':  return const Color(0xFF6B7280);
      default:            return Colors.grey;
    }
  }

  String _labelStatut(String? statut) {
    switch (statut) {
      case 'ACTIF':       return 'Actif';
      case 'EN_ATTENTE':  return 'En attente';
      case 'ALARME':      return 'Alarme';
      case 'HORS_LIGNE':  return 'Hors ligne';
      default:            return statut ?? '—';
    }
  }

  Future<void> _deleteAntenna() async {
    final id = widget.antenne?['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'antenne ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('antennes/$id/');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Antenne supprimée')),
          );
          context.go('/antennes');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.antenne ?? {};
    final statut = a['statut'] as String?;
    final color  = _colorForStatut(statut);
    final bool canDelete = _currentUser?['role'] == 'ADMIN' || _currentUser?['role'] == 'MANAGER';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/antennes'),
          ),
          title: Text(
            a['nom_site']?.toString() ?? 'Détail antenne',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (!_isLoadingUser && canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteAntenna,
              ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF5B21B6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF5B21B6),
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Monitoring'),
              Tab(text: 'Alarmes'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfosTab(a, color),
            _buildMonitoringTab(),
            _buildAlarmesTab(a['id']),
            _buildHistoriqueTab(a['id']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosTab(Map<String, dynamic> a, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Information Site', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Divider(),
                _InfoRow(label: 'Nom du site', value: a['nom_site']?.toString() ?? '—'),
                _InfoRow(label: 'Latitude', value: a['latitude']?.toString() ?? '—'),
                _InfoRow(label: 'Longitude', value: a['longitude']?.toString() ?? '—'),
                _InfoRow(label: 'Altitude', value: a['altitude'] != null ? '${a['altitude']} m' : '—'),
                _InfoRow(label: 'Statut', value: _labelStatut(a['statut']), valueColor: color),
                const SizedBox(height: 16),
                const Text('Configuration Radio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Divider(),
                _InfoRow(label: 'Diamètre', value: '${a['diametre'] ?? '—'} m'),
                _InfoRow(label: 'Configuration', value: a['type_configuration'] ?? '1+0'),
                _InfoRow(label: 'Fréquence', value: '${a['frequence'] ?? '—'} GHz'),
                _InfoRow(label: 'Polarisation', value: a['polarisation'] ?? 'Verticale'),
                _InfoRow(label: 'Downtilt', value: '${a['downtilt'] ?? '0'}°'),
                _InfoRow(label: 'Puissance TX', value: '${a['puissance_tx'] ?? '20'} dBm'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Périmètre de Sécurité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rayonnement de sécurité', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                      Text('Périmètre d\'exclusion recommandé : ${((double.tryParse(a['puissance_tx']?.toString() ?? '20') ?? 20) * 0.15).toStringAsFixed(1)} mètres.', 
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectorization(a),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.map, size: 50, color: Colors.grey.shade300)),
                  Positioned.fill(
                    child: Image.network(
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-s+5B21B6(${a['longitude']},${a['latitude']})/${a['longitude']},${a['latitude']},14/600x300?access_token=YOUR_MAPBOX_TOKEN_HERE',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, s) => Container(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorization(Map<String, dynamic> a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sectorisation (120°)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sectorIcon('S1 (0°)', Colors.blue),
              _sectorIcon('S2 (120°)', Colors.green),
              _sectorIcon('S3 (240°)', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectorIcon(String label, Color color) {
    return Column(
      children: [
        Icon(Icons.pie_chart_outline, color: color, size: 30),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performances (24h)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 20, top: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3), const FlSpot(2, 4), const FlSpot(4, 3.5),
                      const FlSpot(6, 5), const FlSpot(8, 4.5), const FlSpot(10, 4),
                      const FlSpot(12, 4.8),
                    ],
                    isCurved: true,
                    color: const Color(0xFF5B21B6),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF5B21B6).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Trafic Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _MetricTile(label: 'Débit descendant', value: '450 Mbps', icon: Icons.download, color: Colors.blue),
          _MetricTile(label: 'Débit ascendant', value: '82 Mbps', icon: Icons.upload, color: Colors.green),
          _MetricTile(label: 'Latence', value: '12 ms', icon: Icons.timer, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildAlarmesTab(dynamic antennaId) {
    return FutureBuilder(
      future: _apiService.get('alarmes/'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allAlarmes = snapshot.data as List<dynamic>? ?? [];
        final siteAlarmes = allAlarmes.where((al) => al['antenne'] == antennaId).toList();
        
        if (siteAlarmes.isEmpty) return const Center(child: Text('Aucune alarme pour ce site.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: siteAlarmes.length,
          itemBuilder: (context, i) {
            final al = siteAlarmes[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.warning, color: al['niveau'] == 'CRITIQUE' ? Colors.red : Colors.orange),
                title: Text(al['type_alarme'] ?? 'Alarme'),
                subtitle: Text(al['date_alarme'].toString().substring(0, 16)),
                trailing: Text(al['statut']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoriqueTab(dynamic antennaId) {
    return FutureBuilder(
      future: _apiService.get('historiques/'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allHist = snapshot.data as List<dynamic>? ?? [];
        final siteHist = allHist.where((h) => h['antenne'] == antennaId).toList();

        if (siteHist.isEmpty) return const Center(child: Text('Aucun historique.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: siteHist.length,
          itemBuilder: (context, i) {
            final h = siteHist[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.history, size: 20)),
              title: Text(h['description'] ?? ''),
              subtitle: Text(h['date_evenement'].toString().substring(0, 16)),
            );
          },
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor)),
        ],
      ),
    );
  }
}
