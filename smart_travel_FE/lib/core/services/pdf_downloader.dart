import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfDownloader {
  static Future<String> savePdf(List<int> bytes) async {
    Directory dir;

    if (Platform.isAndroid) {
      final externalDirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      dir = externalDirs != null && externalDirs.isNotEmpty
          ? externalDirs.first
          : await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final saveDir = Directory('${dir.path}/SmartTravelReports');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final file = File(
      '${saveDir.path}/finance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<bool> openPdf(String path) async {
    final uri = Uri.file(path);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}