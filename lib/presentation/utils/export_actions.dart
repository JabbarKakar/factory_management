import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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

    var shared = await Printing.sharePdf(
      bytes: bytes,
      filename: safeName,
      bounds: bounds,
    );

    if (!shared) {
      final file = await _writeExportFile(
        bytes: Uint8List.fromList(bytes),
        filename: safeName,
      );
      shared = await _shareFile(
        file: file,
        sharePositionOrigin: bounds,
      );
    }

    if (!shared) {
      final opened = await _openExportFile(safeName);
      if (!opened) {
        throw StateError('PDF share unavailable');
      }
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
    final file = await _writeExportFile(
      bytes: Uint8List.fromList(bytes),
      filename: safeName,
    );

    var shared = await _shareFile(
      file: file,
      sharePositionOrigin: sharePositionOrigin ?? _defaultShareOrigin(),
    );

    if (!shared) {
      final opened = await _openExportFile(safeName);
      if (!opened) {
        throw StateError('Excel share unavailable');
      }
    }
  }

  static Future<bool> _shareFile({
    required File file,
    required Rect sharePositionOrigin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (result.status == ShareResultStatus.unavailable) {
        return false;
      }
      if (result.status == ShareResultStatus.dismissed) {
        debugPrint('ExportActions: share dismissed');
        return true;
      }
      return true;
    } catch (error) {
      debugPrint('ExportActions: share failed: $error');
      return false;
    }
  }

  static Future<bool> _openExportFile(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/exports/$filename';
      final result = await OpenFilex.open(path);
      return result.type == ResultType.done;
    } catch (error) {
      debugPrint('ExportActions: open file failed: $error');
      return false;
    }
  }

  static Future<File> _writeExportFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$filename');
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

  static void showExportError(BuildContext context, [Object? error]) {
    if (kDebugMode && error != null) {
      debugPrint('Export failed: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.exportFailed)),
    );
  }

  static void showExportOpened(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.exportOpened)),
    );
  }
}
