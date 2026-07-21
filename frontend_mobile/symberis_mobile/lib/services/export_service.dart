import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class ExportService {
  /// Génère et télécharge/partage un rapport PDF des antennes.
  static Future<void> exportAntennasToPdf(List<dynamic> antennes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Rapport des Antennes - Simidebis Network',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['ID', 'Nom du Site', 'Latitude', 'Longitude', 'Statut'],
              data: antennes.map((a) => [
                a['id'].toString(),
                a['nom_site'].toString(),
                a['latitude'].toString(),
                a['longitude'].toString(),
                a['statut'].toString(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF5B21B6)),
            ),
          ];
        },
      ),
    );

    if (kIsWeb) {
      // Sur le Web : Ouvre la boîte de dialogue d'impression/sauvegarde du navigateur
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } else {
      // Sur Mobile : Enregistre en temporaire et partage
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapport_antennes.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport PDF');
    }
  }

  /// Génère et télécharge/partage un rapport Excel (XLSX) des alarmes.
  static Future<void> exportAlarmesToExcel(List<dynamic> alarmes) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Alarmes'];
    excel.setDefaultSheet('Alarmes');

    List<String> headers = ['ID', 'Antenne ID', 'Type', 'Niveau', 'Statut', 'Date'];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var a in alarmes) {
      sheetObject.appendRow([
        TextCellValue(a['id'].toString()),
        TextCellValue(a['antenne'].toString()),
        TextCellValue(a['type_alarme'].toString()),
        TextCellValue(a['niveau'].toString()),
        TextCellValue(a['statut'].toString()),
        TextCellValue(a['date_alarme'].toString()),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      // Sur le Web : Utilise Printing pour télécharger le fichier via le navigateur
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'rapport_alarmes.xlsx');
    } else {
      // Sur Mobile : Enregistre et partage
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapport_alarmes.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport Excel');
    }
  }
}
