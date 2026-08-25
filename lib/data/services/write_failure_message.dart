import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/firebase_emulator_config.dart';
import 'sequence_number_service.dart';

/// Turns a failed Firestore write into a message the user can act on.
///
/// Stock blocs used to swallow every non-domain exception as "Could not record
/// adjustment", which hid the actual cause — most often `unavailable` because a
/// debug build is pointed at local emulators that are not running.
String writeFailureMessage(Object error, {required String fallback}) {
  debugPrint('Write failed: $error');

  if (error is SequenceNumberException) return error.message;

  if (error is FirebaseException) {
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      if (FirebaseEmulatorConfig.enabled) {
        return 'Cannot reach the local Firebase emulators. '
            'This debug build does not talk to production. '
            'Stop the app and relaunch with '
            '--dart-define=USE_PROD_FIREBASE=true.';
      }
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
