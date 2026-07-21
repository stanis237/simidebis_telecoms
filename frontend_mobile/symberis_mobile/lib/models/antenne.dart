class Antenne {
  final int id;
  final String nomSite;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? frequence;
  final String statut;

  Antenne({
    required this.id,
    required this.nomSite,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.frequence,
    required this.statut,
  });

  factory Antenne.fromJson(Map<String, dynamic> json) {
    return Antenne(
      id: json['id'],
      nomSite: json['nom_site'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      altitude: json['altitude'] != null ? double.parse(json['altitude'].toString()) : null,
      frequence: json['frequence'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_site': nomSite,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'frequence': frequence,
      'statut': statut,
    };
  }
}
