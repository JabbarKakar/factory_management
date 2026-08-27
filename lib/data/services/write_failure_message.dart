import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'sequence_number_service.dart';

/// Turns a failed Firestore write into a message the user can act on.
String writeFailureMessage(Object error, {required String fallback}) {
  debugPrint('Write failed: $error');

  if (error is SequenceNumberException) return error.message;

  if (error is FirebaseException) {
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return 'No connection to Firestore. Check the network and try again.';
    }
    if (error.code == 'permission-denied') {
      return 'You do not have permission to save this. '
          'If this is a new collection (counters / stock totals), deploy '
          'firestore.rules first.';
    }
    return '$fallback (${error.code})';
  }

  return fallback;
}
