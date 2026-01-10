import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/factory/create_factory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Factory Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile-setup': (context) => const ProfileSetupScreen(),
          '/create-factory': (context) => const CreateFactoryScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.isAuthenticated) {
      if (!authProvider.hasProfile) {
        return const ProfileSetupScreen();
      } else if (!authProvider.hasFactory) {
        return const CreateFactoryScreen();
      } else {
        return const HomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
