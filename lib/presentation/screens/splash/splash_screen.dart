import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
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
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

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

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashContent(
        logoScale: _logoScale,
        logoOpacity: _logoOpacity,
        titleOpacity: _titleOpacity,
        titleSlide: _titleSlide,
        taglineOpacity: _taglineOpacity,
        taglineSlide: _taglineSlide,
        accentPulse: _pulseController,
      ),
    );
  }
}
