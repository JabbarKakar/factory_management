import 'package:equatable/equatable.dart';

import '../enums/job_work_enums.dart';

/// One pending-pickup row on the dashboard (Load-scoped, or legacy JW).
class DashboardPendingPickup extends Equatable {
  const DashboardPendingPickup({
    required this.jobWorkId,
    required this.jobWorkNumber,
    required this.customerName,
    required this.status,
    this.loadId,
    this.loadNumber,
    this.mineLocation,
    this.mineOwner,
  });

  final String jobWorkId;
  final String jobWorkNumber;
  final String customerName;
  final JobWorkStatus status;
  final String? loadId;
  final String? loadNumber;
  final String? mineLocation;
  final String? mineOwner;

  bool get hasLoad => loadId != null && loadId!.isNotEmpty;

  String get primaryLabel {
    if (loadNumber != null && loadNumber!.trim().isNotEmpty) {
      return '$jobWorkNumber · ${loadNumber!.trim()}';
    }
    return jobWorkNumber;
  }

  @override
  List<Object?> get props => [
        jobWorkId,
        jobWorkNumber,
        customerName,
        status,
        loadId,
        loadNumber,
        mineLocation,
        mineOwner,
      ];
}
