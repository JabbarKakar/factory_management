import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../utils/export_actions.dart';

class ExportMenuButton extends StatelessWidget {
  const ExportMenuButton({
    required this.onExportPdf,
    this.onExportExcel,
    this.onPrint,
    super.key,
  });

  final Future<void> Function(Rect? shareOrigin) onExportPdf;
  final Future<void> Function(Rect? shareOrigin)? onExportExcel;
  final Future<void> Function()? onPrint;

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.ios_share_outlined),
      tooltip: AppStrings.export,
      onSelected: (value) async {
        final origin = _shareOrigin(context);
        try {
          switch (value) {
            case 'pdf':
              await onExportPdf(origin);
            case 'excel':
              await onExportExcel?.call(origin);
            case 'print':
              await onPrint?.call();
          }
        } catch (error) {
          if (context.mounted) {
            ExportActions.showExportError(context, error);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text(AppStrings.exportPdf),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (onExportExcel != null)
          const PopupMenuItem(
            value: 'excel',
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text(AppStrings.exportExcel),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (onPrint != null)
          const PopupMenuItem(
            value: 'print',
            child: ListTile(
              leading: Icon(Icons.print_outlined),
              title: Text(AppStrings.print),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
