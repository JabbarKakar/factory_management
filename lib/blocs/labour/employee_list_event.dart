part of 'employee_list_bloc.dart';

sealed class EmployeeListEvent extends Equatable {
  const EmployeeListEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeListWatchStarted extends EmployeeListEvent {
  const EmployeeListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class EmployeeListWatchStopped extends EmployeeListEvent {
  const EmployeeListWatchStopped();
}

final class EmployeeListSearchChanged extends EmployeeListEvent {
  const EmployeeListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class EmployeeListFilterChanged extends EmployeeListEvent {
  const EmployeeListFilterChanged(this.filter);

  final EmployeeListFilter filter;

  @override
  List<Object?> get props => [filter];
}
