part of 'qc_list_bloc.dart';

enum QcListStatus { initial, loading, loaded, failure }

class QcListState extends Equatable {
  const QcListState({
    this.status = QcListStatus.initial,
    this.checks = const [],
    this.visibleChecks = const [],
    this.searchQuery = '',
    this.filter = QcListFilter.all,
    this.monthlyInspectionCount = 0,
    this.monthlyPassRate = 0,
    this.errorMessage,
  });

  final QcListStatus status;
  final List<QualityCheck> checks;
  final List<QualityCheck> visibleChecks;
  final String searchQuery;
  final QcListFilter filter;
  final int monthlyInspectionCount;
  final double monthlyPassRate;
  final String? errorMessage;

  QcListState copyWith({
    QcListStatus? status,
    List<QualityCheck>? checks,
    List<QualityCheck>? visibleChecks,
    String? searchQuery,
    QcListFilter? filter,
    int? monthlyInspectionCount,
    double? monthlyPassRate,
    String? errorMessage,
  }) {
    return QcListState(
      status: status ?? this.status,
      checks: checks ?? this.checks,
      visibleChecks: visibleChecks ?? this.visibleChecks,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      monthlyInspectionCount:
          monthlyInspectionCount ?? this.monthlyInspectionCount,
      monthlyPassRate: monthlyPassRate ?? this.monthlyPassRate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        checks,
        visibleChecks,
        searchQuery,
        filter,
        monthlyInspectionCount,
        monthlyPassRate,
        errorMessage,
      ];
}
