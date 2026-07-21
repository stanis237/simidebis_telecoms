import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'alarme_detail_screen.dart';

class AlarmesScreen extends StatefulWidget {
  const AlarmesScreen({super.key});

  @override
  State<AlarmesScreen> createState() => _AlarmesScreenState();
}

class _AlarmesScreenState extends State<AlarmesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _alarmes = [];
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _fetchAlarmes();
  }

  Future<void> _fetchAlarmes() async {
    try {
      final data = await _apiService.get('alarmes/');
      setState(() {
        _alarmes = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Erreur: $e');
    }
  }

  Color _getColorForNiveau(String niveau) {
    switch (niveau) {
      case 'MINEURE': return const Color(0xFF3B82F6);
      case 'MAJEURE': return const Color(0xFFF59E0B);
      case 'CRITIQUE': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlarmes = _filter == 'Toutes' 
        ? _alarmes 
        : _alarmes.where((a) {
            final niv = a['niveau'].toString();
            if (_filter == 'Critiques') return niv == 'CRITIQUE';
            if (_filter == 'Majeures') return niv == 'MAJEURE';
            if (_filter == 'Mineures') return niv == 'MINEURE';
            return true;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Alarmes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Toutes', 'Critiques', 'Majeures', 'Mineures'].map((f) {
                  final isSelected = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: const Color(0xFFEDE9FE),
                      checkmarkColor: const Color(0xFF5B21B6),
                      onSelected: (_) {
                        setState(() {
                          _filter = f;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAlarmes.length,
                  itemBuilder: (ctx, i) {
                    final a = filteredAlarmes[i];
                    final color = _getColorForNiveau(a['niveau'] ?? '');
                    return GestureDetector(
                      onTap: () => context.go('/alarmes/detail', extra: Map<String, dynamic>.from(a)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.warning_amber, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['type_alarme'] ?? 'Alarme inconnue', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('Antenne ID: ${a['antenne']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(a['niveau'] ?? '', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 4),
                                Text((a['date_alarme'] ?? '').toString().split('T').first, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B21B6),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/antennes'); break;
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cell_tower), label: 'Antennes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined), activeIcon: Icon(Icons.warning), label: 'Alarmes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rapports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
