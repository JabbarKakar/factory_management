part of 'daily_attendance_bloc.dart';

enum DailyAttendanceStatus { initial, loading, loaded, saving, failure }

class DailyAttendanceEntry extends Equatable {
  const DailyAttendanceEntry({
    required this.employee,
    this.record,
  });

  final Employee employee;
  final AttendanceRecord? record;

  AttendanceStatus? get status => record?.status;

  bool get isMarked => record != null;

  DailyAttendanceEntry copyWith({
    Employee? employee,
    AttendanceRecord? record,
    bool clearRecord = false,
  }) {
    return DailyAttendanceEntry(
      employee: employee ?? this.employee,
      record: clearRecord ? null : (record ?? this.record),
    );
  }

  @override
  List<Object?> get props => [employee, record];
}

class DailyAttendanceState extends Equatable {
  const DailyAttendanceState({
    this.status = DailyAttendanceStatus.initial,
    required this.selectedDate,
    this.defaultShift = AttendanceShift.morning,
    this.entries = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.actionMessage,
  });

  final DailyAttendanceStatus status;
  final DateTime selectedDate;
  final AttendanceShift defaultShift;
  final List<DailyAttendanceEntry> entries;
  final String searchQuery;
  final String? errorMessage;
  final String? actionMessage;

  int get activeEmployeeCount => entries.length;

  int get markedCount => entries.where((entry) => entry.isMarked).length;

  int get presentCount => entries
      .where((entry) => entry.status == AttendanceStatus.present)
      .length;

  int get absentCount => entries
      .where((entry) => entry.status == AttendanceStatus.absent)
      .length;

  int get unmarkedCount => entries.where((entry) => !entry.isMarked).length;

  int get nonPresentMarkedCount => entries
      .where(
        (entry) =>
            entry.isMarked && entry.status != AttendanceStatus.present,
      )
      .length;

  List<DailyAttendanceEntry> get visibleEntries {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return entries;

    return entries.where((entry) {
      final haystack = [
        entry.employee.fullName,
        entry.employee.employeeNumber,
        entry.employee.phone,
        entry.employee.workerCategory.label,
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  DailyAttendanceState copyWith({
    DailyAttendanceStatus? status,
    DateTime? selectedDate,
    AttendanceShift? defaultShift,
    List<DailyAttendanceEntry>? entries,
    String? searchQuery,
    String? errorMessage,
    String? actionMessage,
    bool clearActionMessage = false,
    bool clearErrorMessage = false,
  }) {
    return DailyAttendanceState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      defaultShift: defaultShift ?? this.defaultShift,
      entries: entries ?? this.entries,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedDate,
        defaultShift,
        entries,
        searchQuery,
        errorMessage,
        actionMessage,
      ];
}
