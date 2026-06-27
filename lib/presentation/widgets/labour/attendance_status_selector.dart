import 'package:flutter/material.dart';

import '../../../domain/enums/labour_enums.dart';

class AttendanceStatusSelector extends StatelessWidget {
  const AttendanceStatusSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AttendanceStatus? value;
  final ValueChanged<AttendanceStatus> onChanged;

  Color _colorFor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => Colors.green,
      AttendanceStatus.absent => Colors.red,
      AttendanceStatus.halfDay => Colors.orange,
      AttendanceStatus.leave => Colors.blue,
      AttendanceStatus.holiday => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AttendanceStatus>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text('—'),
      items: AttendanceStatus.values
          .map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(
                status.label,
                style: TextStyle(color: _colorFor(status)),
              ),
            ),
          )
          .toList(),
      onChanged: (status) {
        if (status != null) onChanged(status);
      },
    );
  }
}
