import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:async';
import '../services/api_service.dart';

class InterconnexionScreen extends StatefulWidget {
  const InterconnexionScreen({super.key});
  @override
  State<InterconnexionScreen> createState() => _InterconnexionScreenState();
}

class _InterconnexionScreenState extends State<InterconnexionScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isAligning = false;
  double _alignmentProgress = 0.0;
  Timer? _alignmentTimer;

  List<dynamic> _antennes = [];
  List<dynamic> _links = [];
  dynamic _siteA;
  dynamic _siteB;
  bool _checked = false;
  
  double? _distance;
  double? _azimuth;
  double? _tilt;
  double? _receivedPower;
  String? _feasibilityStatus; // VIABLE, WARNING, CRITIQUE
  List<String> _feasibilityReasons = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _alignmentTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final dataAnt = await _apiService.get('antennes/');
      final dataLinks = await _apiService.get('interconnexions/');
      setState(() {
        _antennes = dataAnt ?? [];
        _links = dataLinks ?? [];
        if (_antennes.isNotEmpty) {
          _siteA = _antennes[0];
          if (_antennes.length > 1) _siteB = _antennes[1];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startAlignment() {
    if (_siteA == null || _siteB == null) return;
    setState(() {
      _isAligning = true;
      _alignmentProgress = 0.0;
      _checked = false;
    });

    _alignmentTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _alignmentProgress += 0.05;
        if (_alignmentProgress >= 1.0) {
          timer.cancel();
          _isAligning = false;
          _finishAlignment();
        }
      });
    });
  }

  void _stopAlignment() {
    _alignmentTimer?.cancel();
    setState(() {
      _isAligning = false;
      _alignmentProgress = 0.0;
    });
  }

  void _finishAlignment() {
    final lat1 = double.parse(_siteA['latitude'].toString());
    final lon1 = double.parse(_siteA['longitude'].toString());
    final lat2 = double.parse(_siteB['latitude'].toString());
    final lon2 = double.parse(_siteB['longitude'].toString());
    final alt1 = double.tryParse(_siteA['altitude']?.toString() ?? '0') ?? 0.0;
    final alt2 = double.tryParse(_siteB['altitude']?.toString() ?? '0') ?? 0.0;
    
    _distance = _haversine(lat1, lon1, lat2, lon2);
    _azimuth = _calculateAzimuth(lat1, lon1, lat2, lon2);
    _tilt = _calculateTilt(alt1, alt2, _distance!);
    
    final freq = double.tryParse(_siteA['frequence']?.toString() ?? '7') ?? 7.0;
    _receivedPower = _calculateLinkBudget(_distance!, freq);

    _analyzeFeasibility(_distance!, _tilt!, alt1, alt2);

    setState(() { _checked = true; });
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _calculateAzimuth(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * pi / 180; final phi2 = lat2 * pi / 180;
    final dL = (lon2 - lon1) * pi / 180;
    final y = sin(dL) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dL);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  double _calculateTilt(double alt1, double alt2, double distKm) {
    if (distKm < 0.001) return 0;
    return atan((alt2 - alt1) / (distKm * 1000)) * 180 / pi;
  }

  double _calculateLinkBudget(double distance, double freqGhz) {
    if (distance < 0.1) distance = 0.1;
    final lfs = 92.44 + 20 * (log(distance) / ln10) + 20 * (log(freqGhz) / ln10);
    return 20.0 + 35.0 + 35.0 - lfs - 5.0; // Ptx + Gtx + Grx - Lfs - Lmisc
  }

  void _analyzeFeasibility(double distance, double tilt, double alt1, double alt2) {
    _feasibilityReasons.clear();
    bool critical = false;
    bool warning = false;

    if (distance > 50) { critical = true; _feasibilityReasons.add("Distance critique (>50km)."); }
    else if (distance > 25) { warning = true; _feasibilityReasons.add("Distance élevée : risque d'atténuation pluvieuse."); }

    if (tilt.abs() > 10) { critical = true; _feasibilityReasons.add("Inclinaison extrême : alignement physique précaire."); }
    else if (tilt.abs() > 5) { warning = true; _feasibilityReasons.add("Inclinaison notable : attention au pointage."); }

    if (_receivedPower! < -75) { critical = true; _feasibilityReasons.add("Signal trop faible : liaison instable."); }
    else if (_receivedPower! < -65) { warning = true; _feasibilityReasons.add("Signal moyen : possible présence d'obstacles."); }

    if (critical) _feasibilityStatus = "CRITIQUE";
    else if (warning) _feasibilityStatus = "WARNING";
    else { _feasibilityStatus = "VIABLE"; _feasibilityReasons.add("Ligne de vue dégagée et signal optimal."); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Alignement Liaisons', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: (i) => setState(() => _tabIndex = i),
              labelColor: const Color(0xFF5B21B6),
              indicatorColor: const Color(0xFF5B21B6),
              tabs: const [Tab(text: 'Alignement'), Tab(text: 'Topologie')],
              controller: TabController(length: 2, vsync: this),
            ),
          ),
          Expanded(child: _tabIndex == 0 ? _buildAlignTab() : _buildTopologyTab()),
        ],
      ),
    );
  }

  Widget _buildAlignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SiteSelector(label: 'Site Source (A)', value: _siteA, sites: _antennes, onChanged: (v) => setState(() { _siteA = v; _checked = false; })),
          const SizedBox(height: 8),
          const Icon(Icons.sensors, color: Color(0xFF5B21B6)),
          const SizedBox(height: 8),
          _SiteSelector(label: 'Site Cible (B)', value: _siteB, sites: _antennes, onChanged: (v) => setState(() { _siteB = v; _checked = false; })),
          const SizedBox(height: 20),
          
          if (_isAligning) ...[
            const Text('Recherche d\'alignement en cours...', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _alignmentProgress, color: const Color(0xFF5B21B6), backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _stopAlignment, 
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('ARRÊTER LE SCAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ] else if (!_checked) ...[
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
              onPressed: (_siteA != null && _siteB != null && _siteA != _siteB) ? _startAlignment : null,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('LANCER L\'ALIGNEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B21B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
          ] else ...[
            // Bouton pour recommencer
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => setState(() => _checked = false),
                icon: const Icon(Icons.refresh),
                label: const Text('Nouvel alignement'),
              ),
            ),
          ],

          if (_checked) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    Color statusColor = const Color(0xFF22C55E);
    if (_feasibilityStatus == "WARNING") statusColor = Colors.orange;
    if (_feasibilityStatus == "CRITIQUE") statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Icon(_feasibilityStatus == "VIABLE" ? Icons.check_circle : (_feasibilityStatus == "WARNING" ? Icons.warning : Icons.error), color: statusColor, size: 50),
          const SizedBox(height: 10),
          Text(_feasibilityStatus!, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ResultItem(label: 'Azimut', value: '${_azimuth!.toStringAsFixed(1)}°'),
              _ResultItem(label: 'Tilt', value: '${_tilt!.toStringAsFixed(2)}°'),
              _ResultItem(label: 'Signal', value: '${_receivedPower!.toStringAsFixed(1)} dBm', color: statusColor),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _feasibilityReasons.map((r) => Text('• $r', style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.9)))).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (_feasibilityStatus != "CRITIQUE")
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: statusColor), child: const Text('ENREGISTRER LA LIAISON', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildTopologyTab() {
    return const Center(child: Text('Vue topologique des liaisons enregistrées.'));
  }
}

class _ResultItem extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _ResultItem({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))]);
  }
}

class _SiteSelector extends StatelessWidget {
  final String label;
  final dynamic value;
  final List<dynamic> sites;
  final ValueChanged<dynamic> onChanged;
  const _SiteSelector({required this.label, required this.value, required this.sites, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5B21B6))),
          DropdownButton<dynamic>(
            isExpanded: true,
            value: value,
            underline: const SizedBox(),
            items: sites.map((s) => DropdownMenuItem(value: s, child: Text(s['nom_site'] ?? ''))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
