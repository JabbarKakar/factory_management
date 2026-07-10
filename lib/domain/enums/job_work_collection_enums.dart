enum JobWorkCollectionStatus {
  collected,
  cancelled;

  String get firestoreValue => name;

  String get label => switch (this) {
        JobWorkCollectionStatus.collected => 'Collected',
        JobWorkCollectionStatus.cancelled => 'Cancelled',
      };

  static JobWorkCollectionStatus fromString(String? value) {
    return JobWorkCollectionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => JobWorkCollectionStatus.collected,
    );
  }

  bool get isTerminal => true;

  bool get countsTowardCollected => this == JobWorkCollectionStatus.collected;
}
