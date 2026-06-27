enum ReminderChannel {
  whatsapp,
  sms,
  inApp;

  String get firestoreValue => name;

  static ReminderChannel fromString(String? value) {
    return ReminderChannel.values.firstWhere(
      (channel) => channel.name == value,
      orElse: () => ReminderChannel.whatsapp,
    );
  }
}
