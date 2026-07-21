import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../services/api_service.dart';

class NewAntennaScreen extends StatefulWidget {
  const NewAntennaScreen({super.key});
  @override
  State<NewAntennaScreen> createState() => _NewAntennaScreenState();
}

class _TargetSite {
  final int id;
  final double lat, lon, alt;
  final String name;
  _TargetSite(this.id, this.lat, this.lon, this.alt, this.name);
}

class _NewAntennaScreenState extends State<NewAntennaScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nameController = TextEditingController();
  final _latController  = TextEditingController();
  final _lonController  = TextEditingController();
  final _altController  = TextEditingController();
  final _freqController = TextEditingController();
  final _aziController  = TextEditingController();
  final _tiltController = TextEditingController();
  final _diametreController = TextEditingController();
  final _configController = TextEditingController();
  
  String _selectedStatut = 'ACTIF';
  bool _isSaving = false;
  List<_TargetSite> _existingSites = [];
  _TargetSite? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _loadExistingSites();
    _latController.addListener(_autoCalculate);
    _lonController.addListener(_autoCalculate);
    _altController.addListener(_autoCalculate);
  }

  Future<void> _loadExistingSites() async {
    try {
      final data = await _apiService.get('antennes/');
      if (data != null && data is List) {
        setState(() {
          _existingSites = data.map((s) => _TargetSite(
            s['id'] ?? 0,
            double.tryParse(s['latitude'].toString()) ?? 0,
            double.tryParse(s['longitude'].toString()) ?? 0,
            double.tryParse(s['altitude']?.toString() ?? '0') ?? 0,
            s['nom_site'] ?? 'Inconnu'
          )).toList();
        });
      }
    } catch (_) {}
  }

  void _autoCalculate() {
    final lat = double.tryParse(_latController.text.replaceAll(',', '.'));
    final lon = double.tryParse(_lonController.text.replaceAll(',', '.'));
    final alt = double.tryParse(_altController.text.replaceAll(',', '.')) ?? 0;

    if (lat == null || lon == null || _existingSites.isEmpty) return;

    if (_selectedTarget == null) {
      _TargetSite? nearest;
      double minDist = double.infinity;
      for (var site in _existingSites) {
        final d = _haversine(lat, lon, site.lat, site.lon);
        if (d < minDist) {
          minDist = d;
          nearest = site;
        }
      }
      _selectedTarget = nearest;
    }

    if (_selectedTarget != null) {
      final dist = _haversine(lat, lon, _selectedTarget!.lat, _selectedTarget!.lon);
      final azi = _calculateAzimuth(lat, lon, _selectedTarget!.lat, _selectedTarget!.lon);
      final tilt = _calculateTilt(alt, _selectedTarget!.alt, dist);
      
      setState(() {
        _aziController.text = azi.toStringAsFixed(1);
        _tiltController.text = tilt.toStringAsFixed(2);
      });
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _calculateAzimuth(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;
    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  double _calculateTilt(double alt1, double alt2, double distKm) {
    if (distKm < 0.001) return 0;
    return atan((alt2 - alt1) / (distKm * 1000)) * 180 / pi;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _altController.dispose();
    _freqController.dispose();
    _aziController.dispose();
    _tiltController.dispose();
    _diametreController.dispose();
    _configController.dispose();
    super.dispose();
  }

  Future<void> _saveAntenna() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _apiService.post('antennes/', {
        'nom_site':  _nameController.text.trim(),
        'latitude':  double.parse(_latController.text.trim().replaceAll(',', '.')),
        'longitude': double.parse(_lonController.text.trim().replaceAll(',', '.')),
        if (_altController.text.trim().isNotEmpty)
          'altitude': double.parse(_altController.text.trim().replaceAll(',', '.')),
        if (_freqController.text.trim().isNotEmpty)
          'frequence': _freqController.text.trim(),
        'azimuth': double.tryParse(_aziController.text),
        'tilt': double.tryParse(_tiltController.text),
        'diametre': double.tryParse(_diametreController.text.replaceAll(',', '.')),
        'type_configuration': _configController.text.trim(),
        'statut': _selectedStatut,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antenne enregistrée !'), backgroundColor: Color(0xFF22C55E)),
      );
      context.go('/antennes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouvelle antenne', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Coordonnées Géo-satellitaires', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6))),
                    const SizedBox(height: 16),
                    _buildField('Nom du site *', _nameController, hint: 'Ex: Site Nord 01'),
                    Row(
                      children: [
                        Expanded(child: _buildField('Latitude *', _latController, hint: '3.84', keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Longitude *', _lonController, hint: '11.5', keyboardType: TextInputType.number)),
                      ],
                    ),
                    _buildField('Altitude (m) *', _altController, hint: '650', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spécifications Techniques', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6))),
                    const SizedBox(height: 16),
                    _buildField('Diamètre Antenne (m)', _diametreController, hint: '0.6', keyboardType: TextInputType.number),
                    _buildField('Type Configuration', _configController, hint: 'Ex: 1+0, 1+1'),
                    _buildField('Fréquence (GHz)', _freqController, hint: '23'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alignement Automatique', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6))),
                    const SizedBox(height: 12),
                    if (_existingSites.isNotEmpty) ...[
                      const Text('Pointer vers le site :', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<_TargetSite>(
                        isExpanded: true,
                        value: _selectedTarget,
                        hint: const Text('Choisir une antenne cible'),
                        items: _existingSites.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedTarget = v;
                            _autoCalculate();
                          });
                        },
                      ),
                    ] else
                      const Text('Aucune autre antenne disponible pour l\'alignement.', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Azimut théorique', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              TextField(controller: _aziController, decoration: const InputDecoration(suffixText: '°'), readOnly: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Inclinaison (Tilt)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              TextField(controller: _tiltController, decoration: const InputDecoration(suffixText: '°'), readOnly: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAntenna,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B21B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer l\'antenne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => (v == null && label.contains('*')) ? 'Champ requis' : null,
      ),
    );
  }
}
