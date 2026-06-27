import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    if (bytes.isEmpty) {
      throw StateError('PDF is empty');
    }

    final safeName = _safeFilename(filename);
    final bounds = sharePositionOrigin ?? _defaultShareOrigin();

    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: safeName,
      bounds: bounds,
    );

    if (!shared) {
      debugPrint('ExportActions: PDF share dismissed or unavailable');
    }
  }

  static Future<void> printPdf({
    required pw.Document document,
    required String filename,
  }) async {
    await Printing.layoutPdf(
      name: _safeFilename(filename),
      onLayout: (format) async => document.save(),
    );
  }

  static Future<void> shareExcel({
    required List<int> bytes,
    required String filename,
    Rect? sharePositionOrigin,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Excel file is empty');
    }

    final safeName = _safeFilename(filename);
    final file = await _writeTempFile(
      bytes: Uint8List.fromList(bytes),
      filename: safeName,
    );

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _excelMimeType, name: safeName)],
        subject: safeName,
        sharePositionOrigin: sharePositionOrigin ?? _defaultShareOrigin(),
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      debugPrint('ExportActions: Excel share unavailable');
      throw StateError('Share is unavailable on this device');
    }
    if (result.status == ShareResultStatus.dismissed) {
      debugPrint('ExportActions: Excel share dismissed');
    }
  }

  static Future<File> _writeTempFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Could not write export file');
    }
    return file;
  }

  static Rect _defaultShareOrigin() => const Rect.fromLTWH(0, 0, 1, 1);

  static String _safeFilename(String filename) {
    final trimmed = filename.trim();
    if (trimmed.isEmpty) return 'export.bin';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static const _excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static void showExportError(BuildContext context, [Object? error]) {
    if (kDebugMode && error != null) {
      debugPrint('Export failed: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.exportFailed)),
    );
  }
}
