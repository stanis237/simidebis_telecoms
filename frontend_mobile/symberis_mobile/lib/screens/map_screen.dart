import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _antennes = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchAntennes();
  }

  Future<void> _fetchAntennes() async {
    try {
      final data = await _apiService.get('antennes/');
      setState(() {
        _antennes = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _showAntennaDetails(dynamic antenne) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final color = _getColorForStatut(antenne['statut'] ?? '');
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(antenne['nom_site'] ?? 'Inconnu', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(antenne['statut'] ?? '', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('ID: ${antenne['id']}'),
              const SizedBox(height: 10),
              Text('Coordonnées: ${antenne['latitude']}, ${antenne['longitude']}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calcul de l'itinéraire en cours...")));
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Itinéraire d'intervention", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B21B6), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Antennes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _antennes.isNotEmpty 
                    ? LatLng(double.parse(_antennes[0]['latitude'].toString()), double.parse(_antennes[0]['longitude'].toString()))
                    : const LatLng(3.8480, 11.5021), // Default Yaoundé
                initialZoom: 6.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.simidebis.network',
                ),
                MarkerLayer(
                  markers: _antennes.map((a) {
                    final lat = double.tryParse(a['latitude'].toString()) ?? 0;
                    final lng = double.tryParse(a['longitude'].toString()) ?? 0;
                    final color = _getColorForStatut(a['statut'] ?? '');
                    
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showAntennaDetails(a),
                        child: Icon(Icons.location_on, color: color, size: 40),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
