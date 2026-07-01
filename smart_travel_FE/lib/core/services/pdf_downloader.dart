import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfDownloader {
  static const MethodChannel _channel = MethodChannel('smart_travel/pdf');

  static Future<String> savePdf(List<int> bytes) async {
    if (Platform.isAndroid) {
      final fileName =
          'finance_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      try {
        final location = await _channel.invokeMethod<String>(
          'savePdfToDownloads',
          {
            'bytes': Uint8List.fromList(bytes),
            'fileName': fileName,
          },
        );

        if (location != null && location.isNotEmpty) {
          return location;
        }
      } catch (_) {
        // Fallback xuống cách lưu cũ nếu native save thất bại.
      }
    }

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

  static Future<bool> openPdf(String location) async {
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'openDocument',
          {'location': location},
        );
        if (opened != null) {
          return opened;
        }
      } catch (_) {
        // Fallback xuống launcher mặc định nếu native open thất bại.
      }
    }

    final uri = location.startsWith('content://')
        ? Uri.parse(location)
        : Uri.file(location);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
