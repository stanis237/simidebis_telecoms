class Intervention {
  final int id;
  final int utilisateurId;
  final int antenneId;
  final String dateIntervention;
  final String description;
  final String statut;

  Intervention({
    required this.id,
    required this.utilisateurId,
    required this.antenneId,
    required this.dateIntervention,
    required this.description,
    required this.statut,
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'],
      utilisateurId: json['utilisateur'],
      antenneId: json['antenne'],
      dateIntervention: json['date_intervention'],
      description: json['description'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilisateur': utilisateurId,
      'antenne': antenneId,
      'date_intervention': dateIntervention,
      'description': description,
      'statut': statut,
    };
  }
}
