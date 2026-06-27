import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../routes/route_paths.dart';
import '../../widgets/splash/animated_splash_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _minSplashDuration = Duration(milliseconds: 2800);

  late final AnimationController _entryController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSplashSequence();
  }

  void _setupAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.35, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _runSplashSequence() async {
    final animationFuture = _entryController.forward();

    await Future.wait([
      Future.delayed(_minSplashDuration),
      _waitForAuthReady(),
      animationFuture,
    ]);

    if (!mounted) return;
    _navigateNext();
  }

  Future<void> _waitForAuthReady() async {
    final authBloc = context.read<AuthBloc>();
    final current = authBloc.state;
    if (current is! AuthInitial && current is! AuthLoading) return;

    await authBloc.stream.firstWhere(
      (state) => state is! AuthInitial && state is! AuthLoading,
    );
  }

  void _navigateNext() {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      context.go(RoutePaths.dashboard);
      return;
    }

    context.go(RoutePaths.login);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedSplashContent(
        logoScale: _logoScale,
        logoOpacity: _logoOpacity,
      ),
    );
  }
}
