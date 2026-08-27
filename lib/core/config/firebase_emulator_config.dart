import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase backend selection.
///
/// The app talks to the **production** project by default, including debug
/// builds on a physical phone or tablet. Local emulators are never used unless
/// they are turned on explicitly:
/// `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`
abstract final class FirebaseEmulatorConfig {
  static const bool _useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );

  static const String _hostOverride = String.fromEnvironment('EMULATOR_HOST');

  static String get host =>
      _hostOverride.isNotEmpty ? _hostOverride : 'localhost';

  static const String functionsRegion = 'us-central1';

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int functionsPort = 5001;

  /// True only when [USE_FIREBASE_EMULATORS] was passed at compile time.
  static bool get enabled => !kIsWeb && _useEmulators;

  static Future<void> connectIfEnabled() async {
    if (!enabled) {
      if (kDebugMode) {
        debugPrint(
          'Firebase: using PRODUCTION project. Reads and writes are billed.',
        );
      }
      return;
    }

    // automaticHostMapping must stay off: the Android SDK otherwise rewrites
    // localhost → 10.0.2.2, which is unreachable from a physical device.
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      firestorePort,
      automaticHostMapping: false,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      host,
      authPort,
      automaticHostMapping: false,
    );
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(host, functionsPort);

    if (kDebugMode) {
      debugPrint(
        'Firebase emulators: host=$host '
        '(auth:$authPort, firestore:$firestorePort, functions:$functionsPort).',
      );
    }
  }
}
