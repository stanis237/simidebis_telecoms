class Interconnexion {
  final int id;
  final int sourceId;
  final int destinationId;
  final String typeLiaison;
  final String bandePassante;
  final String statut;

  Interconnexion({
    required this.id,
    required this.sourceId,
    required this.destinationId,
    required this.typeLiaison,
    required this.bandePassante,
    required this.statut,
  });

  factory Interconnexion.fromJson(Map<String, dynamic> json) {
    return Interconnexion(
      id: json['id'],
      sourceId: json['source'],
      destinationId: json['destination'],
      typeLiaison: json['type_liaison'],
      bandePassante: json['bande_passante'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': sourceId,
      'destination': destinationId,
      'type_liaison': typeLiaison,
      'bande_passante': bandePassante,
      'statut': statut,
    };
  }
}
