import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import 'command_center/dashboard_fx_theme.dart';

/// An animated expandable FloatingActionButton (Speed Dial) for Quick Actions.
/// When clicked, expands to show:
/// 1. Create Job Work
/// 2. New Sales Order
/// 3. Record Payment
class ExpandableQuickActionsFab extends StatefulWidget {
  const ExpandableQuickActionsFab({super.key});

  @override
  State<ExpandableQuickActionsFab> createState() =>
      _ExpandableQuickActionsFabState();
}

class _ExpandableQuickActionsFabState extends State<ExpandableQuickActionsFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final actions = <({String label, IconData icon, Color color, VoidCallback onTap})>[
      if (user?.canView(AppModule.jobWork) == true)
        (
          label: 'Create Job Work',
          icon: Icons.add_business_rounded,
          color: const Color(0xFF10B981),
          onTap: () {
            _close();
            context.push(RoutePaths.jobWorkAdd);
          },
        ),
      if (user?.canView(AppModule.sales) == true)
        (
          label: 'New Sales Order',
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFF38BDF8),
          onTap: () {
            _close();
            context.push(RoutePaths.salesAdd);
          },
        ),
      if (user?.canView(AppModule.sales) == true ||
          user?.canView(AppModule.jobWork) == true)
        (
          label: 'Record Payment',
          icon: Icons.payments_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () {
            _close();
            context.push(RoutePaths.notifications);
          },
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    final isDark = DashboardFx.isDark(context);
    final primaryColor = DashboardFx.primary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = actions.length - 1; i >= 0; i--) ...[
          ScaleTransition(
            scale: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Action label pill
                    Material(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFFFFFFF),
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: actions[i].onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            actions[i].label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Action FAB button
                    FloatingActionButton.small(
                      heroTag: 'quick_action_$i',
                      onPressed: actions[i].onTap,
                      backgroundColor: actions[i].color,
                      elevation: 4,
                      child: Icon(
                        actions[i].icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        // Main expandable FAB button
        FloatingActionButton(
          heroTag: 'main_quick_actions_fab',
          onPressed: _toggle,
          backgroundColor: primaryColor,
          elevation: 6,
          tooltip: 'Quick Actions',
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * math.pi / 4,
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
