import 'package:equatable/equatable.dart';

class BankAccount extends Equatable {
  const BankAccount({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.branch,
    this.swiftCode,
    this.iban,
    this.accountType = 'Current',
    this.isDefault = false,
    this.isActive = true,
  });

  final String id;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String? branch;
  final String? swiftCode;
  final String? iban;
  final String accountType; // e.g. 'Current', 'Savings'
  final bool isDefault;
  final bool isActive;

  BankAccount copyWith({
    String? id,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? branch,
    String? swiftCode,
    String? iban,
    String? accountType,
    bool? isDefault,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      swiftCode: swiftCode ?? this.swiftCode,
      iban: iban ?? this.iban,
      accountType: accountType ?? this.accountType,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountName,
        accountNumber,
        bankName,
        branch,
        swiftCode,
        iban,
        accountType,
        isDefault,
        isActive,
      ];
}
