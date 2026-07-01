/// Job work tile/slab size catalog (small + large categories).
abstract final class JobWorkSizes {
  static const List<List<String>> smallSizeRows = [
    ['4x12', '4x24', '4x36', '4x48', '4x60'],
    ['6x12', '6x24', '6x36', '6x48', '6x60'],
    ['8x12', '8x24', '8x36', '8x48', '8x60'],
    ['10x12', '10x24', '10x36', '10x48', '10x60'],
  ];

  static const List<String> smallSizes = [
    '4x12',
    '4x24',
    '4x36',
    '4x48',
    '4x60',
    '6x12',
    '6x24',
    '6x36',
    '6x48',
    '6x60',
    '8x12',
    '8x24',
    '8x36',
    '8x48',
    '8x60',
    '10x12',
    '10x24',
    '10x36',
    '10x48',
    '10x60',
  ];

  static const List<String> largeSizes = [
    '12x12',
    '12x18',
    '12x24',
    '12x30',
    '12x36',
    '12x48',
    '12x60',
  ];

  static final Set<String> _catalog = {
    ...smallSizes,
    ...largeSizes,
  };

  static bool isCatalogSize(String size) => _catalog.contains(size);

  static bool isSmall(String size) => smallSizes.contains(size);

  static bool isLarge(String size) => largeSizes.contains(size);

  static List<String> selectedSmall(Iterable<String> sizes) =>
      smallSizes.where(sizes.contains).toList();

  static List<String> selectedLarge(Iterable<String> sizes) =>
      largeSizes.where(sizes.contains).toList();

  /// Sizes from older records that are not in the current catalog.
  static List<String> legacySizes(Iterable<String> sizes) =>
      sizes.where((size) => size.isNotEmpty && !isCatalogSize(size)).toList();

  /// Preserves catalog order, then appends legacy values.
  static List<String> sortForDisplay(Iterable<String> sizes) {
    final selected = sizes.toSet();
    return [
      ...smallSizes.where(selected.contains),
      ...largeSizes.where(selected.contains),
      ...legacySizes(selected),
    ];
  }

  static String joinForDisplay({
    required List<String> smallSizes,
    required List<String> largeSizes,
    List<String> legacySizes = const [],
  }) {
    final parts = <String>[];
    final small = selectedSmall(smallSizes);
    final large = selectedLarge(largeSizes);
    final legacy = legacySizes.isEmpty
        ? const <String>[]
        : legacySizes.where((size) => size.isNotEmpty).toList();

    if (small.isNotEmpty) parts.add(small.join(', '));
    if (large.isNotEmpty) parts.add(large.join(', '));
    if (legacy.isNotEmpty) parts.add(legacy.join(', '));
    return parts.join(' · ');
  }

  static List<String> _castStringList(dynamic value) =>
      (value as List?)?.cast<String>() ?? const [];

  /// Reads `smallSizes` / `largeSizes` from Firestore, or splits legacy `sizes`.
  static ({
    List<String> smallSizes,
    List<String> largeSizes,
    List<String> legacySizes,
  }) fromCuttingSpec(Map<String, dynamic> cuttingSpec) {
    final small = _castStringList(cuttingSpec['smallSizes']);
    final large = _castStringList(cuttingSpec['largeSizes']);
    final storedLegacy = _castStringList(cuttingSpec['legacySizes']);

    if (small.isNotEmpty || large.isNotEmpty || storedLegacy.isNotEmpty) {
      return (
        smallSizes: small,
        largeSizes: large,
        legacySizes: storedLegacy,
      );
    }

    final combined = _castStringList(cuttingSpec['sizes']);
    return (
      smallSizes: selectedSmall(combined),
      largeSizes: selectedLarge(combined),
      legacySizes: legacySizes(combined),
    );
  }
}
