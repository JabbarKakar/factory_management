import 'mine_locations.dart';

/// Mine owners mapped by [MineLocations].
abstract final class MineOwners {
  static const Map<String, List<String>> byLocation = {
    'Ghawiai Ghar (Travertine)': [
      'Gul Hassan',
      'Jaffar',
      'Noor Muhammad',
      'Hizbullah',
      'Zia ul Haq',
      'Bara Khan',
      'Shero',
      'Razaq',
      'Abdullah',
      'Muhammad Nabi',
      'Quetta',
      'Ajmal',
      'Sarwar',
      'Ameen',
      'Agha Jan',
      'Chaudhry',
    ],
    'Sangori (Travertine)': [
      'Asmat',
      'Razaq',
      'Hizbullah',
      'Gull Hassan',
      'Khalid',
    ],
    'Qasa (Cream)': [
      'Malak Naseeb Ullah',
      'Haji Yaqoob',
      'Co.',
    ],
    'Qasa (Travertine)': [
      'Shahzad',
      'Shah Nazar',
      'Gull Hassan',
      'Ajmal',
    ],
  };

  static List<String> forLocation(String? location) {
    if (location == null || !MineLocations.contains(location)) {
      return const [];
    }
    return List<String>.unmodifiable(byLocation[location] ?? const []);
  }

  static bool isValidCombination(String? location, String? owner) {
    if (location == null || owner == null) return false;
    return forLocation(location).contains(owner);
  }

  static String? normalizeOwnerForLocation(String? location, String? owner) {
    if (!isValidCombination(location, owner)) return null;
    return owner;
  }
}
