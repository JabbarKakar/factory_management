import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_strings.dart';

abstract final class ExportActions {
  static Future<void> sharePdf({
    required pw.Document document,
    required String filename,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await document.save();
    await _shareBytes(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/pdf',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> printPdf({
    required pw.Document document,
    required String filename,
  }) async {
    await Printing.layoutPdf(
      name: filename,
      onLayout: (format) async => document.save(),
    );
  }

  static Future<void> shareExcel({
    required List<int> bytes,
    required String filename,
    Rect? sharePositionOrigin,
  }) async {
    await _shareBytes(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> _shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: mimeType),
        ],
        fileNameOverrides: [filename],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static void showExportError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.exportFailed)),
    );
  }
}
