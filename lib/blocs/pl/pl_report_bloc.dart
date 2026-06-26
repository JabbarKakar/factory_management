import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/services/pl_report_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/monthly_pl_report.dart';
import '../../domain/entities/payment.dart';

part 'pl_report_event.dart';
part 'pl_report_state.dart';

class PlReportBloc extends Bloc<PlReportEvent, PlReportState> {
  PlReportBloc({
    required PaymentRepository paymentRepository,
    required ExpenseRepository expenseRepository,
    required PlReportService reportService,
  })  : _paymentRepository = paymentRepository,
        _expenseRepository = expenseRepository,
        _reportService = reportService,
        super(PlReportState(selectedMonth: _currentMonth())) {
    on<PlReportWatchStarted>(_onWatchStarted);
    on<PlReportWatchStopped>(_onWatchStopped);
    on<PlReportMonthChanged>(_onMonthChanged);
    on<_PlReportDataUpdated>(_onDataUpdated);
    on<_PlReportStreamFailed>(_onStreamFailed);
  }

  final PaymentRepository _paymentRepository;
  final ExpenseRepository _expenseRepository;
  final PlReportService _reportService;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<Expense>>? _expensesSub;

  List<Payment> _payments = const [];
  List<Expense> _expenses = const [];

  Future<void> _onWatchStarted(
    PlReportWatchStarted event,
    Emitter<PlReportState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PlReportStatus.loading,
        factoryId: event.factoryId,
        selectedMonth: _clampMonth(event.initialMonth ?? state.selectedMonth),
      ),
    );
    await _cancelSubscriptions();

    _paymentsSub = _paymentRepository
        .watchPaymentsForFactory(event.factoryId)
        .listen(
          (payments) {
            _payments = payments;
            add(const _PlReportDataUpdated());
          },
          onError: (_) => add(
            const _PlReportStreamFailed('Could not load P&L data.'),
          ),
        );

    _expensesSub = _expenseRepository.watchExpenses(event.factoryId).listen(
          (expenses) {
            _expenses = expenses;
            add(const _PlReportDataUpdated());
          },
          onError: (_) => add(
            const _PlReportStreamFailed('Could not load P&L data.'),
          ),
        );
  }

  Future<void> _onWatchStopped(
    PlReportWatchStopped event,
    Emitter<PlReportState> emit,
  ) async {
    await _cancelSubscriptions();
  }

  void _onMonthChanged(
    PlReportMonthChanged event,
    Emitter<PlReportState> emit,
  ) {
    final month = _clampMonth(event.month);
    if (_isSameMonth(month, state.selectedMonth)) return;

    emit(
      state.copyWith(
        selectedMonth: month,
        report: _buildReport(month),
      ),
    );
  }

  void _onDataUpdated(
    _PlReportDataUpdated event,
    Emitter<PlReportState> emit,
  ) {
    emit(
      state.copyWith(
        status: PlReportStatus.loaded,
        report: _buildReport(state.selectedMonth),
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _PlReportStreamFailed event,
    Emitter<PlReportState> emit,
  ) {
    emit(
      state.copyWith(
        status: PlReportStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  MonthlyPlReport _buildReport(DateTime month) {
    return _reportService.buildReport(
      year: month.year,
      month: month.month,
      payments: _payments,
      expenses: _expenses,
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _paymentsSub?.cancel();
    await _expensesSub?.cancel();
    _paymentsSub = null;
    _expensesSub = null;
  }

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static DateTime _clampMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    final current = _currentMonth();
    return normalized.isAfter(current) ? current : normalized;
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

final class _PlReportDataUpdated extends PlReportEvent {
  const _PlReportDataUpdated();
}

final class _PlReportStreamFailed extends PlReportEvent {
  const _PlReportStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
