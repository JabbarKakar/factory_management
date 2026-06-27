import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/quality_check.dart';

part 'qc_detail_event.dart';
part 'qc_detail_state.dart';

class QcDetailBloc extends Bloc<QcDetailEvent, QcDetailState> {
  QcDetailBloc({required QualityCheckRepository repository})
      : _repository = repository,
        super(const QcDetailState()) {
    on<QcDetailWatchStarted>(_onWatchStarted);
    on<QcDetailWatchStopped>(_onWatchStopped);
    on<_QcDetailUpdated>(_onUpdated);
    on<_QcDetailStreamFailed>(_onStreamFailed);
  }

  final QualityCheckRepository _repository;
  StreamSubscription<QualityCheck?>? _subscription;

  Future<void> _onWatchStarted(
    QcDetailWatchStarted event,
    Emitter<QcDetailState> emit,
  ) async {
    emit(state.copyWith(status: QcDetailStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchQualityCheck(event.qcId).listen(
          (check) {
            if (check == null) {
              add(const _QcDetailStreamFailed('Quality check not found.'));
            } else {
              add(_QcDetailUpdated(check));
            }
          },
          onError: (_) => add(
            const _QcDetailStreamFailed('Could not load quality check.'),
          ),
        );
  }

  Future<void> _onWatchStopped(
    QcDetailWatchStopped event,
    Emitter<QcDetailState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onUpdated(
    _QcDetailUpdated event,
    Emitter<QcDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: QcDetailStatus.loaded,
        check: event.check,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _QcDetailStreamFailed event,
    Emitter<QcDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: QcDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _QcDetailUpdated extends QcDetailEvent {
  const _QcDetailUpdated(this.check);

  final QualityCheck check;

  @override
  List<Object?> get props => [check];
}

final class _QcDetailStreamFailed extends QcDetailEvent {
  const _QcDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
