class Alarme {
  final int id;
  final int antenneId;
  final String typeAlarme;
  final String dateAlarme;
  final String niveau;
  final String statut;

  Alarme({
    required this.id,
    required this.antenneId,
    required this.typeAlarme,
    required this.dateAlarme,
    required this.niveau,
    required this.statut,
  });

  factory Alarme.fromJson(Map<String, dynamic> json) {
    return Alarme(
      id: json['id'],
      antenneId: json['antenne'],
      typeAlarme: json['type_alarme'],
      dateAlarme: json['date_alarme'],
      niveau: json['niveau'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'antenne': antenneId,
      'type_alarme': typeAlarme,
      'niveau': niveau,
      'statut': statut,
    };
  }
}
