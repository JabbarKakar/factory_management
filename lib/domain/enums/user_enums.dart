enum UserAccountStatus {
  active,
  disabled;

  String get firestoreValue => name;

  static UserAccountStatus fromString(String? value) {
    return UserAccountStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => UserAccountStatus.active,
    );
  }
}
