part of 'pl_report_bloc.dart';

enum PlReportStatus { initial, loading, loaded, failure }

class PlReportState extends Equatable {
  const PlReportState({
    this.status = PlReportStatus.initial,
    this.report = MonthlyPlReport.empty,
    required this.selectedMonth,
    this.factoryId,
    this.errorMessage,
  });

  final PlReportStatus status;
  final MonthlyPlReport report;
  final DateTime selectedMonth;
  final String? factoryId;
  final String? errorMessage;

  bool get canGoToNextMonth {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final selected = DateTime(selectedMonth.year, selectedMonth.month);
    return selected.isBefore(current);
  }

  PlReportState copyWith({
    PlReportStatus? status,
    MonthlyPlReport? report,
    DateTime? selectedMonth,
    String? factoryId,
    String? errorMessage,
  }) {
    return PlReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      factoryId: factoryId ?? this.factoryId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        report,
        selectedMonth,
        factoryId,
        errorMessage,
      ];
}
