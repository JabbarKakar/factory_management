import '../../../core/constants/app_strings.dart';
import 'job_work_detail_row.dart';

/// Builds detail rows for selected job work sizes (small, large, legacy).
List<JobWorkDetailRow> buildJobWorkSizeDetailRows({
  required List<String> smallSizes,
  required List<String> largeSizes,
  List<String> legacySizes = const [],
}) {
  if (smallSizes.isEmpty && largeSizes.isEmpty && legacySizes.isEmpty) {
    return const [];
  }

  return [
    if (smallSizes.isNotEmpty)
      JobWorkDetailRow(
        label: AppStrings.smallSize,
        value: smallSizes.join(', '),
      ),
    if (largeSizes.isNotEmpty)
      JobWorkDetailRow(
        label: AppStrings.largeSize,
        value: largeSizes.join(', '),
      ),
    if (legacySizes.isNotEmpty)
      JobWorkDetailRow(
        label: AppStrings.legacySizes,
        value: legacySizes.join(', '),
      ),
  ];
}
