/// Mine / quarry locations for job work stone intake.
abstract final class MineLocations {
  static const List<String> all = [
    'Ghawiai Ghar (Travertine)',
    'Sangori (Travertine)',
    'Qasa (Cream)',
    'Qasa (Travertine)',
  ];

  static bool contains(String? value) =>
      value != null && all.contains(value);
}
