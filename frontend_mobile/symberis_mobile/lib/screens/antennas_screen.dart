import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AntennasScreen extends StatefulWidget {
  const AntennasScreen({super.key});

  @override
  State<AntennasScreen> createState() => _AntennasScreenState();
}

class _AntennasScreenState extends State<AntennasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSearching = false;
  List<dynamic> _antennes = [];
  String _filter = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAntennes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAntennes() async {
    try {
      final data = await _apiService.get('antennes/');
      setState(() {
        _antennes = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Erreur: $e');
    }
  }

  Color _getColorForStatut(String statut) {
    switch (statut) {
      case 'ACTIF': return const Color(0xFF22C55E);
      case 'EN_ATTENTE': return const Color(0xFF3B82F6);
      case 'ALARME': return const Color(0xFFEF4444);
      case 'HORS_LIGNE': return const Color(0xFF6B7280);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAntennes = _antennes.where((a) {
      final matchesFilter = _filter == 'Tous' || a['statut'].toString().toUpperCase() == _filter.toUpperCase();
      final matchesSearch = a['nom_site'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Rechercher un site...', border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Antennes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tous', 'ACTIF', 'EN_ATTENTE', 'ALARME', 'HORS_LIGNE'].map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: f == _filter,
                      selectedColor: const Color(0xFFEDE9FE),
                      checkmarkColor: const Color(0xFF5B21B6),
                      onSelected: (selected) {
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
              : RefreshIndicator(
                  onRefresh: _fetchAntennes,
                  color: const Color(0xFF5B21B6),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAntennes.length,
                    itemBuilder: (ctx, i) {
                    final a = filteredAntennes[i];
                    final color = _getColorForStatut(a['statut']);
                    return GestureDetector(
                      onTap: () => context.go('/antennes/detail', extra: Map<String, dynamic>.from(a)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Hero(
                                tag: 'antenne_icon_${a['id']}',
                                child: Icon(Icons.cell_tower, color: color, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['nom_site'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('ID: ${a['id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(a['statut'], style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B21B6),
        onPressed: () => context.go('/antennes/nouveau'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B21B6),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/dashboard'); break;
            case 2: context.go('/alarmes'); break;
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.cell_tower), activeIcon: Icon(Icons.cell_tower), label: 'Antennes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined), label: 'Alarmes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rapports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
