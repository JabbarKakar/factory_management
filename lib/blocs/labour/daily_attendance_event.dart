part of 'daily_attendance_bloc.dart';

sealed class DailyAttendanceEvent extends Equatable {
  const DailyAttendanceEvent();

  @override
  List<Object?> get props => [];
}

final class DailyAttendanceWatchStarted extends DailyAttendanceEvent {
  const DailyAttendanceWatchStarted({
    required this.factoryId,
    this.initialDate,
  });

  final String factoryId;
  final DateTime? initialDate;

  @override
  List<Object?> get props => [factoryId, initialDate];
}

final class DailyAttendanceWatchStopped extends DailyAttendanceEvent {
  const DailyAttendanceWatchStopped();
}

final class DailyAttendanceDateChanged extends DailyAttendanceEvent {
  const DailyAttendanceDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class DailyAttendanceShiftChanged extends DailyAttendanceEvent {
  const DailyAttendanceShiftChanged(this.shift);

  final AttendanceShift shift;

  @override
  List<Object?> get props => [shift];
}

final class DailyAttendanceStatusChanged extends DailyAttendanceEvent {
  const DailyAttendanceStatusChanged({
    required this.employeeId,
    required this.status,
  });

  final String employeeId;
  final AttendanceStatus status;

  @override
  List<Object?> get props => [employeeId, status];
}

final class DailyAttendanceMarkAllPresentRequested extends DailyAttendanceEvent {
  const DailyAttendanceMarkAllPresentRequested();
}

final class DailyAttendanceSearchChanged extends DailyAttendanceEvent {
  const DailyAttendanceSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
