import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../enums/job_work_enums.dart';
import 'stock_output.dart';

class JobWorkShiftLog extends Equatable {
  const JobWorkShiftLog({
    required this.id,
    required this.shiftDate,
    this.shiftName,
    this.smallStockOutputs = const [],
    this.largeStockOutputs = const [],
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
  final List<StockOutput> smallStockOutputs;
  final List<StockOutput> largeStockOutputs;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double wasteAmount;
  final WasteUnit wasteUnit;
  final String? notes;
  final DateTime recordedAt;

  List<StockOutput> get allStockOutputs =>
      [...smallStockOutputs, ...largeStockOutputs];

  bool get hasStockOutputs =>
      allStockOutputs.any((output) => output.hasProduction);

  double get totalUsableSqFt {
    if (hasStockOutputs) {
      return JobWorkOutput._roundSqFt(
        allStockOutputs.fold<double>(0, (sum, output) => sum + output.squareFeet),
      );
    }
    return gradeASqFt + gradeBSqFt + gradeCSqFt;
  }

  double get grandCuttingTotal => JobWorkOutput._roundAmount(
        allStockOutputs.fold<double>(0, (sum, output) => sum + output.amount),
      );

  int get totalPieces =>
      allStockOutputs.fold<int>(0, (sum, output) => sum + output.pieces);

  double get totalOutputSqFt => totalUsableSqFt + rejectSqFt;

  bool get hasOutput =>
      hasStockOutputs || totalOutputSqFt > 0 || wasteAmount > 0;

  factory JobWorkShiftLog.create({
    required DateTime shiftDate,
    String? shiftName,
    List<StockOutput> smallStockOutputs = const [],
    List<StockOutput> largeStockOutputs = const [],
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
      smallStockOutputs: smallStockOutputs,
      largeStockOutputs: largeStockOutputs,
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
    List<StockOutput>? smallStockOutputs,
    List<StockOutput>? largeStockOutputs,
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
      smallStockOutputs: smallStockOutputs ?? this.smallStockOutputs,
      largeStockOutputs: largeStockOutputs ?? this.largeStockOutputs,
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
        smallStockOutputs,
        largeStockOutputs,
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
    this.smallStockOutputs = const [],
    this.largeStockOutputs = const [],
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

  final List<StockOutput> smallStockOutputs;
  final List<StockOutput> largeStockOutputs;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double wasteAmount;
  final WasteUnit wasteUnit;
  final String? slurryDust;
  final WasteDisposition wasteDisposition;
  final DateTime? recordedAt;

  List<StockOutput> get allStockOutputs =>
      [...smallStockOutputs, ...largeStockOutputs];

  bool get hasStockOutputs =>
      allStockOutputs.any((output) => output.hasProduction);

  double get totalUsableSqFt {
    if (hasStockOutputs) {
      return _roundSqFt(
        allStockOutputs.fold<double>(0, (sum, output) => sum + output.squareFeet),
      );
    }
    return gradeASqFt + gradeBSqFt + gradeCSqFt;
  }

  double get grandCuttingTotal => _roundAmount(
        allStockOutputs.fold<double>(0, (sum, output) => sum + output.amount),
      );

  int get totalPieces =>
      allStockOutputs.fold<int>(0, (sum, output) => sum + output.pieces);

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
      hasStockOutputs || totalOutputSqFt > 0 || wasteAmount > 0 || recordedAt != null;

  static JobWorkOutput aggregateFromShifts(
    List<JobWorkShiftLog> shifts, {
    WasteDisposition wasteDisposition = WasteDisposition.customerTakes,
    String? slurryDust,
  }) {
    final smallOutputs = <StockOutput>[];
    final largeOutputs = <StockOutput>[];
    var gradeA = 0.0;
    var gradeB = 0.0;
    var gradeC = 0.0;
    var reject = 0.0;
    var wasteTons = 0.0;
    var wasteSqFt = 0.0;
    var anyStockOutputs = false;

    for (final shift in shifts) {
      if (shift.hasStockOutputs) {
        anyStockOutputs = true;
        smallOutputs.addAll(shift.smallStockOutputs);
        largeOutputs.addAll(shift.largeStockOutputs);
      } else {
        gradeA += shift.gradeASqFt;
        gradeB += shift.gradeBSqFt;
        gradeC += shift.gradeCSqFt;
        reject += shift.rejectSqFt;
      }

      if (shift.wasteUnit == WasteUnit.tons) {
        wasteTons += shift.wasteAmount;
      } else {
        wasteSqFt += shift.wasteAmount;
      }
    }

    String? combinedSlurry = slurryDust;
    if (wasteTons > 0 && wasteSqFt > 0) {
      final extra =
          '${wasteSqFt.toStringAsFixed(0)} sq. ft waste (shift total)';
      combinedSlurry = combinedSlurry == null || combinedSlurry.isEmpty
          ? extra
          : '$combinedSlurry · $extra';
    }

    final base = JobWorkOutput(
      smallStockOutputs:
          anyStockOutputs ? _mergeStockOutputs(smallOutputs) : const [],
      largeStockOutputs:
          anyStockOutputs ? _mergeStockOutputs(largeOutputs) : const [],
      gradeASqFt: anyStockOutputs ? 0 : gradeA,
      gradeBSqFt: anyStockOutputs ? 0 : gradeB,
      gradeCSqFt: anyStockOutputs ? 0 : gradeC,
      rejectSqFt: anyStockOutputs ? 0 : reject,
      slurryDust: combinedSlurry,
      wasteDisposition: wasteDisposition,
    );

    if (wasteTons > 0) {
      return base.copyWith(wasteAmount: wasteTons, wasteUnit: WasteUnit.tons);
    }

    if (wasteSqFt > 0) {
      return base.copyWith(wasteAmount: wasteSqFt, wasteUnit: WasteUnit.sqFt);
    }

    return base;
  }

  JobWorkOutput copyWith({
    List<StockOutput>? smallStockOutputs,
    List<StockOutput>? largeStockOutputs,
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
      smallStockOutputs: smallStockOutputs ?? this.smallStockOutputs,
      largeStockOutputs: largeStockOutputs ?? this.largeStockOutputs,
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

  static List<StockOutput> _mergeStockOutputs(Iterable<StockOutput> outputs) {
    final merged = <String, StockOutput>{};
    for (final output in outputs) {
      if (!output.hasProduction) continue;
      final current = merged[output.size];
      if (current == null) {
        merged[output.size] = output;
        continue;
      }
      final pieces = current.pieces + output.pieces;
      final pricePerSqFt =
          output.pricePerSqFt > 0 ? output.pricePerSqFt : current.pricePerSqFt;
      final squareFeet = _squareFeetFor(output.size, pieces);
      merged[output.size] = StockOutput(
        size: output.size,
        pieces: pieces,
        squareFeet: squareFeet,
        pricePerSqFt: pricePerSqFt,
        amount: _roundAmount(squareFeet * pricePerSqFt),
      );
    }
    return merged.values.toList();
  }

  static double _squareFeetFor(String size, int pieces) {
    final normalized = size.toLowerCase().replaceAll('×', 'x').trim();
    final parts = normalized.split('x');
    if (parts.length != 2) return 0;
    final width = double.tryParse(parts[0].trim());
    final height = double.tryParse(parts[1].trim());
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 0;
    }
    return _roundSqFt((width * height * pieces) / 144);
  }

  static double _roundSqFt(double value) =>
      double.parse(value.toStringAsFixed(2));

  static double _roundAmount(double value) =>
      double.parse(value.toStringAsFixed(2));

  @override
  List<Object?> get props => [
        smallStockOutputs,
        largeStockOutputs,
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
