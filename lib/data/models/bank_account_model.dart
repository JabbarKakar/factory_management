import 'dart:convert';
import '../../domain/entities/bank_account.dart';

class BankAccountModel extends BankAccount {
  const BankAccountModel({
    required super.id,
    required super.accountName,
    required super.accountNumber,
    required super.bankName,
    super.branch,
    super.swiftCode,
    super.iban,
    super.accountType = 'Current',
    super.isDefault = false,
    super.isActive = true,
  });

  factory BankAccountModel.fromEntity(BankAccount bankAccount) {
    return BankAccountModel(
      id: bankAccount.id,
      accountName: bankAccount.accountName,
      accountNumber: bankAccount.accountNumber,
      bankName: bankAccount.bankName,
      branch: bankAccount.branch,
      swiftCode: bankAccount.swiftCode,
      iban: bankAccount.iban,
      accountType: bankAccount.accountType,
      isDefault: bankAccount.isDefault,
      isActive: bankAccount.isActive,
    );
  }

  factory BankAccountModel.fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id'] as String? ?? '',
      accountName: map['accountName'] as String? ?? '',
      accountNumber: map['accountNumber'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      branch: map['branch'] as String?,
      swiftCode: map['swiftCode'] as String?,
      iban: map['iban'] as String?,
      accountType: map['accountType'] as String? ?? 'Current',
      isDefault: map['isDefault'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      if (branch != null && branch!.isNotEmpty) 'branch': branch,
      if (swiftCode != null && swiftCode!.isNotEmpty) 'swiftCode': swiftCode,
      if (iban != null && iban!.isNotEmpty) 'iban': iban,
      'accountType': accountType,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  factory BankAccountModel.fromJson(String source) =>
      BankAccountModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());
}
