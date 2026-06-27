import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/quality_enums.dart';

part 'qc_list_event.dart';
part 'qc_list_state.dart';

class QcListBloc extends Bloc<QcListEvent, QcListState> {
  QcListBloc({required QualityCheckRepository repository})
      : _repository = repository,
        super(const QcListState()) {
    on<QcListWatchStarted>(_onWatchStarted);
    on<QcListWatchStopped>(_onWatchStopped);
    on<QcListSearchChanged>(_onSearchChanged);
    on<QcListFilterChanged>(_onFilterChanged);
    on<_QcListUpdated>(_onListUpdated);
    on<_QcListStreamFailed>(_onStreamFailed);
  }

  final QualityCheckRepository _repository;
  StreamSubscription<List<QualityCheck>>? _subscription;

  Future<void> _onWatchStarted(
    QcListWatchStarted event,
    Emitter<QcListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: QcListStatus.loading,
        filter: event.initialFilter ?? state.filter,
      ),
    );
    await _subscription?.cancel();
    _subscription = _repository.watchQualityChecks(event.factoryId).listen(
          (checks) => add(_QcListUpdated(checks)),
          onError: (_) => add(
            const _QcListStreamFailed(
              'Could not load quality checks. Please try again.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    QcListWatchStopped event,
    Emitter<QcListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSearchChanged(
    QcListSearchChanged event,
    Emitter<QcListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleChecks: _applyFilters(
          state.checks,
          query: event.query,
          filter: state.filter,
        ),
      ),
    );
  }

  void _onFilterChanged(
    QcListFilterChanged event,
    Emitter<QcListState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        visibleChecks: _applyFilters(
          state.checks,
          query: state.searchQuery,
          filter: event.filter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _QcListUpdated event,
    Emitter<QcListState> emit,
  ) {
    final now = DateTime.now();
    final thisMonth = event.checks.where((check) {
      final date = check.inspectionDate;
      return date.year == now.year && date.month == now.month;
    }).toList();

    final monthlyPassRate = thisMonth.isEmpty
        ? 0.0
        : thisMonth.fold<double>(0, (sum, check) => sum + check.passRatePercent) /
            thisMonth.length;

    emit(
      state.copyWith(
        status: QcListStatus.loaded,
        checks: event.checks,
        visibleChecks: _applyFilters(
          event.checks,
          query: state.searchQuery,
          filter: state.filter,
        ),
        monthlyInspectionCount: thisMonth.length,
        monthlyPassRate: monthlyPassRate,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _QcListStreamFailed event,
    Emitter<QcListState> emit,
  ) {
    emit(
      state.copyWith(
        status: QcListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<QualityCheck> _applyFilters(
    List<QualityCheck> checks, {
    required String query,
    required QcListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return checks.where((check) {
      if (!filter.matches(
        referenceType: check.referenceType,
        disposition: check.disposition,
      )) {
        return false;
      }

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        check.qcNumber,
        check.referenceNumber,
        check.referenceLabel,
        check.productLabel,
        check.marbleVariety,
        check.inspectorName,
        check.referenceType.label,
        check.disposition.label,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _QcListUpdated extends QcListEvent {
  const _QcListUpdated(this.checks);

  final List<QualityCheck> checks;

  @override
  List<Object?> get props => [checks];
}

final class _QcListStreamFailed extends QcListEvent {
  const _QcListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
