import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Connects to local Firebase emulators when built with:
/// `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`
///
/// Android emulator host defaults to `10.0.2.2`. For a physical device on the
/// same Wi‑Fi network, pass your PC IP:
/// `--dart-define=EMULATOR_HOST=192.168.1.10`
abstract final class FirebaseEmulatorConfig {
  static const bool enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const String host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  static const String functionsRegion = 'us-central1';

  static Future<void> connectIfEnabled() async {
    if (!enabled || kIsWeb) return;

    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(host, 5001);

    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'Firebase emulators: host=$host '
        '(auth:9099, firestore:8080, functions:5001)',
      );
    }
  }
}
