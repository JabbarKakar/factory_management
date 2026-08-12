import 'package:equatable/equatable.dart';
import '../enums/dashboard_finance_period.dart';

class JobWorkDispatchCategoryMetrics extends Equatable {
  const JobWorkDispatchCategoryMetrics({
    required this.largePieces,
    required this.largeSqFt,
    required this.smallPieces,
    required this.smallSqFt,
  });

  static const empty = JobWorkDispatchCategoryMetrics(
    largePieces: 0,
    largeSqFt: 0,
    smallPieces: 0,
    smallSqFt: 0,
  );

  final int largePieces;
  final double largeSqFt;
  final int smallPieces;
  final double smallSqFt;

  int get totalPieces => largePieces + smallPieces;
  double get totalSqFt => largeSqFt + smallSqFt;

  @override
  List<Object?> get props => [
        largePieces,
        largeSqFt,
        smallPieces,
        smallSqFt,
      ];
}

class JobWorkDispatchTrendPoint extends Equatable {
  const JobWorkDispatchTrendPoint({
    required this.label,
    required this.largePieces,
    required this.largeSqFt,
    required this.smallPieces,
    required this.smallSqFt,
  });

  final String label;
  final int largePieces;
  final double largeSqFt;
  final int smallPieces;
  final double smallSqFt;

  int get totalPieces => largePieces + smallPieces;
  double get totalSqFt => largeSqFt + smallSqFt;

  @override
  List<Object?> get props => [
        label,
        largePieces,
        largeSqFt,
        smallPieces,
        smallSqFt,
      ];
}

class JobWorkDispatchPayload extends Equatable {
  const JobWorkDispatchPayload({
    required this.period,
    required this.jobWorkMetrics,
    required this.saleDispatchMetrics,
    this.jobWorkTrendPoints = const [],
    this.saleDispatchTrendPoints = const [],
  });

  final DashboardFinancePeriod period;
  final JobWorkDispatchCategoryMetrics jobWorkMetrics;
  final JobWorkDispatchCategoryMetrics saleDispatchMetrics;
  final List<JobWorkDispatchTrendPoint> jobWorkTrendPoints;
  final List<JobWorkDispatchTrendPoint> saleDispatchTrendPoints;

  static const empty = JobWorkDispatchPayload(
    period: DashboardFinancePeriod.daily,
    jobWorkMetrics: JobWorkDispatchCategoryMetrics.empty,
    saleDispatchMetrics: JobWorkDispatchCategoryMetrics.empty,
  );

  @override
  List<Object?> get props => [
        period,
        jobWorkMetrics,
        saleDispatchMetrics,
        jobWorkTrendPoints,
        saleDispatchTrendPoints,
      ];
}
