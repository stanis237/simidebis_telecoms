import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<void> sendAntennaCommand(
  BluetoothCharacteristic characteristic,
  int azimut,
  int elevation,
) async {
  try {
    // 1. Création du paquet de données (ex: 2 octets)
    // On utilise Uint8List pour envoyer des octets bruts
    List<int> command = [azimut, elevation];

    // 2. Envoi via Bluetooth
    await characteristic.write(command, withoutResponse: false);

    print("Commande envoyée : Az=$azimut, El=$elevation");
  } catch (e) {
    print("Erreur lors de l'envoi : $e");
  }
}
