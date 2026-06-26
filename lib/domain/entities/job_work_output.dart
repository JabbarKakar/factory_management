import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../enums/job_work_enums.dart';

class JobWorkShiftLog extends Equatable {
  const JobWorkShiftLog({
    required this.id,
    required this.shiftDate,
    this.shiftName,
    this.gradeASqFt = 0,
    this.gradeBSqFt = 0,
    this.gradeCSqFt = 0,
    this.rejectSqFt = 0,
    this.wasteAmount = 0,
    this.wasteUnit = WasteUnit.tons,
    this.notes,
    required this.recordedAt,
  });

  final String id;
  final DateTime shiftDate;
  final String? shiftName;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double wasteAmount;
  final WasteUnit wasteUnit;
  final String? notes;
  final DateTime recordedAt;

  double get totalUsableSqFt => gradeASqFt + gradeBSqFt + gradeCSqFt;

  double get totalOutputSqFt => totalUsableSqFt + rejectSqFt;

  bool get hasOutput => totalOutputSqFt > 0 || wasteAmount > 0;

  factory JobWorkShiftLog.create({
    required DateTime shiftDate,
    String? shiftName,
    double gradeASqFt = 0,
    double gradeBSqFt = 0,
    double gradeCSqFt = 0,
    double rejectSqFt = 0,
    double wasteAmount = 0,
    WasteUnit wasteUnit = WasteUnit.tons,
    String? notes,
  }) {
    return JobWorkShiftLog(
      id: const Uuid().v4(),
      shiftDate: shiftDate,
      shiftName: shiftName,
      gradeASqFt: gradeASqFt,
      gradeBSqFt: gradeBSqFt,
      gradeCSqFt: gradeCSqFt,
      rejectSqFt: rejectSqFt,
      wasteAmount: wasteAmount,
      wasteUnit: wasteUnit,
      notes: notes,
      recordedAt: DateTime.now(),
    );
  }

  JobWorkShiftLog copyWith({
    String? id,
    DateTime? shiftDate,
    String? shiftName,
    double? gradeASqFt,
    double? gradeBSqFt,
    double? gradeCSqFt,
    double? rejectSqFt,
    double? wasteAmount,
    WasteUnit? wasteUnit,
    String? notes,
    DateTime? recordedAt,
  }) {
    return JobWorkShiftLog(
      id: id ?? this.id,
      shiftDate: shiftDate ?? this.shiftDate,
      shiftName: shiftName ?? this.shiftName,
      gradeASqFt: gradeASqFt ?? this.gradeASqFt,
      gradeBSqFt: gradeBSqFt ?? this.gradeBSqFt,
      gradeCSqFt: gradeCSqFt ?? this.gradeCSqFt,
      rejectSqFt: rejectSqFt ?? this.rejectSqFt,
      wasteAmount: wasteAmount ?? this.wasteAmount,
      wasteUnit: wasteUnit ?? this.wasteUnit,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shiftDate,
        shiftName,
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
        wasteAmount,
        wasteUnit,
        notes,
        recordedAt,
      ];
}

class JobWorkOutput extends Equatable {
  const JobWorkOutput({
    this.gradeASqFt = 0,
    this.gradeBSqFt = 0,
    this.gradeCSqFt = 0,
    this.rejectSqFt = 0,
    this.wasteAmount = 0,
    this.wasteUnit = WasteUnit.tons,
    this.slurryDust,
    this.wasteDisposition = WasteDisposition.customerTakes,
    this.recordedAt,
  });

  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double wasteAmount;
  final WasteUnit wasteUnit;
  final String? slurryDust;
  final WasteDisposition wasteDisposition;
  final DateTime? recordedAt;

  double get totalUsableSqFt => gradeASqFt + gradeBSqFt + gradeCSqFt;

  double get totalOutputSqFt => totalUsableSqFt + rejectSqFt;

  double wastePercent(double inputTons) {
    if (wasteAmount <= 0) return 0;

    return switch (wasteUnit) {
      WasteUnit.tons when inputTons > 0 => (wasteAmount / inputTons) * 100,
      WasteUnit.sqFt => () {
          final totalAccounted = totalOutputSqFt + wasteAmount;
          if (totalAccounted <= 0) return 0.0;
          return (wasteAmount / totalAccounted) * 100;
        }(),
      _ => 0.0,
    };
  }

  double yieldPercent(double? expectedSqFt) {
    if (expectedSqFt == null || expectedSqFt <= 0 || totalUsableSqFt <= 0) {
      return 0;
    }
    return (totalUsableSqFt / expectedSqFt) * 100;
  }

  bool get isRecorded =>
      totalOutputSqFt > 0 || wasteAmount > 0 || recordedAt != null;

  static JobWorkOutput aggregateFromShifts(
    List<JobWorkShiftLog> shifts, {
    WasteDisposition wasteDisposition = WasteDisposition.customerTakes,
    String? slurryDust,
  }) {
    var gradeA = 0.0;
    var gradeB = 0.0;
    var gradeC = 0.0;
    var reject = 0.0;
    var wasteTons = 0.0;
    var wasteSqFt = 0.0;

    for (final shift in shifts) {
      gradeA += shift.gradeASqFt;
      gradeB += shift.gradeBSqFt;
      gradeC += shift.gradeCSqFt;
      reject += shift.rejectSqFt;
      if (shift.wasteUnit == WasteUnit.tons) {
        wasteTons += shift.wasteAmount;
      } else {
        wasteSqFt += shift.wasteAmount;
      }
    }

    String? combinedSlurry = slurryDust;
    if (wasteTons > 0 && wasteSqFt > 0) {
      final extra = '${wasteSqFt.toStringAsFixed(0)} sq. ft waste (shift total)';
      combinedSlurry = combinedSlurry == null || combinedSlurry.isEmpty
          ? extra
          : '$combinedSlurry · $extra';
    }

    if (wasteTons > 0) {
      return JobWorkOutput(
        gradeASqFt: gradeA,
        gradeBSqFt: gradeB,
        gradeCSqFt: gradeC,
        rejectSqFt: reject,
        wasteAmount: wasteTons,
        wasteUnit: WasteUnit.tons,
        slurryDust: combinedSlurry,
        wasteDisposition: wasteDisposition,
      );
    }

    if (wasteSqFt > 0) {
      return JobWorkOutput(
        gradeASqFt: gradeA,
        gradeBSqFt: gradeB,
        gradeCSqFt: gradeC,
        rejectSqFt: reject,
        wasteAmount: wasteSqFt,
        wasteUnit: WasteUnit.sqFt,
        slurryDust: combinedSlurry,
        wasteDisposition: wasteDisposition,
      );
    }

    return JobWorkOutput(
      gradeASqFt: gradeA,
      gradeBSqFt: gradeB,
      gradeCSqFt: gradeC,
      rejectSqFt: reject,
      slurryDust: combinedSlurry,
      wasteDisposition: wasteDisposition,
    );
  }

  JobWorkOutput copyWith({
    double? gradeASqFt,
    double? gradeBSqFt,
    double? gradeCSqFt,
    double? rejectSqFt,
    double? wasteAmount,
    WasteUnit? wasteUnit,
    String? slurryDust,
    WasteDisposition? wasteDisposition,
    DateTime? recordedAt,
  }) {
    return JobWorkOutput(
      gradeASqFt: gradeASqFt ?? this.gradeASqFt,
      gradeBSqFt: gradeBSqFt ?? this.gradeBSqFt,
      gradeCSqFt: gradeCSqFt ?? this.gradeCSqFt,
      rejectSqFt: rejectSqFt ?? this.rejectSqFt,
      wasteAmount: wasteAmount ?? this.wasteAmount,
      wasteUnit: wasteUnit ?? this.wasteUnit,
      slurryDust: slurryDust ?? this.slurryDust,
      wasteDisposition: wasteDisposition ?? this.wasteDisposition,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
        wasteAmount,
        wasteUnit,
        slurryDust,
        wasteDisposition,
        recordedAt,
      ];
}

class JobWorkExecution extends Equatable {
  const JobWorkExecution({
    this.cuttingStartDate,
    this.cuttingCompletionDate,
    this.supervisorName,
    this.progressNotes,
  });

  final DateTime? cuttingStartDate;
  final DateTime? cuttingCompletionDate;
  final String? supervisorName;
  final String? progressNotes;

  bool get hasData =>
      cuttingStartDate != null ||
      cuttingCompletionDate != null ||
      (supervisorName != null && supervisorName!.trim().isNotEmpty) ||
      (progressNotes != null && progressNotes!.trim().isNotEmpty);

  JobWorkExecution copyWith({
    DateTime? cuttingStartDate,
    DateTime? cuttingCompletionDate,
    String? supervisorName,
    String? progressNotes,
  }) {
    return JobWorkExecution(
      cuttingStartDate: cuttingStartDate ?? this.cuttingStartDate,
      cuttingCompletionDate:
          cuttingCompletionDate ?? this.cuttingCompletionDate,
      supervisorName: supervisorName ?? this.supervisorName,
      progressNotes: progressNotes ?? this.progressNotes,
    );
  }

  @override
  List<Object?> get props => [
        cuttingStartDate,
        cuttingCompletionDate,
        supervisorName,
        progressNotes,
      ];
}
