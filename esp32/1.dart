[18:45, 19/07/2026] Meuble: #include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// UUIDs uniques (vous pouvez les générer en ligne sur uuidgenerator.net)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b2648"

void setup() {
  Serial.begin(115200);

  // Initialisation du BLE
  BLEDevice::init("Antenne_ESP32");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Création de la caractéristique pour recevoir les ordres
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );

  pService->start();
  
  // Publicité pour que le téléphone puisse trouver l'appareil
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  
  Serial.println("Appareil prêt, en attente de connexion...");
}

void loop() {
  // Ici vous traiterez les données reçues
  delay(2000);
}
[18:46, 19/07/2026] Meuble: // Supposez que vous avez déjà trouvé la caractéristique lors de la connexion
late BluetoothCharacteristic targetCharacteristic;

// ... dans votre fonction de callback d'UI
onChanged: (double value) {
  int angle = value.toInt();
  sendAntennaCommand(targetCharacteristic, angle, currentElevation);
},
[18:47, 19/07/2026] Meuble: var buffer = Uint8List(4).buffer;
ByteData(buffer).setFloat32(0, 45.5, Endian.little);
await characteristic.write(buffer.asUint8List());
[18:47, 19/07/2026] Meuble: void onWrite(BLECharacteristic *pCharacteristic) {
  std::string value = pCharacteristic->getValue();
  if (value.length() >= 2) {
    int azimut = value[0];
    int elevation = value[1];
    // Appeler ici votre fonction qui pilote les moteurs
    setAntennaPosition(azimut, elevation);
  }
}