enum InviteStatus {
  pending,
  accepted,
  expired,
  revoked;

  String get firestoreValue => name;

  String get label => switch (this) {
        InviteStatus.pending => 'Pending',
        InviteStatus.accepted => 'Accepted',
        InviteStatus.expired => 'Expired',
        InviteStatus.revoked => 'Revoked',
      };

  static InviteStatus fromString(String? value) {
    return InviteStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => InviteStatus.pending,
    );
  }

  bool get isOpen => this == InviteStatus.pending;
}
