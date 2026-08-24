import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/document_sequence.dart';
import 'sequence_number_service.dart';

@immutable
class SequenceSeedReport {
  const SequenceSeedReport({
    this.seeded = const {},
    this.skipped = const [],
    this.failed = const {},
  });

  static const SequenceSeedReport empty = SequenceSeedReport();

  /// Sequences whose counter was created, with the value it was set to.
  final Map<DocumentSequence, int> seeded;

  /// Sequences that needed no work: counter already present, or no existing
  /// numbers to continue from.
  final List<DocumentSequence> skipped;

  /// Sequences whose scan failed, with the reason.
  final Map<DocumentSequence, String> failed;

  bool get isComplete => failed.isEmpty;

  @override
  String toString() => 'seeded=${seeded.length} skipped=${skipped.length} '
      'failed=${failed.length}'
      '${seeded.isEmpty ? '' : ' -> ${seeded.map((k, v) => MapEntry(k.key, v))}'}'
      '${failed.isEmpty ? '' : ' errors=${failed.map((k, v) => MapEntry(k.key, v))}'}';
}

/// Pre-warms every sequence counter at login so the first document create of the
/// day does not pay for a collection scan.
///
/// [SequenceNumberService.allocate] seeds itself on first use, so this is an
/// optimisation rather than a correctness requirement — the numbering is safe
/// whether or not this ever runs.
class SequenceSeedMigration {
  SequenceSeedMigration({
    SequenceNumberService? sequenceNumberService,
    SharedPreferences? preferences,
  })  : _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(),
        _preferences = preferences;

  static const _prefKeyPrefix = 'sequence_counters_seed_v1_';

  final SequenceNumberService _sequenceNumberService;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  /// Runs once per factory per install; retries on the next launch while any
  /// sequence still failed to seed.
  Future<SequenceSeedReport> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final key = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(key) == true) return SequenceSeedReport.empty;

    final report = await run(factoryId);
    debugPrint('SequenceSeedMigration: $report');

    if (report.isComplete) {
      await prefs.setBool(key, true);
    }
    return report;
  }

  Future<SequenceSeedReport> run(String factoryId, {DateTime? now}) async {
    final year = (now ?? DateTime.now()).year;
    final seeded = <DocumentSequence, int>{};
    final skipped = <DocumentSequence>[];
    final failed = <DocumentSequence, String>{};

    for (final sequence in DocumentSequence.values) {
      try {
        final counter = await _sequenceNumberService
            .counterRef(factoryId: factoryId, sequence: sequence)
            .get();
        // Any existing counter means this sequence is already live. A counter
        // from an earlier year is left alone on purpose: the allocator restarts
        // at 1 for the new year, and rescanning would cost a full collection
        // read every January.
        if (counter.exists) {
          skipped.add(sequence);
          continue;
        }

        final highest = await _sequenceNumberService.seedFromExistingDocuments(
          factoryId: factoryId,
          sequence: sequence,
          year: year,
        );
        if (highest > 0) {
          seeded[sequence] = highest;
        } else {
          skipped.add(sequence);
        }
      } catch (error) {
        failed[sequence] = error.toString();
      }
    }

    return SequenceSeedReport(
      seeded: seeded,
      skipped: skipped,
      failed: failed,
    );
  }
}
