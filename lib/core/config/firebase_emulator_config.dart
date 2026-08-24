import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Routes Firebase traffic to local emulators during development.
///
/// Debug builds use the emulators **by default** so that day-to-day development
/// never consumes the production project's daily read/write quota. Release
/// builds always use production.
///
/// Opt out of the emulators in a debug build (to test against the real project):
/// `flutter run --dart-define=USE_PROD_FIREBASE=true`
///
/// Host resolution by target:
///
/// - **Android emulator** — `10.0.2.2` (the default) maps to the host machine.
/// - **Desktop / iOS simulator** — `localhost` (the default) shares the host
///   network stack.
/// - **Physical Android device** — neither default works. Prefer adb port
///   reversal, which tunnels over the existing USB connection and avoids Wi-Fi
///   and firewall problems entirely:
///
///   ```
///   adb reverse tcp:8080 tcp:8080
///   adb reverse tcp:9099 tcp:9099
///   adb reverse tcp:5001 tcp:5001
///   flutter run --dart-define=EMULATOR_HOST=localhost
///   ```
///
///   Alternatively, pass the PC's LAN IP with both devices on the same Wi-Fi
///   (`ipconfig` → IPv4) and allow inbound traffic on those ports:
///   `flutter run --dart-define=EMULATOR_HOST=192.168.1.10`
///
/// A physical Android device cannot be distinguished from the emulator without
/// an extra platform dependency, so it requires the explicit override above.
abstract final class FirebaseEmulatorConfig {
  /// Forces production Firebase in a debug build.
  static const bool _useProduction = bool.fromEnvironment('USE_PROD_FIREBASE');

  /// Legacy opt-in flag, kept so existing run configurations keep working.
  static const bool _legacyOptIn = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );

  static const String _hostOverride = String.fromEnvironment('EMULATOR_HOST');

  /// Host that reaches the developer machine from the current target.
  ///
  /// The Android emulator maps the host machine to `10.0.2.2`. Desktop builds
  /// and the iOS simulator share the host's network stack, so `localhost` is
  /// correct there — using `10.0.2.2` makes Firestore silently fall back to the
  /// local cache instead of connecting.
  static String get host {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }

  static const String functionsRegion = 'us-central1';

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int functionsPort = 5001;

  /// True when this build should talk to the emulators.
  ///
  /// Web is excluded because `firebase_options` uses a different host mapping
  /// there and the emulator suite is not part of the web debug workflow.
  static bool get enabled {
    if (kIsWeb) return false;
    if (_legacyOptIn) return true;
    if (_useProduction) return false;
    return kDebugMode;
  }

  static Future<void> connectIfEnabled() async {
    if (!enabled) {
      if (kDebugMode) {
        debugPrint(
          'Firebase: using PRODUCTION project '
          '(USE_PROD_FIREBASE=true). Reads and writes are billed.',
        );
      }
      return;
    }

    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(host, functionsPort);

    if (kDebugMode) {
      debugPrint(
        'Firebase emulators: host=$host '
        '(auth:$authPort, firestore:$firestorePort, functions:$functionsPort). '
        'Pass --dart-define=USE_PROD_FIREBASE=true to use production instead.',
      );
    }
  }
}
