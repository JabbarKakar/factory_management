enum InvoiceStatus {
  unpaid,
  partial,
  paid,
  overdue,
  cancelled;

  String get label => switch (this) {
        InvoiceStatus.unpaid => 'Unpaid',
        InvoiceStatus.partial => 'Partial',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.overdue => 'Overdue',
        InvoiceStatus.cancelled => 'Cancelled',
      };

  String get firestoreValue => name;

  static InvoiceStatus fromString(String? value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceStatus.unpaid,
    );
  }

  static InvoiceStatus fromAmounts({
    required double dueAmount,
    required double paidAmount,
    required double totalAmount,
    DateTime? dueDate,
  }) {
    if (dueAmount <= 0 && totalAmount > 0) return InvoiceStatus.paid;
    if (paidAmount > 0 && dueAmount > 0) {
      if (dueDate != null &&
          DateTime.now().isAfter(
            DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59),
          )) {
        return InvoiceStatus.overdue;
      }
      return InvoiceStatus.partial;
    }
    if (dueDate != null &&
        DateTime.now().isAfter(
          DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59),
        )) {
      return InvoiceStatus.overdue;
    }
    return InvoiceStatus.unpaid;
  }
}

enum PaymentMethod {
  cash,
  bankTransfer,
  cheque,
  online;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.cheque => 'Cheque',
        PaymentMethod.online => 'Online',
      };

  String get firestoreValue => name;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum InvoiceType {
  jobWork,
  sales;

  String get firestoreValue => name;

  static InvoiceType fromString(String? value) {
    return InvoiceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceType.jobWork,
    );
  }
}
