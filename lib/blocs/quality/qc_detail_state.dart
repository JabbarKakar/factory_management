part of 'qc_detail_bloc.dart';

enum QcDetailStatus { initial, loading, loaded, failure }

class QcDetailState extends Equatable {
  const QcDetailState({
    this.status = QcDetailStatus.initial,
    this.check,
    this.errorMessage,
  });

  final QcDetailStatus status;
  final QualityCheck? check;
  final String? errorMessage;

  QcDetailState copyWith({
    QcDetailStatus? status,
    QualityCheck? check,
    String? errorMessage,
  }) {
    return QcDetailState(
      status: status ?? this.status,
      check: check ?? this.check,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, check, errorMessage];
}
