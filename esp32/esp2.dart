 class AntennaStatus {
  final double azimuth;
  final double elevation;
  AntennaStatus({required this.azimuth, required this.elevation});

  factory AntennaStatus.fromJson(Map<String, dynamic> json) {
    return AntennaStatus(
      azimuth: json['az'].toDouble(),
      elevation: json['el'].toDouble(),
    );
  }
}