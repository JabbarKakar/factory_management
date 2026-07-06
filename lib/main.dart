import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'blocs/app_bloc_observer.dart';
import 'core/config/firebase_emulator_config.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseEmulatorConfig.connectIfEnabled();

  Bloc.observer = AppBlocObserver();
  setupDependencies();

  runApp(const FactoryManagementApp());
}
