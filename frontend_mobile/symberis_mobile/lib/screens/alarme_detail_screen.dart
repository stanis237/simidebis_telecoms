import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AlarmeDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? alarme;
  const AlarmeDetailScreen({super.key, this.alarme});

  @override
  State<AlarmeDetailScreen> createState() => _AlarmeDetailScreenState();
}

class _AlarmeDetailScreenState extends State<AlarmeDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isUpdating = false;
  late Map<String, dynamic> _alarme;

  @override
  void initState() {
    super.initState();
    _alarme = widget.alarme ?? {};
  }

  Color _colorForNiveau(String? niveau) {
    switch (niveau) {
      case 'MINEURE':  return const Color(0xFF3B82F6);
      case 'MAJEURE':  return const Color(0xFFF59E0B);
      case 'CRITIQUE': return const Color(0xFFEF4444);
      default:         return Colors.grey;
    }
  }

  Color _colorForStatut(String? statut) {
    switch (statut) {
      case 'RESOLUE':     return const Color(0xFF22C55E);
      case 'EN_COURS':    return const Color(0xFFF59E0B);
      case 'NON_RESOLUE': return const Color(0xFFEF4444);
      default:            return Colors.grey;
    }
  }

  String _labelStatut(String? statut) {
    switch (statut) {
      case 'RESOLUE':     return 'Résolue';
      case 'EN_COURS':    return 'En cours';
      case 'NON_RESOLUE': return 'Non résolue';
      default:            return statut ?? '—';
    }
  }

  /// Marque l'alarme comme résolue via l'API.
  Future<void> _resoudreAlarme() async {
    final id = _alarme['id'];
    if (id == null) return;

    setState(() => _isUpdating = true);
    try {
      await _apiService.patch('alarmes/$id/', {'statut': 'RESOLUE'});
      if (!mounted) return;
      setState(() => _alarme['statut'] = 'RESOLUE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Alarme marquée comme résolue'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Passe l'alarme en statut "En cours".
  Future<void> _mettreEnCours() async {
    final id = _alarme['id'];
    if (id == null) return;
    if (_alarme['statut'] == 'RESOLUE') return;

    setState(() => _isUpdating = true);
    try {
      await _apiService.patch('alarmes/$id/', {'statut': 'EN_COURS'});
      if (!mounted) return;
      setState(() => _alarme['statut'] = 'EN_COURS');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alarme assignée — statut : En cours'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final niveau = _alarme['niveau'] as String?;
    final statut = _alarme['statut'] as String?;
    final niveauColor = _colorForNiveau(niveau);
    final statutColor = _colorForStatut(statut);
    final isResolved = statut == 'RESOLUE';

    // Formater la date
    String dateStr = '—';
    if (_alarme['date_alarme'] != null) {
      try {
        final dt = DateTime.parse(_alarme['date_alarme'].toString()).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateStr = _alarme['date_alarme'].toString();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: niveauColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/alarmes'),
        ),
        title: const Text('Détail alarme', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête alarme ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: niveauColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: niveauColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: niveauColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber, color: niveauColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _alarme['type_alarme']?.toString() ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'ID alarme : ${_alarme['id'] ?? '—'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: niveauColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      niveau ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Détails ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Antenne ID', value: _alarme['antenne']?.toString() ?? '—'),
                  _DetailRow(label: 'Date', value: dateStr),
                  _DetailRow(label: 'Niveau', value: niveau ?? '—', valueColor: niveauColor),
                  _DetailRow(
                    label: 'Statut',
                    value: _labelStatut(statut),
                    valueColor: statutColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions ────────────────────────────────────────────────────
            if (!isResolved) ...[
              const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _resoudreAlarme,
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'Marquer comme résolue',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isUpdating || statut == 'EN_COURS') ? null : _mettreEnCours,
                  icon: const Icon(Icons.engineering, color: Color(0xFF5B21B6)),
                  label: const Text(
                    'Assigner / Mettre en cours',
                    style: TextStyle(color: Color(0xFF5B21B6), fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5B21B6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                    SizedBox(width: 8),
                    Text(
                      'Alarme résolue',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
