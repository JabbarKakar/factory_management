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
/// The host is always `localhost`. Desktop builds and the iOS simulator share
/// the host's network stack, so it works directly. **Android needs one command
/// first**, on a physical device *and* on the Android emulator:
///
/// ```
/// adb reverse tcp:8080 tcp:8080
/// adb reverse tcp:9099 tcp:9099
/// adb reverse tcp:5001 tcp:5001
/// ```
///
/// That tunnels the three ports over the existing USB/adb connection, which
/// avoids Wi-Fi and firewall problems entirely. The tunnels are cleared when the
/// device is unplugged, so re-run them after reconnecting.
///
/// Android used to default to `10.0.2.2`, the emulator's alias for the host
/// machine. That is unreachable from a physical device and surfaced as
/// `Failed to connect to /10.0.2.2:9099`, so it is no longer used: a physical
/// device cannot be told apart from the emulator without an extra platform
/// dependency, and `localhost` plus adb reversal works for both.
///
/// To go over Wi-Fi instead, pass the PC's LAN IP (`ipconfig` → IPv4) and allow
/// inbound traffic on those ports:
/// `flutter run --dart-define=EMULATOR_HOST=192.168.1.10`
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
  /// On Android this relies on `adb reverse` (see the class comment); without
  /// the tunnels Auth fails outright and Firestore silently serves the local
  /// cache instead of connecting.
  static String get host =>
      _hostOverride.isNotEmpty ? _hostOverride : 'localhost';

  static const String functionsRegion = 'us-central1';

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int functionsPort = 5001;

  /// True when this build should talk to the emulators.
  ///
  /// Web is excluded because `firebase_options` uses a different host mapping
  /// there and the emulator suite is not part of the web debug workflow.
  ///
  /// `USE_PROD_FIREBASE=true` always wins, including over the legacy
  /// `USE_FIREBASE_EMULATORS` flag.
  static bool get enabled {
    if (kIsWeb) return false;
    if (_useProduction) return false;
    if (_legacyOptIn) return true;
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

    // automaticHostMapping must stay off: the Android SDK otherwise rewrites
    // localhost → 10.0.2.2, which is unreachable from a physical device and
    // surfaces as WatchStream/WriteStream UNAVAILABLE.
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
        '(auth:$authPort, firestore:$firestorePort, functions:$functionsPort). '
        'Pass --dart-define=USE_PROD_FIREBASE=true to use production instead.',
      );
    }
  }
}
